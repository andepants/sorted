/// SortedApp.swift
/// Sorted - AI-Powered Messaging App
///
/// Main entry point for the Sorted iOS application.
/// Configured for Swift 6, iOS 17+, and SwiftUI with SwiftData persistence.

import SwiftUI
import SwiftData
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import Kingfisher

@main
struct SortedApp: App {
    // MARK: - Properties

    /// Shared model container for the app
    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        // Initialize Firebase
        FirebaseApp.configure()

        print("✅ Firebase initialized successfully")
        if let app = FirebaseApp.app() {
            print("   Project ID: \(app.options.projectID ?? "unknown")")
            print("   Bundle ID: \(app.options.bundleID ?? "unknown")")
        }

        // Initialize SwiftData ModelContainer
        do {
            // Define the schema with all model types
            let schema = Schema([
                MessageEntity.self,
                ConversationEntity.self,
                UserEntity.self,
                AttachmentEntity.self,
                FAQEntity.self
            ])

            // Configure model container
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            // Create container
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("✅ SwiftData ModelContainer initialized successfully")
            print("   Entities: MessageEntity, ConversationEntity, UserEntity, AttachmentEntity, FAQEntity")

        } catch {
            fatalError("❌ Failed to initialize ModelContainer: \(error)")
        }
    }

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
