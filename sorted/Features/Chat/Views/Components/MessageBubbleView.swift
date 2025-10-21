/// MessageBubbleView.swift
///
/// Message bubble component with WhatsApp-style delivery status indicators.
/// Supports status animations, retry functionality, and accessibility.
///
/// Created: 2025-10-21 (Story 2.3)
/// Enhanced: 2025-10-21 (Story 2.4)

import SwiftUI

/// Message bubble view for chat messages
struct MessageBubbleView: View {
    let message: MessageEntity

    @State private var currentUserID: String?

    var isSentByCurrentUser: Bool {
        message.senderID == currentUserID
    }

    var body: some View {
        HStack {
            if isSentByCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isSentByCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        isSentByCurrentUser ? Color.blue : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(isSentByCurrentUser ? .white : .primary)
                    .cornerRadius(18)
                    .textSelection(.enabled)

                // Timestamp + status
                HStack(spacing: 4) {
                    // Use server timestamp if available, fallback to local
                    Text(message.serverTimestamp ?? message.localCreatedAt, style: .time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    if isSentByCurrentUser {
                        statusIcon
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.2), value: message.status)
                            .animation(.easeInOut(duration: 0.2), value: message.syncStatus)
                    }
                }
            }

            if !isSentByCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .onAppear {
            currentUserID = AuthService.shared.currentUserID
        }
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        switch message.syncStatus {
        case .pending:
            // Sending
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .accessibilityLabel("Sending")

        case .failed:
            // Failed - show retry button
            Button {
                retryMessage()
            } label: {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            .accessibilityLabel("Failed to send. Tap to retry.")

        case .synced:
            // Successfully synced - show delivery status
            switch message.status {
            case .sending, .sent:
                // Sent to server (single checkmark)
                Image(systemName: "checkmark")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Sent")

            case .delivered:
                // Delivered to recipient (double checkmark gray)
                HStack(spacing: 2) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .accessibilityLabel("Delivered")

            case .read:
                // Read by recipient (double checkmark blue)
                HStack(spacing: 2) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 12))
                .foregroundColor(.blue)
                .accessibilityLabel("Read")
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var description = message.text

        if isSentByCurrentUser {
            description += ", "
            switch message.syncStatus {
            case .pending:
                description += "sending"
            case .failed:
                description += "failed to send, tap to retry"
            case .synced:
                switch message.status {
                case .sending, .sent:
                    description += "sent"
                case .delivered:
                    description += "delivered"
                case .read:
                    description += "read"
                }
            }
        } else {
            description += ", received"
        }

        return description
    }

    // MARK: - Retry

    private func retryMessage() {
        Task {
            await SyncCoordinator.shared.retryMessage(message)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(message: MessageEntity(
            id: "1",
            conversationID: "conv1",
            senderID: "user1",
            text: "Hello! How are you?",
            localCreatedAt: Date(),
            status: .sent,
            syncStatus: .synced
        ))

        MessageBubbleView(message: MessageEntity(
            id: "2",
            conversationID: "conv1",
            senderID: "user2",
            text: "I'm doing great, thanks!",
            localCreatedAt: Date(),
            status: .read,
            syncStatus: .synced
        ))
    }
    .padding()
}
