/// MessageThreadView.swift
///
/// Main message thread view displaying conversation messages with real-time sync.
/// Supports optimistic UI, scroll-to-bottom, keyboard handling, and VoiceOver.
///
/// Created: 2025-10-21 (Story 2.3)

@preconcurrency import FirebaseDatabase
import SwiftData
import SwiftUI

/// Main message thread view
struct MessageThreadView: View {
    // MARK: - Properties

    let conversation: ConversationEntity

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var networkMonitor: NetworkMonitor

    // MARK: - Query

    // Query messages for this conversation sorted by localCreatedAt (Pattern 4: Null-Safe Sorting)
    @Query private var messages: [MessageEntity]

    // MARK: - State

    @StateObject private var viewModel: MessageThreadViewModel
    @StateObject private var syncCoordinator = SyncCoordinator.shared
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    // Typing indicator state
    @State private var typingUserIDs: Set<String> = []
    @State private var typingListenerHandle: DatabaseHandle?

    // MARK: - Initialization

    init(conversation: ConversationEntity) {
        self.conversation = conversation

        // Query messages for this conversation
        let conversationID = conversation.id
        _messages = Query(
            filter: #Predicate<MessageEntity> { message in
                message.conversationID == conversationID
            },
            sort: [
                // ✅ FIXED: Sort by localCreatedAt first (never nil)
                // See Pattern 4 in Epic 2: Null-Safe Sorting
                SortDescriptor(\MessageEntity.localCreatedAt, order: .forward),
                SortDescriptor(\MessageEntity.serverTimestamp, order: .forward),
                SortDescriptor(\MessageEntity.sequenceNumber, order: .forward)
            ]
        )

        // Initialize ViewModel
        let context = ModelContext(AppContainer.shared.modelContainer)
        _viewModel = StateObject(wrappedValue: MessageThreadViewModel(
            conversationID: conversationID,
            modelContext: context
        ))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Network status banner
            if !syncCoordinator.isOnline {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14))

                    Text(syncCoordinator.networkType)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(8)
                .padding(.horizontal)
                .transition(.opacity)
            }

            // Sync progress indicator
            SyncProgressView()

            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }

                        // Typing indicator at bottom
                        if !typingUserIDs.isEmpty {
                            HStack {
                                TypingIndicatorView()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .transition(.opacity)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                    isInputFocused = true // Auto-focus keyboard
                }
                .onChange(of: messages.count) { oldCount, newCount in
                    scrollToBottom(proxy: proxy)

                    // VoiceOver announcement for new messages
                    if newCount > oldCount, let newMessage = messages.last {
                        if newMessage.senderID != AuthService.shared.currentUserID {
                            UIAccessibility.post(
                                notification: .announcement,
                                argument: "New message: \(newMessage.text)"
                            )
                        }
                    }
                }
            }

            // Message input composer
            MessageComposerView(
                text: $messageText,
                characterLimit: 10_000,
                onSend: {
                    await sendMessage()
                }
            )
            .focused($isInputFocused)
            .onChange(of: messageText) { _, newValue in
                handleTypingChange(newValue)
            }
        }
        .navigationTitle(conversation.getRecipientID(currentUserID: AuthService.shared.currentUserID ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Start typing listener
            typingListenerHandle = TypingIndicatorService.shared.listenToTypingIndicators(
                conversationID: conversation.id
            ) { userIDs in
                withAnimation {
                    // Filter out current user's typing
                    typingUserIDs = userIDs.filter { $0 != AuthService.shared.currentUserID }
                }
            }

            await viewModel.startRealtimeListener()
            await viewModel.markAsRead()
        }
        .onDisappear {
            // Cleanup: Stop typing
            if let currentUserID = AuthService.shared.currentUserID {
                TypingIndicatorService.shared.stopTyping(
                    conversationID: conversation.id,
                    userID: currentUserID
                )
            }

            // Remove typing listener
            if let handle = typingListenerHandle {
                TypingIndicatorService.shared.stopListening(
                    conversationID: conversation.id,
                    handle: handle
                )
            }

            viewModel.stopRealtimeListener()
        }
    }

    // MARK: - Private Methods

    /// Sends a message with validation and haptic feedback
    private func sendMessage() async {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate message
        do {
            try MessageValidator.validate(trimmed)
        } catch {
            // Show error: Empty or too long
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }

        let text = messageText
        messageText = "" // Clear input immediately (optimistic UI)

        // Send message
        await viewModel.sendMessage(text: text)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Scrolls to bottom of message list
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    /// Handles typing indicator logic based on message text changes
    private func handleTypingChange(_ text: String) {
        guard let currentUserID = AuthService.shared.currentUserID else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty {
            // User is typing
            TypingIndicatorService.shared.startTyping(
                conversationID: conversation.id,
                userID: currentUserID
            )
        } else {
            // User cleared input
            TypingIndicatorService.shared.stopTyping(
                conversationID: conversation.id,
                userID: currentUserID
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MessageThreadView(conversation: ConversationEntity(
            id: "user1_user2",
            participantIDs: ["user1", "user2"],
            displayName: nil,
            isGroup: false,
            createdAt: Date(),
            syncStatus: .synced
        ))
        .environmentObject(NetworkMonitor.shared)
        .modelContainer(AppContainer.shared.modelContainer)
    }
}
