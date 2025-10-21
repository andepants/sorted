/// AppContainer.swift
///
/// Singleton container for SwiftData model persistence.
/// Must be initialized before any ViewModel that uses ModelContext.
///
/// Created: 2025-10-21 (Story 2.1 - Pattern 1 from Epic 2)

import Foundation
import SwiftData

/// Singleton container for SwiftData model persistence
@MainActor
final class AppContainer {
    /// Shared instance - initialized once at app launch
    static let shared = AppContainer()

    /// SwiftData model container
    let modelContainer: ModelContainer

    private init() {
        // Define SwiftData schema
        let schema = Schema([
            MessageEntity.self,
            ConversationEntity.self,
            UserEntity.self,
            AttachmentEntity.self,
            FAQEntity.self
        ])

        // Configure persistent storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            // Initialize container
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("✅ AppContainer initialized successfully")
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error)")
        }
    }

    /// Create a new ModelContext for background operations
    func newBackgroundContext() -> ModelContext {
        ModelContext(modelContainer)
    }
}
