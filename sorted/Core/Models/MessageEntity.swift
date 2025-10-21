/// MessageEntity.swift
///
/// SwiftData model for local message storage with offline-first capabilities.
/// Stores message content, AI metadata, and sync status for offline queue.
///
/// Created: 2025-10-20

import Foundation
import SwiftData

@Model
final class MessageEntity {
    // MARK: - Core Properties

    /// Unique message identifier (matches Firestore document ID)
    @Attribute(.unique) var id: String

    /// Parent conversation ID
    var conversationID: String

    /// Sender's user ID
    var senderID: String

    /// Message text content
    var text: String

    /// Client timestamp for immediate display (never nil)
    /// Used as primary sort key for null-safe sorting (Pattern 4)
    var localCreatedAt: Date

    /// Server timestamp from RTDB (authoritative ordering)
    /// Can be nil for pending messages not yet synced
    var serverTimestamp: Date?

    /// Server-assigned sequence number for ordering
    /// Detects gaps in message stream for out-of-order delivery
    var sequenceNumber: Int64?

    /// Last update timestamp
    var updatedAt: Date

    // MARK: - Status & Sync

    /// Message delivery status (sending, sent, delivered, read)
    var status: MessageStatus

    /// Sync status for offline queue (pending, synced, failed)
    var syncStatus: SyncStatus

    /// Number of sync retry attempts
    var retryCount: Int

    /// Last sync attempt timestamp
    var lastSyncAttempt: Date?

    /// Sync error message (if failed)
    var syncError: String?

    // MARK: - Message Type

    /// Is this a system message? (e.g., "Alice joined the group")
    var isSystemMessage: Bool

    // MARK: - Read Receipts

    /// Dictionary of user IDs to read timestamps (userID -> when they read the message)
    var readBy: [String: Date]

    // MARK: - AI Metadata

    /// AI-generated category (Fan, Business, Spam, Urgent)
    var category: MessageCategory?

    /// Confidence score for category (0.0 - 1.0)
    var categoryConfidence: Double?

    /// Sentiment analysis result
    var sentiment: MessageSentiment?

    /// Sentiment intensity (low, medium, high)
    var sentimentIntensity: SentimentIntensity?

    /// Opportunity score (0-100) for business messages
    var opportunityScore: Int?

    /// FAQ match ID (if detected)
    var faqMatchID: String?

    /// FAQ confidence score (0.0 - 1.0)
    var faqConfidence: Double?

    /// AI-generated draft reply
    var smartReplyDraft: String?

    /// Supermemory reference ID
    var supermemoryID: String?

    // MARK: - Relationships

    /// Parent conversation (inverse relationship)
    @Relationship(deleteRule: .nullify, inverse: \ConversationEntity.messages)
    var conversation: ConversationEntity?

    /// Message attachments (cascade delete)
    @Relationship(deleteRule: .cascade)
    var attachments: [AttachmentEntity]

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        conversationID: String,
        senderID: String,
        text: String,
        localCreatedAt: Date = Date(),
        serverTimestamp: Date? = nil,
        sequenceNumber: Int64? = nil,
        status: MessageStatus = .sending,
        syncStatus: SyncStatus = .pending,
        isSystemMessage: Bool = false
    ) {
        self.id = id
        self.conversationID = conversationID
        self.senderID = senderID
        self.text = text
        self.localCreatedAt = localCreatedAt
        self.serverTimestamp = serverTimestamp
        self.sequenceNumber = sequenceNumber
        self.updatedAt = localCreatedAt
        self.status = status
        self.syncStatus = syncStatus
        self.retryCount = 0
        self.isSystemMessage = isSystemMessage
        self.readBy = [:]
        self.attachments = []
    }

    // MARK: - Helper Methods

    /// Mark message as synced with Firestore
    func markAsSynced() {
        self.syncStatus = .synced
        self.syncError = nil
        self.updatedAt = Date()
    }

    /// Mark message as failed sync with error
    func markAsFailed(error: String) {
        self.syncStatus = .failed
        self.syncError = error
        self.retryCount += 1
        self.lastSyncAttempt = Date()
        self.updatedAt = Date()
    }

    /// Check if message should be retried
    var shouldRetry: Bool {
        syncStatus == .failed && retryCount < 3
    }

    /// Check if message is pending sync
    var isPendingSync: Bool {
        syncStatus == .pending || (syncStatus == .failed && shouldRetry)
    }
}
