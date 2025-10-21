/// ConversationListView.swift
///
/// Main view displaying all user conversations with search and filtering.
/// Includes "New Message" button to start new conversations.
///
/// Created: 2025-10-21 (Story 2.1)

import SwiftData
import SwiftUI

/// Main conversation list view
struct ConversationListView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var networkMonitor: NetworkMonitor

    // MARK: - Query

    // Query non-archived conversations sorted by last message timestamp
    @Query(
        filter: #Predicate<ConversationEntity> { conversation in
            conversation.isArchived == false
        },
        sort: [SortDescriptor(\ConversationEntity.lastMessageAt, order: .reverse)]
    ) private var conversations: [ConversationEntity]

    // MARK: - State

    @StateObject private var viewModel: ConversationViewModel
    @State private var showRecipientPicker = false
    @State private var searchText = ""
    @State private var selectedConversation: ConversationEntity?
    @State private var errorMessage: String?
    @State private var showError = false

    // MARK: - Initialization

    init() {
        // Initialize ViewModel with ModelContext from AppContainer
        let context = ModelContext(AppContainer.shared.modelContainer)
        _viewModel = StateObject(wrappedValue: ConversationViewModel(modelContext: context))
    }

    // MARK: - Computed Properties

    /// Filtered conversations based on search text
    var filteredConversations: [ConversationEntity] {
        if searchText.isEmpty {
            return Array(conversations)
        }

        let currentUserID = AuthService.shared.currentUserID ?? ""

        return conversations.filter { conversation in
            // Search by display name or last message
            let displayName = conversation.getDisplayName(currentUserID: currentUserID)
            return displayName.localizedCaseInsensitiveContains(searchText) ||
            (conversation.lastMessageText?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Network status banner
                if !networkMonitor.isConnected {
                    NetworkStatusBanner()
                }

                if filteredConversations.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "message",
                        description: Text("Tap + to start messaging")
                    )
                } else {
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationRowView(conversation: conversation)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                archiveConversation(conversation)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                        .contextMenu {
                            Button {
                                togglePin(conversation)
                            } label: {
                                Label(
                                    conversation.isPinned ? "Unpin" : "Pin",
                                    systemImage: conversation.isPinned ? "pin.slash" : "pin"
                                )
                            }

                            Button {
                                toggleUnread(conversation)
                            } label: {
                                Label(
                                    conversation.unreadCount > 0 ? "Mark as Read" : "Mark as Unread",
                                    systemImage: "envelope.badge"
                                )
                            }

                            Button {
                                archiveConversation(conversation)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }

                            Button(role: .destructive) {
                                deleteConversation(conversation)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search conversations")
            .refreshable {
                await viewModel.syncConversations()
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: { showRecipientPicker = true },
                        label: {
                            Image(systemName: "square.and.pencil")
                        }
                    )
                    .accessibilityLabel("New Message")
                    .accessibilityHint("Start a new conversation")
                }
            }
            .task {
                await viewModel.startRealtimeListener()
                // Refresh display names on first load
                await viewModel.refreshAllDisplayNames()
            }
            .onDisappear {
                viewModel.stopRealtimeListener()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh display names when app returns to foreground
                Task {
                    await viewModel.refreshAllDisplayNames()
                }
            }
            .navigationDestination(for: ConversationEntity.self) { conversation in
                MessageThreadView(conversation: conversation)
            }
            .sheet(isPresented: $showRecipientPicker) {
                RecipientPickerView { selectedUserID in
                    Task {
                        await createConversation(withUserID: selectedUserID)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - Methods

    /// Create a new conversation with the selected user
    private func createConversation(withUserID userID: String) async {
        do {
            let conversation = try await viewModel.createConversation(withUserID: userID)
            selectedConversation = conversation
            print("✅ Conversation created: \(conversation.id)")
        } catch let error as ConversationError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Archive a conversation
    private func archiveConversation(_ conversation: ConversationEntity) {
        conversation.isArchived = true
        try? modelContext.save()

        // Sync to RTDB
        Task {
            await viewModel.syncConversation(conversation)
        }
    }

    /// Toggle pin status
    private func togglePin(_ conversation: ConversationEntity) {
        conversation.isPinned.toggle()
        try? modelContext.save()
    }

    /// Toggle unread status
    private func toggleUnread(_ conversation: ConversationEntity) {
        conversation.unreadCount = conversation.unreadCount > 0 ? 0 : 1
        try? modelContext.save()
    }

    /// Delete a conversation
    private func deleteConversation(_ conversation: ConversationEntity) {
        modelContext.delete(conversation)
        try? modelContext.save()

        // Delete from RTDB
        Task {
            await viewModel.deleteConversation(conversation.id)
        }
    }
}

// MARK: - Network Status Banner

/// Banner shown when device is offline
struct NetworkStatusBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text("Offline")
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.2))
        .foregroundColor(.orange)
        .listRowInsets(EdgeInsets())
    }
}

// MARK: - Conversation Row View

/// View for displaying a conversation row
struct ConversationRowView: View {
    let conversation: ConversationEntity
    @State private var displayName: String = "Loading..."

    var body: some View {
        HStack(spacing: 12) {
            // Profile picture placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.system(size: 17, weight: .semibold))

                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let lastMessageAt = conversation.lastMessageAt {
                        Text(lastMessageAt, style: .relative)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text(conversation.lastMessageText ?? "No messages yet")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Spacer()

                    if conversation.unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)

                            Text("\(conversation.unreadCount)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .task {
            // Load display name from cached data or show fallback
            let currentUserID = AuthService.shared.currentUserID ?? ""
            displayName = conversation.getDisplayName(currentUserID: currentUserID)
        }
        .accessibilityLabel("Conversation with \(displayName)")
    }
}

// MARK: - Previews

#Preview {
    ConversationListView()
        .modelContainer(AppContainer.shared.modelContainer)
}
