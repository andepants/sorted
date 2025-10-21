/// MessageThreadViewModel.swift
///
/// ViewModel for managing message thread operations and real-time RTDB sync.
/// Handles message sending with optimistic UI, RTDB SSE streaming, and read receipts.
///
/// Created: 2025-10-21 (Story 2.3)

import Combine
@preconcurrency import FirebaseDatabase
import Foundation
import SwiftData
import SwiftUI

/// ViewModel for message thread management with real-time RTDB sync
@MainActor
final class MessageThreadViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private let conversationID: String
    private let modelContext: ModelContext

    // MARK: - Real-time Listener Properties

    nonisolated(unsafe) private var sseTask: Task<Void, Never>?
    nonisolated(unsafe) private var messagesRef: DatabaseReference?
    nonisolated(unsafe) private var childAddedHandle: DatabaseHandle?
    nonisolated(unsafe) private var childChangedHandle: DatabaseHandle?

    // MARK: - Initialization

    init(conversationID: String, modelContext: ModelContext) {
        self.conversationID = conversationID
        self.modelContext = modelContext
        self.messagesRef = Database.database().reference().child("messages/\(conversationID)")
    }

    // MARK: - Message Sending

    /// Sends a message with optimistic UI and RTDB sync
    /// - Parameter text: The message text to send
    func sendMessage(text: String) async {
        guard let currentUserID = AuthService.shared.currentUserID else {
            self.error = NSError(
                domain: "MessageThread",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
            )
            return
        }

        // Create message with client-side timestamp (for immediate display)
        let messageID = UUID().uuidString
        let message = MessageEntity(
            id: messageID,
            conversationID: conversationID,
            senderID: currentUserID,
            text: text,
            localCreatedAt: Date(), // Client timestamp for display
            serverTimestamp: nil, // Will be set by RTDB
            sequenceNumber: nil, // Will be set by RTDB
            status: .sent,
            syncStatus: .pending
        )

        // Save locally first (optimistic UI)
        modelContext.insert(message)
        try? modelContext.save()

        // Sync to RTDB in background
        Task { @MainActor in
            do {
                // Push to RTDB (generates server timestamp)
                let messageData: [String: Any] = [
                    "senderID": message.senderID,
                    "text": message.text,
                    "serverTimestamp": ServerValue.timestamp(),
                    "status": "sent"
                ]

                guard let messagesRef = self.messagesRef else { return }
                try await messagesRef.child(messageID).setValue(messageData)

                // Update local sync status
                message.syncStatus = .synced
                try? modelContext.save()

                // Update conversation last message and ensure it exists in RTDB
                await updateConversationLastMessage(text: text, senderID: currentUserID)
            } catch {
                // Mark as failed
                message.syncStatus = .failed
                self.error = error
                try? modelContext.save()
            }
        }
    }

    // MARK: - Real-time RTDB Listener

    /// Starts real-time RTDB listener for messages
    func startRealtimeListener() async {
        guard let messagesRef = self.messagesRef else { return }

        // Listen for new messages via RTDB observe
        childAddedHandle = messagesRef
            .queryOrdered(byChild: "serverTimestamp")
            .queryLimited(toLast: 100) // Load recent 100 messages
            .observe(.childAdded) { [weak self] snapshot in
                guard let self = self else { return }

                Task { @MainActor in
                    await self.handleIncomingMessage(snapshot)
                }
            }

        // Listen for message status updates
        childChangedHandle = messagesRef.observe(.childChanged) { [weak self] snapshot in
            guard let self = self else { return }

            Task { @MainActor in
                await self.handleMessageUpdate(snapshot)
            }
        }
    }

    /// Stops real-time listener and cleans up
    func stopRealtimeListener() {
        cleanup()
    }

    /// Cleanup synchronously (called from deinit)
    nonisolated private func cleanup() {
        if let messagesRef = self.messagesRef {
            if let handle = childAddedHandle {
                messagesRef.removeObserver(withHandle: handle)
            }
            if let handle = childChangedHandle {
                messagesRef.removeObserver(withHandle: handle)
            }
        }
        sseTask?.cancel()
    }

    // MARK: - Read Receipts

    /// Marks all unread messages in conversation as read
    func markAsRead() async {
        guard let currentUserID = AuthService.shared.currentUserID else { return }

        // Fetch all messages in conversation
        let descriptor = FetchDescriptor<MessageEntity>(
            predicate: #Predicate { message in
                message.conversationID == conversationID &&
                message.senderID != currentUserID
            }
        )

        guard let allMessages = try? modelContext.fetch(descriptor) else { return }

        // Filter unread messages
        let unreadMessages = allMessages.filter { $0.status != .read }

        for message in unreadMessages {
            message.status = .read

            // Update RTDB
            Task { @MainActor in
                guard let messagesRef = self.messagesRef else { return }
                try? await messagesRef.child(message.id).updateChildValues([
                    "status": "read"
                ])
            }
        }

        try? modelContext.save()
    }

    // MARK: - Private Methods

    /// Handles incoming message from RTDB
    /// Handles incoming message from RTDB
    private func handleIncomingMessage(_ snapshot: DataSnapshot) async {
        guard let messageData = snapshot.value as? [String: Any] else { return }

        let messageID = snapshot.key

        // Check if message already exists locally (duplicate detection)
        let descriptor = FetchDescriptor<MessageEntity>(
            predicate: #Predicate { $0.id == messageID }
        )

        let existing = try? modelContext.fetch(descriptor).first

        if existing == nil {
            // New message from RTDB
            let message = MessageEntity(
                id: messageID,
                conversationID: conversationID,
                senderID: messageData["senderID"] as? String ?? "",
                text: messageData["text"] as? String ?? "",
                localCreatedAt: Date(), // Use current time for display
                serverTimestamp: Date(
                    timeIntervalSince1970: (messageData["serverTimestamp"] as? TimeInterval ?? 0) / 1000
                ),
                sequenceNumber: messageData["sequenceNumber"] as? Int64,
                status: MessageStatus(rawValue: messageData["status"] as? String ?? "sent") ?? .sent,
                syncStatus: .synced
            )

            modelContext.insert(message)
            try? modelContext.save()

            // Update conversation's last message immediately (optimistic UI)
            let conversationDescriptor = FetchDescriptor<ConversationEntity>(
                predicate: #Predicate { $0.id == conversationID }
            )

            if let conversation = try? modelContext.fetch(conversationDescriptor).first {
                conversation.lastMessageText = message.text
                conversation.lastMessageAt = message.localCreatedAt
                conversation.lastMessageSenderID = message.senderID
                conversation.updatedAt = Date()
                try? modelContext.save()
            }
        }
    }

    /// Handles message update from RTDB (status changes)
    private func handleMessageUpdate(_ snapshot: DataSnapshot) async {
        guard let messageData = snapshot.value as? [String: Any] else { return }

        let messageID = snapshot.key

        // Find existing message
        let descriptor = FetchDescriptor<MessageEntity>(
            predicate: #Predicate { $0.id == messageID }
        )

        guard let existing = try? modelContext.fetch(descriptor).first else { return }

        // Update status (delivered → read)
        if let statusString = messageData["status"] as? String,
           let status = MessageStatus(rawValue: statusString) {
            existing.status = status
            try? modelContext.save()
        }
    }

    /// Ensures conversation exists in RTDB and updates last message
    /// Ensures conversation exists in RTDB and updates last message
    private func updateConversationLastMessage(text: String, senderID: String) async {
        let conversationRef = Database.database().reference().child("conversations/\(conversationID)")

        // Get conversation from local SwiftData
        let descriptor = FetchDescriptor<ConversationEntity>(
            predicate: #Predicate { $0.id == conversationID }
        )

        guard let conversation = try? modelContext.fetch(descriptor).first else {
            print("❌ Error: Conversation \(conversationID) not found in local SwiftData")
            return
        }

        // Update local conversation entity immediately (optimistic UI)
        conversation.lastMessageText = text
        conversation.lastMessageAt = Date()
        conversation.lastMessageSenderID = senderID
        conversation.updatedAt = Date()
        try? modelContext.save()

        // Get conversation to check if it exists and get participants in RTDB
        let snapshot = try? await conversationRef.getData()

        if snapshot?.exists() == false {
            // Conversation doesn't exist in RTDB - create it first
            // This shouldn't normally happen if createConversation() completed successfully
            print("⚠️ Warning: Conversation \(conversationID) not found in RTDB, creating it now")

            // Create conversation in RTDB
            var participantsObject: [String: Bool] = [:]
            for participantID in conversation.participantIDs {
                participantsObject[participantID] = true
            }

            let conversationData: [String: Any] = [
                "participants": participantsObject,
                "participantList": conversation.participantIDs,
                "lastMessage": text,
                "lastMessageTimestamp": ServerValue.timestamp(),
                "lastMessageSenderID": senderID,
                "createdAt": conversation.createdAt.timeIntervalSince1970,
                "updatedAt": ServerValue.timestamp()
            ]

            try? await conversationRef.setValue(conversationData)
        } else {
            // Conversation exists - just update metadata
            try? await conversationRef.updateChildValues([
                "lastMessage": text,
                "lastMessageTimestamp": ServerValue.timestamp(),
                "lastMessageSenderID": senderID
            ])
        }
    }

    deinit {
        cleanup()
    }
}
