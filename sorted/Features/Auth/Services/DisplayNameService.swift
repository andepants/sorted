/// DisplayNameService.swift
/// Manages displayName uniqueness enforcement via Firestore `/displayNames` collection
/// [Source: Epic 1, Story 1.1]

import FirebaseFirestore
import Foundation

/// Handles displayName uniqueness checks and reservations in Firestore
final class DisplayNameService {
    private let db = Firestore.firestore()

    /// Checks if a display name is available (not already taken)
    /// - Parameter name: Display name to check
    /// - Returns: True if available, false if taken
    /// - Throws: Firestore errors during query
    func checkAvailability(_ name: String) async throws -> Bool {
        let doc = try await db.collection("displayNames").document(name).getDocument()
        return !doc.exists
    }

    /// Reserves a display name for a user in Firestore
    /// - Parameters:
    ///   - name: Display name to reserve
    ///   - userId: Firebase Auth UID of the user claiming this name
    /// - Throws: Firestore errors during write operation
    func reserveDisplayName(_ name: String, userId: String) async throws {
        try await db.collection("displayNames").document(name).setData([
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    /// Releases a display name reservation (used when changing displayName)
    /// - Parameter name: Display name to release
    /// - Throws: Firestore errors during delete operation
    func releaseDisplayName(_ name: String) async throws {
        try await db.collection("displayNames").document(name).delete()
    }
}
