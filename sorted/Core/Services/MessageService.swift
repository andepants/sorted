/// MessageService.swift
///
/// Service for syncing messages to Firebase RTDB.
/// Handles message synchronization, status updates, and read receipts.
///
/// Created: 2025-10-21 (Story 2.5)

@preconcurrency import FirebaseDatabase
import Foundation

/// Service for message synchronization with RTDB
final class MessageService {
    // MARK: - Singleton

    static let shared = MessageService()

    // MARK: - Private Properties

    private let database = Database.database().reference()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Syncs a message to RTDB
    /// - Parameter message: The message to sync
    /// - Throws: Error if RTDB write fails
    func syncMessage(_ message: MessageEntity) async throws {
        let messagesRef = database.child("messages/\(message.conversationID)/\(message.id)")

        let messageData: [String: Any] = [
            "senderID": message.senderID,
            "text": message.text,
            "serverTimestamp": ServerValue.timestamp(),
            "status": message.status.rawValue
        ]

        try await messagesRef.setValue(messageData)
    }

    /// Updates message status in RTDB
    /// - Parameters:
    ///   - messageID: The message ID
    ///   - conversationID: The conversation ID
    ///   - status: The new status
    func updateMessageStatus(messageID: String, conversationID: String, status: MessageStatus) async throws {
        let messagesRef = database.child("messages/\(conversationID)/\(messageID)")

        try await messagesRef.updateChildValues([
            "status": status.rawValue
        ])
    }

    /// Marks a message as read in RTDB
    /// - Parameters:
    ///   - messageID: The message ID
    ///   - conversationID: The conversation ID
    func markMessageAsRead(messageID: String, conversationID: String) async throws {
        try await updateMessageStatus(messageID: messageID, conversationID: conversationID, status: .read)
    }
}
