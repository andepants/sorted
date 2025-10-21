/// SortedApp.swift
/// Sorted - AI-Powered Messaging App
///
/// Main entry point for the Sorted iOS application.
/// Configured for Swift 6, iOS 17+, and SwiftUI with SwiftData persistence.

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import Kingfisher
import SwiftData
import SwiftUI

@main
struct SortedApp: App {
    // MARK: - Properties

    /// Register AppDelegate for FCM setup and push notification handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Network connectivity monitor - initialized ONCE and injected globally
    @StateObject private var networkMonitor = NetworkMonitor.shared

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(networkMonitor) // Inject network monitor globally
                .onReceive(NotificationCenter.default.publisher(for: .openConversation)) { notification in
                    // Handle deep link to conversation when notification is tapped
                    if let conversationID = notification.userInfo?["conversationID"] as? String {
                        // Navigate to MessageThreadView
                        // NOTE: Navigation implementation pending Story 2.3
                        print("Navigate to conversation: \(conversationID)")
                    }
                }
        }
        .modelContainer(AppContainer.shared.modelContainer)
    }
}
