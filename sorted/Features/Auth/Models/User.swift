/// User.swift
/// Swift model representing authenticated user data
/// [Source: Epic 1, Story 1.1]

import Foundation

/// Represents an authenticated user in the Sorted app
struct User: Sendable, Codable, Identifiable {
    /// Firebase Auth UID (unique identifier)
    let id: String

    /// User's email address
    var email: String

    /// User's display name (Instagram-style: 3-30 chars, alphanumeric + _ + .)
    var displayName: String

    /// Optional Firebase Storage URL for profile picture (HTTPS download URL)
    var photoURL: String?

    /// Timestamp when the account was created
    let createdAt: Date

    /// Initializes a new User instance
    /// - Parameters:
    ///   - id: Firebase Auth UID
    ///   - email: User's email address
    ///   - displayName: User's display name
    ///   - photoURL: Optional profile picture URL (HTTPS download URL from Firebase Storage)
    ///   - createdAt: Account creation timestamp
    init(id: String, email: String, displayName: String, photoURL: String? = nil, createdAt: Date) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
    }
}
