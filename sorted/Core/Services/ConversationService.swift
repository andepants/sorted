/// ConversationService.swift
///
/// Service for managing conversations in Firebase Realtime Database.
/// Handles conversation CRUD operations and user validation.
///
/// Created: 2025-10-21 (Story 2.1)

@preconcurrency import FirebaseDatabase
@preconcurrency import FirebaseFirestore
import Foundation
import SwiftData

/// Service responsible for conversation operations in RTDB
final class ConversationService {
    /// Shared singleton instance
    static let shared = ConversationService()

    private let database: DatabaseReference

    private init() {
        self.database = Database.database().reference()
    }

    // MARK: - Conversation Operations

    /// Syncs a conversation to RTDB
    /// - Parameter conversation: The conversation entity to sync
    /// - Throws: Error if RTDB write fails
    func syncConversation(_ conversation: ConversationEntity) async throws {
        // Convert participantIDs array to object for security rules
        var participantsObject: [String: Bool] = [:]
        for participantID in conversation.participantIDs {
            participantsObject[participantID] = true
        }

        var conversationData: [String: Any] = [
            "participants": participantsObject,              // Object for security rules
            "participantList": conversation.participantIDs,  // Array for Swift iteration
            "lastMessage": conversation.lastMessageText ?? "",
            "lastMessageTimestamp": ServerValue.timestamp(),
            "lastMessageSenderID": conversation.lastMessageSenderID ?? "",
            "createdAt": conversation.createdAt.timeIntervalSince1970,
            "updatedAt": ServerValue.timestamp(),
            "isGroup": conversation.isGroup
        ]

        // Add group-specific fields if it's a group conversation
        if conversation.isGroup {
            conversationData["groupName"] = conversation.displayName ?? ""
            conversationData["groupPhotoURL"] = conversation.groupPhotoURL ?? ""

            // Convert adminUserIDs array to object for security rules
            var adminObject: [String: Bool] = [:]
            for adminID in conversation.adminUserIDs {
                adminObject[adminID] = true
            }
            conversationData["adminUserIDs"] = adminObject
        }

        // Inline reference to avoid Swift 6 concurrency warnings
        try await database.child("conversations/\(conversation.id)").setValue(conversationData)
    }

    /// Finds a conversation by ID in RTDB
    /// - Parameter id: The conversation ID to find
    /// - Returns: ConversationEntity if found, nil otherwise
    func findConversation(id: String) async throws -> ConversationEntity? {
        // Use getData() with error handling for non-existent conversations
        // Note: Will return nil for permission denied (expected when conversation doesn't exist)
        do {
            // Inline reference to avoid Swift 6 concurrency warnings
            let snapshot = try await database.child("conversations/\(id)").getData()

            guard snapshot.exists(),
                  let conversationData = snapshot.value as? [String: Any] else {
                return nil
            }

            // Parse participantList (array) from RTDB
            let participantList = conversationData["participantList"] as? [String] ?? []

            return ConversationEntity(
                id: id,
                participantIDs: participantList,
                displayName: nil,
                isGroup: false,
                createdAt: Date(
                    timeIntervalSince1970: conversationData["createdAt"] as? TimeInterval ?? 0
                ),
                syncStatus: .synced
            )
        } catch {
            // If conversation doesn't exist or permission denied, return nil
            // This is expected behavior when checking for new conversations
            print("findConversation: conversation not found or permission denied - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - User Operations

    /// Fetches display name from Firestore user profile
    /// - Parameter userID: The user ID to fetch display name for
    /// - Returns: Display name string, or nil if not found
    func fetchDisplayName(for userID: String) async throws -> String? {
        let firestore = Firestore.firestore()
        let userDoc = try await firestore.collection("users").document(userID).getDocument()

        guard userDoc.exists,
              let data = userDoc.data(),
              let displayName = data["displayName"] as? String else {
            return nil
        }

        return displayName
    }

    /// Listen to display name changes for a user
    /// - Parameters:
    ///   - userID: The user ID to listen to
    ///   - onChange: Callback when display name changes
    /// - Returns: Listener registration for cleanup
    @MainActor
    func listenToDisplayName(
        for userID: String,
        onChange: @escaping (String?) -> Void
    ) -> ListenerRegistration {
        let firestore = Firestore.firestore()

        return firestore.collection("users").document(userID)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot,
                      snapshot.exists,
                      let data = snapshot.data(),
                      error == nil else {
                    onChange(nil)
                    return
                }

                let displayName = data["displayName"] as? String
                onChange(displayName)
            }
    }

    /// Gets a user by ID from Firestore (user profiles stored in Firestore, not RTDB)
    /// - Parameter userID: The user ID to fetch
    /// - Returns: UserEntity if found, nil otherwise
    func getUser(userID: String) async throws -> UserEntity? {
        let firestore = Firestore.firestore()
        let userDoc = try await firestore.collection("users").document(userID).getDocument()

        guard userDoc.exists,
              let data = userDoc.data() else {
            return nil
        }

        return UserEntity(
            id: userID,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "Unknown User",
            photoURL: data["photoURL"] as? String,
            createdAt: Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? 0)
        )
    }

    /// Checks if a user is blocked
    /// - Parameter userID: The user ID to check
    /// - Returns: True if the user is blocked, false otherwise
    func isBlocked(userID: String) async throws -> Bool {
        guard let currentUserID = AuthService.shared.currentUserID else {
            return false
        }

        // Inline reference to avoid Swift 6 concurrency warnings
        let snapshot = try await database.child("users/\(currentUserID)/blockedUsers/\(userID)").getData()
        return snapshot.exists()
    }
}
