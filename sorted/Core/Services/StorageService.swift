/// StorageService.swift
/// Handles Firebase Storage operations for profile pictures and media
/// [Source: Epic 1, Story 1.5]

@preconcurrency import FirebaseStorage
import Foundation
import UIKit

/// Service responsible for uploading and managing files in Firebase Storage
@MainActor
final class StorageService {
    private let storage: Storage

    init() {
        self.storage = Storage.storage()
    }

    /// Upload image to Firebase Storage and return publicly accessible download URL
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - path: Storage path (e.g., "profile_pictures/{userId}/profile.jpg")
    /// - Returns: HTTPS download URL (not gs:// reference URL)
    /// - Throws: StorageError if upload fails
    func uploadImage(_ image: UIImage, path: String) async throws -> URL {
        // 1. Compress image (0.7 quality, max ~5MB after compression)
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.imageCompressionFailed
        }

        // 2. Validate file size (5MB max enforced by Storage Rules)
        let maxSize = 5 * 1024 * 1024 // 5MB
        guard imageData.count <= maxSize else {
            throw StorageError.fileTooLarge
        }

        // 3. Create storage reference
        let storageRef = storage.reference().child(path)

        // 4. Upload with metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=31536000" // Cache for 1 year

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // 5. CRITICAL: Get download URL (HTTPS, not gs://)
        // This URL is what we store in Firestore and use with Kingfisher
        let downloadURL = try await storageRef.downloadURL()

        // 6. Verify URL is HTTPS (required for Kingfisher & AsyncImage)
        guard downloadURL.scheme == "https" else {
            throw StorageError.invalidDownloadURL
        }

        return downloadURL
    }

    /// Upload group photo to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - groupID: The group conversation ID
    /// - Returns: HTTPS download URL
    /// - Throws: StorageError if upload fails
    func uploadGroupPhoto(_ image: UIImage, groupID: String) async throws -> URL {
        let path = "group_photos/\(groupID)/group_photo.jpg"
        return try await uploadImage(image, path: path)
    }

    /// Delete image from Firebase Storage
    /// - Parameter path: Storage path to delete
    /// - Throws: StorageError if deletion fails
    func deleteImage(at path: String) async throws {
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }
}

/// Errors that can occur during Storage operations
enum StorageError: Error, LocalizedError {
    case imageCompressionFailed
    case fileTooLarge
    case invalidDownloadURL

    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image. Please try a different image."
        case .fileTooLarge:
            return "Image is too large. Maximum size is 5MB."
        case .invalidDownloadURL:
            return "Failed to get valid download URL from Firebase Storage."
        }
    }
}
