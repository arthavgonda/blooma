//
//  CloudinaryVideoService.swift
//  Blooma
//
//  Created by GEU on 29/05/26.
//

import Foundation

final class CloudinaryVideoService {

    static let shared = CloudinaryVideoService()

    private init() {
        createCacheDirectoryIfNeeded()
        removeExpiredVideos()
    }

    // MARK: - Config

    private let cloudName = "ddeuboz3q"
    private let uploadPreset = "blooma_videos"
    private let ttlSeconds: TimeInterval = 7 * 24 * 60 * 60
    private let formatProbes = [".mov", ".mp4", ".mkv", ".m4v"]

    private var inFlight: [String: [(URL?) -> Void]] = [:]
    private let lock = NSLock()

    private var cacheDirectory: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CloudinaryVideos", isDirectory: true)
    }

    // MARK: - Download / Cache Video

    func loadVideo(
        named name: String,
        routineType: RoutineType,
        completion: @escaping (URL?) -> Void
    ) {
        guard routineType == .yoga else {
            print("ℹ️ [CloudinaryVideo] Cloudinary video download is currently enabled only for yoga. Received type=\(routineType.rawValue), video=\(name)")
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let normalized = normalizedVideoName(name)
        guard !normalized.isEmpty else {
            print("⛔ [CloudinaryVideo] Empty video name received for \(routineType.rawValue)")
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let cacheKey = "\(routineType.cloudinaryVideoCacheNamespace)/\(normalized)"

        if let cachedURL = loadFromDisk(fileName: normalized, routineType: routineType) {
            print("✅ [CloudinaryVideo] Cache hit: \(cacheKey)")
            DispatchQueue.main.async { completion(cachedURL) }
            return
        }

        lock.lock()
        if inFlight[cacheKey] != nil {
            inFlight[cacheKey]?.append(completion)
            lock.unlock()
            print("🔄 [CloudinaryVideo] Joining existing download: \(cacheKey)")
            return
        }
        inFlight[cacheKey] = [completion]
        lock.unlock()

        print("⬇️ [CloudinaryVideo] Starting download: \(cacheKey)")
        probeVideoFormats(
            originalName: normalized,
            routineType: routineType,
            cacheKey: cacheKey,
            candidates: candidateNames(for: normalized)
        )
    }

    func prefetchVideos(for items: [RoutineItem], routineType: RoutineType = .yoga) {
        let videos = Array(Set(items.filter { $0.routineType == routineType }.map(\.video)))
        guard !videos.isEmpty else {
            print("ℹ️ [CloudinaryVideo] No \(routineType.rawValue) videos to prefetch")
            removeExpiredVideos()
            return
        }

        print("🚀 [CloudinaryVideo] Prefetching \(videos.count) \(routineType.rawValue) video(s)")
        removeExpiredVideos()

        videos.forEach { video in
            loadVideo(named: video, routineType: routineType) { url in
                if let url {
                    print("✅ [CloudinaryVideo] Prefetch ready: \(video) -> \(url.lastPathComponent)")
                } else {
                    print("⛔ [CloudinaryVideo] Prefetch failed: \(video)")
                }
            }
        }
    }

    // MARK: - Upload Video

    func uploadVideo(
        videoURL: URL,
        fileName: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {

        let url = URL(
            string: "https://api.cloudinary.com/v1_1/\(cloudName)/video/upload"
        )!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        func append(_ string: String) {
            body.append(string.data(using: .utf8)!)
        }

        // upload preset
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n")
        append("\(uploadPreset)\r\n")

        // public id
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"public_id\"\r\n\r\n")
        append("yoga_video/\(fileName)\r\n")

        let videoData: Data

        do {
            videoData = try Data(contentsOf: videoURL)
        } catch {
            print("⛔ [CloudinaryVideo] Could not read video for upload: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"video.mp4\"\r\n")
        append("Content-Type: video/mp4\r\n\r\n")

        body.append(videoData)

        append("\r\n")
        append("--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("⛔ [CloudinaryVideo] Upload failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200...299).contains(statusCode) else {
                let preview = data.flatMap { String(data: $0.prefix(300), encoding: .utf8) } ?? "<no body>"
                let error = NSError(
                    domain: "CloudinaryVideoService",
                    code: statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Cloudinary upload failed with HTTP \(statusCode): \(preview)"]
                )
                print("⛔ [CloudinaryVideo] Upload failed with HTTP \(statusCode): \(preview)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("⛔ [CloudinaryVideo] Upload returned no response data")
                completion(.failure(NSError(
                    domain: "CloudinaryVideoService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Cloudinary upload returned no response data"]
                )))
                return
            }

            do {

                let json = try JSONSerialization.jsonObject(
                    with: data
                ) as? [String: Any]

                if let secureURL = json?["secure_url"] as? String {
                    print("✅ [CloudinaryVideo] Upload completed: \(secureURL)")
                    completion(.success(secureURL))
                } else {
                    print("⛔ [CloudinaryVideo] Upload response missing secure_url: \(json ?? [:])")
                }

            } catch {
                print("⛔ [CloudinaryVideo] Upload response decode failed: \(error.localizedDescription)")
                completion(.failure(error))
            }

        }.resume()
    }
}

// MARK: - Private Helpers

private extension CloudinaryVideoService {
    func probeVideoFormats(
        originalName: String,
        routineType: RoutineType,
        cacheKey: String,
        candidates: [String]
    ) {
        var candidates = candidates
        guard !candidates.isEmpty else {
            print("⛔ [CloudinaryVideo] All video URL probes failed for \(cacheKey)")
            deliverResult(nil, forKey: cacheKey)
            return
        }

        let candidate = candidates.removeFirst()
        guard let url = cloudinaryURL(for: candidate, routineType: routineType) else {
            print("⛔ [CloudinaryVideo] Invalid Cloudinary URL candidate: \(candidate)")
            probeVideoFormats(originalName: originalName, routineType: routineType, cacheKey: cacheKey, candidates: candidates)
            return
        }

        print("🔎 [CloudinaryVideo] Probing: \(url.absoluteString)")

        URLSession.shared.downloadTask(with: url) { [weak self] temporaryURL, response, error in
            guard let self else { return }

            if let error {
                print("⛔ [CloudinaryVideo] Download error for \(candidate): \(error.localizedDescription)")
                self.probeVideoFormats(originalName: originalName, routineType: routineType, cacheKey: cacheKey, candidates: candidates)
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200...299).contains(statusCode), let temporaryURL else {
                print("↩️ [CloudinaryVideo] Probe failed for \(candidate), HTTP \(statusCode)")
                self.probeVideoFormats(originalName: originalName, routineType: routineType, cacheKey: cacheKey, candidates: candidates)
                return
            }

            do {
                let savedURL = try self.saveDownloadedVideo(
                    temporaryURL: temporaryURL,
                    originalFileName: originalName,
                    routineType: routineType
                )
                print("✅ [CloudinaryVideo] Downloaded and cached \(cacheKey) at \(savedURL.lastPathComponent)")
                self.deliverResult(savedURL, forKey: cacheKey)
            } catch {
                print("⛔ [CloudinaryVideo] Could not save \(cacheKey): \(error.localizedDescription)")
                self.deliverResult(nil, forKey: cacheKey)
            }
        }.resume()
    }

    func createCacheDirectoryIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: cacheDirectory.path) else { return }

        do {
            try fm.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            print("✅ [CloudinaryVideo] Created cache directory: \(cacheDirectory.path)")
        } catch {
            print("⛔ [CloudinaryVideo] Failed to create cache directory: \(error.localizedDescription)")
        }
    }

    func removeExpiredVideos() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }

        for file in files {
            guard let modified = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else { continue }

            if Date().timeIntervalSince(modified) > ttlSeconds {
                do {
                    try fm.removeItem(at: file)
                    print("🧹 [CloudinaryVideo] Removed expired cached video: \(file.lastPathComponent)")
                } catch {
                    print("⛔ [CloudinaryVideo] Failed to remove expired video \(file.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    func loadFromDisk(fileName: String, routineType: RoutineType) -> URL? {
        let fileURL = diskURL(fileName: fileName, routineType: routineType)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let modified = attrs[.modificationDate] as? Date else {
            print("⛔ [CloudinaryVideo] Missing file attributes for cache item: \(fileURL.lastPathComponent)")
            return nil
        }

        if Date().timeIntervalSince(modified) > ttlSeconds {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("🧹 [CloudinaryVideo] Removed stale cached video before playback: \(fileURL.lastPathComponent)")
            } catch {
                print("⛔ [CloudinaryVideo] Failed to remove stale video: \(error.localizedDescription)")
            }
            return nil
        }

        return fileURL
    }

    func saveDownloadedVideo(
        temporaryURL: URL,
        originalFileName: String,
        routineType: RoutineType
    ) throws -> URL {
        createCacheDirectoryIfNeeded()

        let targetURL = diskURL(fileName: originalFileName, routineType: routineType)
        let fm = FileManager.default

        if fm.fileExists(atPath: targetURL.path) {
            try fm.removeItem(at: targetURL)
        }

        try fm.moveItem(at: temporaryURL, to: targetURL)
        return targetURL
    }

    func diskURL(fileName: String, routineType: RoutineType) -> URL {
        cacheDirectory.appendingPathComponent("\(routineType.cloudinaryVideoCacheNamespace)_\(safeDiskFileName(fileName))")
    }

    func deliverResult(_ url: URL?, forKey key: String) {
        lock.lock()
        let callbacks = inFlight[key] ?? []
        inFlight[key] = nil
        lock.unlock()

        DispatchQueue.main.async {
            callbacks.forEach { $0(url) }
        }
    }

    func cloudinaryURL(for fileName: String, routineType: RoutineType) -> URL? {
        let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName

        // Videos are currently delivered from the Cloudinary root public_id
        // using transformations, for example:
        // https://res.cloudinary.com/ddeuboz3q/video/upload/q_auto/f_auto/warrior_flow.mov
        return URL(string: "https://res.cloudinary.com/\(cloudName)/video/upload/q_auto/f_auto/\(encodedFileName)")
    }

    func candidateNames(for name: String) -> [String] {
        let baseName = (name as NSString).deletingPathExtension
        let pathExtension = (name as NSString).pathExtension
        let original = pathExtension.isEmpty ? name : "\(baseName).\(pathExtension)"

        var candidates = [original]
        for suffix in formatProbes {
            let candidate = "\(baseName)\(suffix)"
            if !candidates.contains(candidate) {
                candidates.append(candidate)
            }
        }
        return candidates
    }

    func normalizedVideoName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func safeDiskFileName(_ fileName: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return fileName.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }.map(String.init).joined()
    }
}

private extension RoutineType {
    var cloudinaryVideoCacheNamespace: String {
        switch self {
        case .exercise: return "exercise_video"
        case .yoga: return "yoga_video"
        case .walking: return "walking_video"
        }
    }
}
