//
//  CloudinaryService.swift
//  Blooma
//

import UIKit
import UniformTypeIdentifiers

final class CloudinaryService {

    // MARK: - Config — fill these from your Cloudinary dashboard
    private let cloudName   = "ddeuboz3q"
    private let uploadPreset = "blooma_profile"  // unsigned preset
    private let folder      = "profile_images"

    static let shared = CloudinaryService()
    private init() {}

    // MARK: - Supported formats
    private let supportedUTTypes: [UTType] = [.jpeg, .png, .heic, .webP, .image]
    private let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif", "webp"]

    // MARK: - Compression config
    private let maxDimensionPx: CGFloat = 512
    private let jpegQuality: CGFloat    = 0.75
    private let maxFileSizeBytes        = 500_000

    // MARK: - Upload
    func uploadProfileImage(
        _ image: UIImage,
        userId: String,
        completion: @escaping (Result<String, CloudinaryError>) -> Void
    ) {
        guard let compressed = compress(image) else {
            completion(.failure(.compressionFailed))
            return
        }

        let publicId = "\(folder)/\(userId)"
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(
            imageData: compressed,
            publicId: publicId,
            boundary: boundary
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(.invalidResponse))
                return
            }
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                completion(.failure(.cloudinaryError(message)))
                return
            }
            guard let secureUrl = json["secure_url"] as? String else {
                completion(.failure(.invalidResponse))
                return
            }
            completion(.success(secureUrl))
        }.resume()
    }

    // MARK: - Fetch URL
    /// Returns the Cloudinary URL for a given userId (no network call)
    func profileImageURL(for userId: String) -> URL? {
        // Add v= timestamp busting if needed; for now returns stable URL
        let urlString = "https://res.cloudinary.com/\(cloudName)/image/upload/\(folder)/\(userId)"
        return URL(string: urlString)
    }

    // MARK: - Validation
    func isSupported(_ image: UIImage) -> Bool {
        // UIImage is already decoded — always valid at this point
        // Real extension check happens at PHPicker level (see ProfileViewController)
        return true
    }

    func isSupportedFileExtension(_ ext: String) -> Bool {
        supportedExtensions.contains(ext.lowercased())
    }

    // MARK: - Compression pipeline
    private func compress(_ image: UIImage) -> Data? {
        // Step 1: Resize to max dimension
        let resized = resize(image, maxDimension: maxDimensionPx)

        // Step 2: Convert to JPEG at target quality
        guard var data = resized.jpegData(compressionQuality: jpegQuality) else { return nil }

        // Step 3: If still over cap, reduce quality progressively
        var quality = jpegQuality
        while data.count > maxFileSizeBytes && quality > 0.3 {
            quality -= 0.1
            guard let recompressed = resized.jpegData(compressionQuality: quality) else { break }
            data = recompressed
        }

        return data.count <= maxFileSizeBytes ? data : nil
    }

    private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Multipart
    private func multipartBody(imageData: Data, publicId: String, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"

        func append(_ string: String) {
            if let data = string.data(using: .utf8) { body.append(data) }
        }

        // upload_preset
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"upload_preset\"\(crlf)\(crlf)")
        append("\(uploadPreset)\(crlf)")

        // public_id
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"public_id\"\(crlf)\(crlf)")
        append("\(publicId)\(crlf)")

        // image file
        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\(crlf)")
        append("Content-Type: image/jpeg\(crlf)\(crlf)")
        body.append(imageData)
        append(crlf)

        append("--\(boundary)--\(crlf)")
        return body
    }
}

// MARK: - Errors
enum CloudinaryError: LocalizedError {
    case unsupportedFormat
    case compressionFailed
    case fileTooLarge
    case networkError(Error)
    case invalidResponse
    case cloudinaryError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:   return "Image format not supported. Use JPEG, PNG, HEIC, or WebP."
        case .compressionFailed:   return "Could not compress image."
        case .fileTooLarge:        return "Image is too large even after compression."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .invalidResponse:     return "Unexpected response from server."
        case .cloudinaryError(let msg): return "Cloudinary error: \(msg)"
        }
    }
}
