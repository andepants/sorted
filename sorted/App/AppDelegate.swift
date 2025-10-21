/// AppDelegate.swift
/// Sorted - AI-Powered Messaging App
///
/// Handles app lifecycle events, Firebase Cloud Messaging (FCM) setup,
/// and push notification registration/handling.
///
/// Responsibilities:
/// - Configure Firebase on app launch
/// - Register for remote notifications (APNs)
/// - Receive and store FCM tokens in Firestore
/// - Handle notification display (foreground/background)
/// - Handle notification taps for deep linking
///
/// Dependencies:
/// - Firebase Cloud Messaging (FCM)
/// - UserNotifications framework
/// - AuthService for current user ID
///
/// Created: 2025-10-20
/// Last Modified: 2025-10-21

import FirebaseCore
import FirebaseDatabase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

// MARK: - AppDelegate

/// Application delegate for handling app lifecycle and push notifications
@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Lifecycle Methods

    /// Called when the application finishes launching
    /// - Parameters:
    ///   - application: The application instance
    ///   - launchOptions: Launch options dictionary
    /// - Returns: True if launch was successful
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Enable RTDB persistence for offline support
        Database.database().isPersistenceEnabled = true

        // Set FCM messaging delegate
        Messaging.messaging().delegate = self

        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        Task {
            await requestNotificationPermissions()
        }

        // Register for remote notifications (APNs)
        application.registerForRemoteNotifications()

        return true
    }

    // MARK: - Push Notification Registration

    /// Called when the app successfully registers for remote notifications
    /// - Parameters:
    ///   - application: The application instance
    ///   - deviceToken: The device token for push notifications (APNs token)
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Pass APNs token to FCM
        Messaging.messaging().apnsToken = deviceToken

        // Log token for debugging (first few bytes only)
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNs token (first 16 chars): \(String(token.prefix(16)))...")
    }

    /// Called when the app fails to register for remote notifications
    /// - Parameters:
    ///   - application: The application instance
    ///   - error: The error that occurred
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        // Note: This is expected on iOS Simulator (APNs doesn't work on simulator)
    }

    // MARK: - Notification Permissions

    /// Requests notification permissions from the user
    /// - Note: This is called on app launch, but won't re-prompt if already answered
    private func requestNotificationPermissions() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    /// Called when FCM token is received or refreshed
    /// - Parameters:
    ///   - messaging: The messaging instance
    ///   - fcmToken: The FCM registration token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }

        // Log token for debugging (first 16 chars only)
        print("FCM Token (first 16 chars): \(String(token.prefix(16)))...")

        // Store token in Firestore
        Task { @MainActor in
            await storeFCMToken(token)
        }
    }

    /// Stores the FCM token in Firestore for the current user
    /// - Parameter token: The FCM token to store
    /// - Note: Token is stored at /users/{userId}/fcmToken with timestamp
    private func storeFCMToken(_ token: String) async {
        guard let userID = AuthService.shared.currentUserID else {
            print("No authenticated user - cannot store FCM token")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        do {
            try await userRef.updateData([
                "fcmToken": token,
                "fcmTokenUpdatedAt": FieldValue.serverTimestamp()
            ])
            print("FCM token stored successfully in Firestore")
        } catch {
            print("Error storing FCM token: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in FOREGROUND
    /// - Parameters:
    ///   - center: The notification center
    ///   - notification: The notification to present
    ///   - completionHandler: Handler to call with presentation options
    /// - Note: For messaging app, we suppress banner when app is open
    ///         RTDB real-time listener will update UI automatically
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        print("Notification received in foreground: \(userInfo)")

        // For messaging app, suppress notification banner when app is open
        // RTDB real-time listener will update UI automatically
        completionHandler([]) // Don't show notification
    }

    /// Handle notification TAP when app is backgrounded/closed
    /// - Parameters:
    ///   - center: The notification center
    ///   - response: The user's response to the notification
    ///   - completionHandler: Handler to call when finished processing
    /// - Note: Extracts conversationID and posts deep link event
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        print("Notification tapped: \(userInfo)")

        // Extract conversation ID for deep linking
        if let conversationID = userInfo["conversationID"] as? String {
            // Notify app to navigate to conversation
            NotificationCenter.default.post(
                name: .openConversation,
                object: nil,
                userInfo: ["conversationID": conversationID]
            )
            print("Posted deep link event for conversation: \(conversationID)")
        }

        completionHandler()
    }
}

// MARK: - Notification Names

/// Notification name for deep linking to conversations
extension Notification.Name {
    static let openConversation = Notification.Name("openConversation")
}
