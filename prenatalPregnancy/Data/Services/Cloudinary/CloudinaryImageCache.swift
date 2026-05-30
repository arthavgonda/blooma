//
//  CloudinaryImageCache.swift
//  prenatalPregnancy
//
//  Fetches exercise/yoga/walking images from Cloudinary.
//  Two-level cache: NSCache (memory) + disk (Caches dir, 3-day TTL).
//  Falls back silently to the local bundle asset if any fetch fails.
//

import UIKit

// MARK: - CloudinaryImageCache

final class CloudinaryImageCache {

    // MARK: - Singleton
    static let shared = CloudinaryImageCache()
    private init() {
        createCacheDirectoryIfNeeded()
    }

    // MARK: - Config
    private let cloudName  = "ddeuboz3q"
    private let ttlSeconds: TimeInterval = 3 * 24 * 60 * 60

    private let formatProbes = [".png", "", ".jpg", ".jpeg", ".webp"]

    // MARK: - Memory cache
    private let memoryCache = NSCache<NSString, UIImage>()

    // MARK: - In-flight request deduplication
    //  Maps cache key → list of pending completion blocks so a second caller
    //  for the same image waits on the single in-flight URLSession task.
    private var inFlight: [String: [(UIImage?) -> Void]] = [:]
    private let lock = NSLock()

