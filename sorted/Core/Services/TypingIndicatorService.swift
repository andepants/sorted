/// TypingIndicatorService.swift
///
/// Service for real-time typing indicators using RTDB ephemeral storage.
/// Features throttled events, auto-stop, and .onDisconnect() cleanup.
///
/// Created: 2025-10-21 (Story 2.6)

@preconcurrency import FirebaseDatabase
import Foundation

/// Service for managing typing indicators with RTDB
final class TypingIndicatorService {
    // MARK: - Singleton

    static let shared = TypingIndicatorService()

    // MARK: - Private Properties

    private let database = Database.database().reference()
    private var throttleTimers: [String: Timer] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Starts typing indicator for a user in a conversation
    /// Throttles to max 1 update per 3 seconds
    /// - Parameters:
    ///   - conversationID: The conversation ID
    ///   - userID: The user who is typing
    func startTyping(conversationID: String, userID: String) {
        // Throttle typing events (max 1 per 3 seconds)
        let key = "\(conversationID)_\(userID)"

        if throttleTimers[key] != nil {
            return // Already typing, don't send duplicate event
        }

        let typingRef = database
            .child("conversations/\(conversationID)/typing/\(userID)")

        // Set typing state
        typingRef.setValue(true)

        // Auto-cleanup on disconnect (RTDB feature!)
        typingRef.onDisconnectRemoveValue()

        // Throttle for 3 seconds
        throttleTimers[key] = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.throttleTimers[key] = nil

                // Auto-stop typing after 3 seconds
                self?.stopTyping(conversationID: conversationID, userID: userID)
            }
        }
    }

    /// Stops typing indicator for a user in a conversation
    /// - Parameters:
    ///   - conversationID: The conversation ID
    ///   - userID: The user who stopped typing
    func stopTyping(conversationID: String, userID: String) {
        let key = "\(conversationID)_\(userID)"
        throttleTimers[key]?.invalidate()
        throttleTimers[key] = nil

        let typingRef = database
            .child("conversations/\(conversationID)/typing/\(userID)")

        typingRef.removeValue()
    }

    /// Listens to typing indicators in a conversation
    /// - Parameters:
    ///   - conversationID: The conversation ID
    ///   - onChange: Closure called with set of typing user IDs
    /// - Returns: DatabaseHandle for cleanup
    func listenToTypingIndicators(
        conversationID: String,
        onChange: @escaping (Set<String>) -> Void
    ) -> DatabaseHandle {
        let typingRef = database
            .child("conversations/\(conversationID)/typing")

        return typingRef.observe(.value) { snapshot in
            var typingUserIDs = Set<String>()

            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                if let isTyping = child.value as? Bool, isTyping {
                    typingUserIDs.insert(child.key)
                }
            }

            onChange(typingUserIDs)
        }
    }

    /// Stops listening to typing indicators
    /// - Parameters:
    ///   - conversationID: The conversation ID
    ///   - handle: The DatabaseHandle from listenToTypingIndicators
    func stopListening(conversationID: String, handle: DatabaseHandle) {
        database
            .child("conversations/\(conversationID)/typing")
            .removeObserver(withHandle: handle)
    }
}
