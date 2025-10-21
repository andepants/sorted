/// ConversationViewModel.swift
///
/// ViewModel for managing conversation operations and state.
/// Handles conversation creation, validation, and RTDB synchronization.
///
/// Created: 2025-10-21 (Story 2.1)

import Combine
@preconcurrency import FirebaseDatabase
import Foundation
import SwiftData
import SwiftUI

/// ViewModel for conversation management with optimistic UI and offline support
@MainActor
final class ConversationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var conversations: [ConversationEntity] = []
    @Published var isLoading = false
    @Published var error: ConversationError?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let conversationService: ConversationService

    // MARK: - Initialization

    init(modelContext: ModelContext, conversationService: ConversationService = .shared) {
        self.modelContext = modelContext
        self.conversationService = conversationService
    }

    // MARK: - Conversation Creation

    /// Creates a new one-on-one conversation with deterministic ID
    /// - Parameter userID: The recipient's user ID
    /// - Returns: The created or existing conversation entity
    /// - Throws: ConversationError if validation fails
    func createConversation(withUserID userID: String) async throws -> ConversationEntity {
        isLoading = true
        defer { isLoading = false }

        // Validate recipient
        try await validateRecipient(userID: userID)

        // Generate conversation ID
        let (conversationID, participants) = try generateConversationID(with: userID)

        // Check local SwiftData first (optimistic)
        let localDescriptor = FetchDescriptor<ConversationEntity>(
            predicate: #Predicate { $0.id == conversationID }
        )

        if let existing = try? modelContext.fetch(localDescriptor).first {
            return existing
        }

        // Check RTDB for existing conversation (handles simultaneous creation)
        if let remoteConversation = try await conversationService.findConversation(id: conversationID) {
            // Sync remote conversation to local SwiftData
            modelContext.insert(remoteConversation)
            try modelContext.save()

            // Haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            return remoteConversation
        }

        // Create new conversation
        let conversation = ConversationEntity(
            id: conversationID, // Deterministic!
            participantIDs: participants,
            displayName: nil,
            isGroup: false,
            createdAt: Date(),
            syncStatus: .pending
        )

        // Save locally first (optimistic UI)
        modelContext.insert(conversation)
        try modelContext.save()

        // Fetch display name immediately for new conversations
        await fetchAndCacheDisplayName(for: conversation)

        // Sync to RTDB synchronously (CRITICAL: must complete before messages can be sent)
        do {
            try await conversationService.syncConversation(conversation)
            conversation.syncStatus = .synced
            try? modelContext.save()

            // Haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            conversation.syncStatus = .failed
            self.error = .creationFailed
            try? modelContext.save()
            throw error // Re-throw to prevent message sending on failed conversation creation
        }

        return conversation
    }

    // MARK: - Private Helpers

    /// Validates that the recipient exists and is not blocked
    /// - Parameter userID: The recipient's user ID
    /// - Throws: ConversationError if validation fails
    /// Validates that the recipient exists and is not blocked
    /// - Parameter userID: The recipient's user ID
    /// - Throws: ConversationError if validation fails
    private func validateRecipient(userID: String) async throws {
        // Check recipient exists
        guard (try? await conversationService.getUser(userID: userID)) != nil else {
            let error = ConversationError.recipientNotFound
            self.error = error
            throw error
        }

        // Check if user is blocked
        if try await conversationService.isBlocked(userID: userID) {
            let error = ConversationError.userBlocked
            self.error = error
            throw error
        }
    }

    /// Generates a deterministic conversation ID from participant IDs
    /// - Parameter userID: The other participant's user ID
    /// - Returns: Tuple of (conversationID, participants array)
    /// - Throws: ConversationError if user is not authenticated
    private func generateConversationID(with userID: String) throws -> (String, [String]) {
        guard let currentUserID = AuthService.shared.currentUserID else {
            let error = ConversationError.notAuthenticated
            self.error = error
            throw error
        }

        let participants = [currentUserID, userID].sorted()
        let conversationID = participants.joined(separator: "_")
        return (conversationID, participants)
    }

    // MARK: - Conversation Management

    /// Fetches and caches display name for a conversation's recipient
    /// - Parameter conversation: The conversation to fetch display name for
    func fetchAndCacheDisplayName(for conversation: ConversationEntity) async {
        guard let currentUserID = AuthService.shared.currentUserID else { return }

        // Only fetch if needed (cache expired or never fetched)
        guard conversation.needsDisplayNameRefresh else { return }

        // Get recipient ID
        let recipientID = conversation.getRecipientID(currentUserID: currentUserID)
        guard recipientID != "Unknown" else { return }

        // Fetch display name from Firestore
        do {
            let displayName = try await conversationService.fetchDisplayName(for: recipientID)
            conversation.updateDisplayName(displayName)
            try? modelContext.save()
        } catch {
            // Failed to fetch - keep existing cached value or default to "Unknown User"
            print("Failed to fetch display name for \(recipientID): \(error)")
        }
    }

    /// Syncs a conversation to RTDB
    /// - Parameter conversation: The conversation to sync
    func syncConversation(_ conversation: ConversationEntity) async {
        do {
            try await conversationService.syncConversation(conversation)
            conversation.syncStatus = .synced
            try? modelContext.save()
        } catch {
            conversation.syncStatus = .failed
            self.error = .networkError
            try? modelContext.save()
        }
    }

    /// Deletes a conversation from RTDB and local storage
    /// - Parameter conversationID: The conversation ID to delete
    func deleteConversation(_ conversationID: String) async {
        // Remove from local SwiftData
        let descriptor = FetchDescriptor<ConversationEntity>(
            predicate: #Predicate { $0.id == conversationID }
        )

        if let conversation = try? modelContext.fetch(descriptor).first {
            modelContext.delete(conversation)
            try? modelContext.save()
        }

        // NOTE: RTDB deletion pending backend implementation
    }

    // MARK: - Real-time RTDB Listener

    nonisolated(unsafe) private var sseTask: Task<Void, Never>?
    nonisolated(unsafe) private var conversationsObserverHandle: DatabaseHandle?

    /// Start listening to RTDB conversations in real-time
    func startRealtimeListener() async {
        guard let currentUserID = AuthService.shared.currentUserID else { return }

        let conversationsRef = Database.database().reference().child("conversations")

        // Store observer handle for cleanup
        conversationsObserverHandle = conversationsRef.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }

            Task { @MainActor in
                for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                    self.processConversationSnapshot(child, currentUserID: currentUserID)
                }
            }
        }
    }

    /// Process a single conversation snapshot from RTDB
    /// - Parameters:
    ///   - snapshot: The conversation snapshot
    ///   - currentUserID: The current user's ID
    private func processConversationSnapshot(_ snapshot: DataSnapshot, currentUserID: String) {
        guard let conversationData = snapshot.value as? [String: Any] else { return }

        // Check if current user is participant
        let participants = conversationData["participants"] as? [String: Bool] ?? [:]
        guard participants[currentUserID] == true else { return }

        // Extract data
        let participantList = conversationData["participantList"] as? [String] ?? []
        let conversationID = snapshot.key

        // Check if exists locally
        let descriptor = FetchDescriptor<ConversationEntity>(
            predicate: #Predicate { $0.id == conversationID }
        )

        let existing = try? modelContext.fetch(descriptor).first

        if existing == nil {
            createNewConversationFromRTDB(
                id: conversationID,
                participantList: participantList,
                data: conversationData,
                currentUserID: currentUserID
            )
        } else if let existing = existing {
            updateExistingConversationFromRTDB(existing, data: conversationData, currentUserID: currentUserID)
        }

        try? modelContext.save()
    }

    /// Create a new conversation entity from RTDB data
    private func createNewConversationFromRTDB(
        id: String,
        participantList: [String],
        data: [String: Any],
        currentUserID: String
    ) {
        let conversation = ConversationEntity(
            id: id,
            participantIDs: participantList,
            displayName: nil,
            isGroup: false,
            createdAt: Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? 0),
            syncStatus: .synced
        )

        // Set conversation properties
        conversation.lastMessageText = data["lastMessage"] as? String
        let lastMessageTimestamp = data["lastMessageTimestamp"] as? TimeInterval ?? 0
        conversation.lastMessageAt = Date(timeIntervalSince1970: lastMessageTimestamp)
        conversation.lastMessageSenderID = data["lastMessageSenderID"] as? String

        // Set unread count
        if let senderID = data["lastMessageSenderID"] as? String, senderID != currentUserID {
            conversation.unreadCount = 1
        } else {
            conversation.unreadCount = 0
        }

        modelContext.insert(conversation)

        // Fetch display name in background
        Task {
            await fetchAndCacheDisplayName(for: conversation)
        }
    }

    /// Update an existing conversation entity from RTDB data
    private func updateExistingConversationFromRTDB(
        _ conversation: ConversationEntity,
        data: [String: Any],
        currentUserID: String
    ) {
        let oldLastMessageSenderID = conversation.lastMessageSenderID
        let newLastMessageSenderID = data["lastMessageSenderID"] as? String

        conversation.lastMessageText = data["lastMessage"] as? String
        let lastMessageTimestamp = data["lastMessageTimestamp"] as? TimeInterval ?? 0
        conversation.lastMessageAt = Date(timeIntervalSince1970: lastMessageTimestamp)
        conversation.lastMessageSenderID = newLastMessageSenderID

        // Increment unread count if there's a new message from someone else
        if let newSenderID = newLastMessageSenderID,
           newSenderID != currentUserID,
           newSenderID != oldLastMessageSenderID {
            conversation.incrementUnreadCount()
        }
    }

    /// Stop listening to RTDB conversations
    func stopRealtimeListener() {
        if let handle = conversationsObserverHandle {
            Database.database().reference().child("conversations").removeObserver(withHandle: handle)
        }
        sseTask?.cancel()
        sseTask = nil
    }

    /// Refresh display names for all conversations
    func refreshAllDisplayNames() async {
        guard AuthService.shared.currentUserID != nil else { return }

        let descriptor = FetchDescriptor<ConversationEntity>(
            predicate: #Predicate { !$0.isArchived }
        )

        guard let conversations = try? modelContext.fetch(descriptor) else { return }

        // Refresh display names sequentially (SwiftData models are main actor-isolated)
        for conversation in conversations {
            await fetchAndCacheDisplayName(for: conversation)
        }
    }

    /// Manually sync conversations from RTDB (for pull-to-refresh)
    func syncConversations() async {
        // Refresh display names first
        await refreshAllDisplayNames()

        // Then refresh conversations from RTDB
        stopRealtimeListener()
        await startRealtimeListener()
    }

    /// Cleanup synchronously (called from deinit)
    nonisolated private func cleanup() {
        if let handle = conversationsObserverHandle {
            Database.database().reference().child("conversations").removeObserver(withHandle: handle)
        }
        sseTask?.cancel()
    }

    deinit {
        cleanup()
    }
}

// MARK: - Error Handling

enum ConversationError: LocalizedError {
    case recipientNotFound
    case userBlocked
    case creationFailed
    case networkError
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .recipientNotFound:
            return "User not found. Please check the username and try again."
        case .userBlocked:
            return "You cannot message this user."
        case .creationFailed:
            return "Failed to create conversation. Please try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .notAuthenticated:
            return "You must be signed in to create conversations."
        }
    }
}
