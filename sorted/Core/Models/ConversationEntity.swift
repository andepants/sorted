/// ConversationEntity.swift
///
/// SwiftData model for conversation storage with participant management.
/// Maintains conversation state, unread counts, and message relationships.
///
/// Created: 2025-10-20

import Foundation
import SwiftData

@Model
final class ConversationEntity {
    // MARK: - Core Properties

    /// Unique conversation identifier (matches Firestore document ID)
    @Attribute(.unique) var id: String

    /// Array of participant user IDs
    var participantIDs: [String]

    /// Conversation display name (for groups)
    var displayName: String?

    /// Group photo URL (for group conversations)
    var groupPhotoURL: String?

    /// Is this a group conversation?
    var isGroup: Bool

    /// Array of admin user IDs (for group conversations)
    var adminUserIDs: [String]

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp (when last message was sent)
    var updatedAt: Date

    // MARK: - Conversation State

    /// Is conversation pinned?
    var isPinned: Bool

    /// Is conversation muted?
    var isMuted: Bool

    /// Is conversation archived?
    var isArchived: Bool

    /// Unread message count
    var unreadCount: Int

    /// Last message preview text
    var lastMessageText: String?

    /// Last message timestamp
    var lastMessageAt: Date?

    /// Last message sender ID
    var lastMessageSenderID: String?

    /// Sync status for offline queue (pending, synced, failed)
    var syncStatus: SyncStatus

    // MARK: - Display Name Caching

    /// Cached display name for the recipient (one-on-one conversations)
    var recipientDisplayName: String?

    /// Timestamp when display name was last fetched/updated
    var displayNameLastUpdated: Date?

    // MARK: - AI Metadata

    /// Supermemory conversation ID for RAG context
    var supermemoryConversationID: String?

    // MARK: - Relationships

    /// All messages in this conversation (cascade delete)
    @Relationship(deleteRule: .cascade)
    var messages: [MessageEntity]

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        participantIDs: [String],
        displayName: String? = nil,
        isGroup: Bool = false,
        adminUserIDs: [String] = [],
        createdAt: Date = Date(),
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.participantIDs = participantIDs
        self.displayName = displayName
        self.isGroup = isGroup
        self.adminUserIDs = adminUserIDs
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isPinned = false
        self.isMuted = false
        self.isArchived = false
        self.unreadCount = 0
        self.syncStatus = syncStatus
        self.messages = []
    }

    // MARK: - Helper Methods

    /// Update conversation with latest message
    func updateWithMessage(_ message: MessageEntity) {
        self.lastMessageText = message.text
        self.lastMessageAt = message.localCreatedAt
        self.lastMessageSenderID = message.senderID
        self.updatedAt = Date()
    }

    /// Increment unread count
    func incrementUnreadCount() {
        self.unreadCount += 1
    }

    /// Reset unread count (when conversation is opened)
    func markAsRead() {
        self.unreadCount = 0
    }

    /// Get sorted messages (newest first)
    var sortedMessages: [MessageEntity] {
        messages.sorted { $0.localCreatedAt > $1.localCreatedAt }
    }

    /// Get messages pending sync
    var pendingSyncMessages: [MessageEntity] {
        messages.filter { $0.isPendingSync }
    }

    /// Get recipient ID (for one-on-one conversations)
    /// - Parameter currentUserID: The current user's ID
    /// - Returns: The recipient's user ID or "Unknown"
    func getRecipientID(currentUserID: String) -> String {
        // Get the participant who is NOT the current user
        guard let recipientID = participantIDs.first(where: { $0 != currentUserID }) else {
            return "Unknown"
        }
        return recipientID
    }

    /// Get display name for conversation
    /// Uses cached recipient display name for one-on-one chats, falls back to "Unknown User"
    /// - Parameter currentUserID: The current user's ID
    /// - Returns: Display name or fallback
    func getDisplayName(currentUserID: String) -> String {
        // For one-on-one conversations, use cached recipient display name
        if !isGroup {
            return recipientDisplayName ?? "Unknown User"
        }

        // For group conversations, use group display name
        return displayName ?? "Group Chat"
    }

    /// Check if display name cache needs refresh (older than 1 hour)
    var needsDisplayNameRefresh: Bool {
        guard let lastUpdated = displayNameLastUpdated else {
            return true // Never fetched
        }

        let oneHourAgo = Date().addingTimeInterval(-3600)
        return lastUpdated < oneHourAgo
    }

    /// Update cached display name
    func updateDisplayName(_ name: String?) {
        self.recipientDisplayName = name
        self.displayNameLastUpdated = Date()
    }
}