    // MARK: - Disk cache location
    private var cacheDirectory: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CloudinaryImages", isDirectory: true)
    }

    // MARK: - Public API

    /// Load image for a routine asset.
    /// - Parameters:
    ///   - name:        The `item.image` string from the dataset (e.g. "catcow").
    ///   - routineType: Used to choose the correct Cloudinary folder.
    ///   - fallback:    A pre-resolved local UIImage to use immediately as placeholder
    ///                  and as permanent fallback if Cloudinary fails.
    ///   - completion:  Called on the **main thread** with the best available image.
    func loadImage(
        named name: String,
        routineType: RoutineType,
        fallback: UIImage?,
        completion: @escaping (UIImage?) -> Void
    ) {
        let baseName  = (name as NSString).deletingPathExtension
        let cacheKey  = "\(routineType.cloudinaryFolder)/\(baseName)" as NSString

        // 1 — Memory hit
        if let cached = memoryCache.object(forKey: cacheKey) {
            completion(cached)
            return
        }

        // 2 — Disk hit (validate TTL)
        if let diskImage = loadFromDisk(key: baseName, folder: routineType.cloudinaryFolder) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            completion(diskImage)
            return
        }

        // 3 — Deduplicate in-flight requests
        lock.lock()
        if inFlight[cacheKey as String] != nil {
            inFlight[cacheKey as String]?.append(completion)
            lock.unlock()
            return
        }
        inFlight[cacheKey as String] = [completion]
        lock.unlock()

        // 4 — Fetch from Cloudinary — start with .png (confirmed format)
        guard let url = cloudinaryURL(for: "\(baseName).png", folder: routineType.cloudinaryFolder) else {
            deliverResult(nil, forKey: cacheKey as String)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                print("[Cloudinary] ❌ Fetch failed for '\(baseName)': \(error.localizedDescription) — falling back to local asset")
                self.deliverResult(nil, forKey: cacheKey as String)
                return
            }

            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? -1

            if let data, let image = UIImage(data: data) {
                print("[Cloudinary] ✅ Fetched from Cloudinary successful: '\(baseName).png'")
                self.memoryCache.setObject(image, forKey: cacheKey)
                self.saveToDisk(image: image, key: baseName, folder: routineType.cloudinaryFolder)
                self.deliverResult(image, forKey: cacheKey as String)
            } else {
                let preview = data.flatMap { String(data: $0.prefix(200), encoding: .utf8) } ?? "<no body>"
                print("[Cloudinary] ❌ .png failed for '\(baseName)' (HTTP \(httpStatus)) — trying other formats")
                print("[Cloudinary]    Response preview: \(preview)")
                // .png failed; probe remaining formats in order
                self.probeFormats(
                    baseName: baseName,
                    folder: routineType.cloudinaryFolder,
                    cacheKey: cacheKey as String,
                    remaining: self.formatProbes.filter { $0 != ".png" }  // skip .png — already tried
                )
            }
        }.resume()
    }

    func prefetchImages(for items: [RoutineItem]) {
        let imageRequests = Array(
            Set(items.map { "\($0.routineType.rawValue)|\($0.image)" })
        )

        guard !imageRequests.isEmpty else { return }

        imageRequests.forEach { request in
            let parts = request.split(separator: "|", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let routineType = RoutineType(rawValue: parts[0]),
                  !parts[1].isEmpty else { return }

            loadImage(named: parts[1], routineType: routineType, fallback: nil) { _ in }
        }
    }

    // MARK: - Multi-format probe

    /// Recursively tries the next format suffix until one returns valid image data or we run out.
    private func probeFormats(
        baseName: String,
        folder: String,
        cacheKey: String,
        remaining: [String]
    ) {
        var remaining = remaining
        guard !remaining.isEmpty else {
            print("[Cloudinary] ❌ All format probes exhausted for '\(baseName)' — falling back to local asset")
            deliverResult(nil, forKey: cacheKey)
            return
        }
        let ext = remaining.removeFirst()
        guard let probeURL = cloudinaryURL(for: "\(baseName)\(ext)", folder: folder) else {
            probeFormats(baseName: baseName, folder: folder, cacheKey: cacheKey, remaining: remaining)
            return
        }
        print("[Cloudinary] 🔄 Probing '\(baseName)\(ext)': \(probeURL)")
        URLSession.shared.dataTask(with: probeURL) { [weak self] data, response, error in
            guard let self else { return }
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            if let data, let image = UIImage(data: data) {
                print("[Cloudinary] ✅ Fetched from Cloudinary successful (\(ext.isEmpty ? "no-ext" : ext)): '\(baseName)'")
                let key = cacheKey as NSString
                self.memoryCache.setObject(image, forKey: key)
                self.saveToDisk(image: image, key: baseName, folder: folder)
                self.deliverResult(image, forKey: cacheKey)
            } else {
                print("[Cloudinary] ↩ '\(baseName)\(ext)' → HTTP \(status), trying next...")
                self.probeFormats(baseName: baseName, folder: folder, cacheKey: cacheKey, remaining: remaining)
            }
        }.resume()
    }

    // MARK: - Private helpers

    /// Construct the Cloudinary delivery URL.
    /// Files are stored at the ROOT level (dynamic folder mode — folder names in the media
    /// library are labels only, NOT part of the public_id / URL path).
    private func cloudinaryURL(for name: String, folder: String) -> URL? {
        // folder is intentionally excluded from the URL — kept only for disk-cache namespacing.
        let urlString = "https://res.cloudinary.com/\(cloudName)/image/upload/\(name)"
        return URL(string: urlString)
    }

    /// Deliver result to all waiting completions, then clear the in-flight entry.
    private func deliverResult(_ image: UIImage?, forKey key: String) {
        lock.lock()
        let callbacks = inFlight[key] ?? []
        inFlight[key] = nil
        lock.unlock()

        DispatchQueue.main.async {
            callbacks.forEach { $0(image) }
        }
    }

    // MARK: - Disk cache

    private func createCacheDirectoryIfNeeded() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: cacheDirectory.path) {
            try? fm.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func diskURL(key: String, folder: String) -> URL {
        // Prefix the folder name so yoga/cat_cow and exercise/cat_cow don't collide
        cacheDirectory.appendingPathComponent("\(folder)_\(key).png")
    }

    private func loadFromDisk(key: String, folder: String) -> UIImage? {
        let fileURL = diskURL(key: key, folder: folder)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        // TTL check
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modified = attrs[.modificationDate] as? Date {
            if Date().timeIntervalSince(modified) > ttlSeconds {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
        }

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(image: UIImage, key: String, folder: String) {
        guard let data = image.pngData() else { return }
        let fileURL = diskURL(key: key, folder: folder)
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - RoutineType → Cloudinary folder

private extension RoutineType {
    var cloudinaryFolder: String {
        switch self {
        case .exercise: return "exercise_assets"
        case .yoga:     return "yoga_assets"
        case .walking:  return "walking_assets"
        }
    }
}
