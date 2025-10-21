/// PreviewContainer.swift
///
/// Preview-specific ModelContainer with sample data for SwiftUI previews.
///
/// Created: 2025-10-20

import Foundation
import SwiftData

@MainActor
class PreviewContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            MessageEntity.self,
            ConversationEntity.self,
            UserEntity.self,
            AttachmentEntity.self,
            FAQEntity.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true // In-memory only for previews
        )

        guard let container = try? ModelContainer(
            for: schema,
            configurations: [configuration]
        ) else {
            fatalError("Failed to create preview ModelContainer")
        }

        // Insert sample data
        let context = container.mainContext

        // Sample user
        let user = UserEntity(
            id: "preview-user-1",
            email: "sarah@example.com",
            displayName: "Sarah Chen"
        )
        context.insert(user)

        // Sample conversation
        let conversation = ConversationEntity(
            id: "preview-conv-1",
            participantIDs: ["preview-user-1", "preview-user-2"],
            displayName: "John Doe",
            isGroup: false
        )
        context.insert(conversation)

        // Sample messages
        let message1 = MessageEntity(
            conversationID: conversation.id,
            senderID: "preview-user-2",
            text: "Hey! Love your latest video!",
            status: .read,
            syncStatus: .synced
        )
        message1.category = .fan
        message1.categoryConfidence = 0.95
        context.insert(message1)

        let message2 = MessageEntity(
            conversationID: conversation.id,
            senderID: "preview-user-1",
            text: "Thanks so much! More content coming soon",
            status: .sent,
            syncStatus: .synced
        )
        context.insert(message2)

        conversation.messages = [message1, message2]
        conversation.updateWithMessage(message2)

        try? context.save()

        return container
    }()
}
