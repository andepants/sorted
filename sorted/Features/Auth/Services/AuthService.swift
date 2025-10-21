/// AuthService.swift
/// Handles Firebase Auth operations for sign up, login, and session management
/// [Source: Epic 1, Stories 1.1, 1.2]

@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseDatabase
import FirebaseFirestore
import Foundation
import Kingfisher

/// Service responsible for all authentication operations
final class AuthService {
    /// Shared singleton instance
    static let shared = AuthService()

    private let auth: Auth
    private let firestore: Firestore
    private let database: Database

    /// Initializes AuthService with Firebase dependencies
    /// - Parameters:
    ///   - auth: Firebase Auth instance
    ///   - firestore: Firestore database instance
    ///   - database: Realtime Database instance
    init(
        auth: Auth = Auth.auth(),
        firestore: Firestore = Firestore.firestore(),
        database: Database = Database.database()
    ) {
        self.auth = auth
        self.firestore = firestore
        self.database = database
    }

    /// Returns the current authenticated user's ID
    var currentUserID: String? {
        return auth.currentUser?.uid
    }

    // MARK: - Sign Up (Story 1.1)

    /// Creates a new user account with email, password, and display name
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 8 characters)
    ///   - displayName: User's display name (Instagram-style validation)
    /// - Returns: User object with Firebase UID
    /// - Throws: AuthError if validation or Firebase operation fails
    func createUser(email: String, password: String, displayName: String) async throws -> User {
        // 1. Validate displayName format (client-side)
        guard isValidDisplayName(displayName) else {
            throw AuthError.invalidDisplayName
        }

        // 2. Check displayName availability
        let displayNameService = DisplayNameService()
        let isAvailable = try await displayNameService.checkAvailability(displayName)
        guard isAvailable else {
            throw AuthError.displayNameTaken
        }

        // 3. Create Firebase Auth user
        let authResult = try await auth.createUser(withEmail: email, password: password)
        let uid = authResult.user.uid

        // 4. Get ID token and save to Keychain
        let idToken = try await authResult.user.getIDToken()
        let keychainService = KeychainService()
        try keychainService.save(token: idToken)

        // 5. Reserve displayName in Firestore (for uniqueness)
        try await displayNameService.reserveDisplayName(displayName, userId: uid)

        // 6. Create Firestore user document
        let userData: [String: Any] = [
            "email": email,
            "displayName": displayName,
            "photoURL": "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        try await firestore.collection("users").document(uid).setData(userData)

        // 7. Initialize user presence in Realtime Database
        await initializeUserPresence(userId: uid)

        // 8. Create User object
        let user = User(id: uid, email: email, displayName: displayName, photoURL: nil, createdAt: Date())
        return user
    }

    /// Validates displayName format (Instagram-style rules)
    /// - Parameter name: Display name to validate
    /// - Returns: True if valid, false otherwise
    private func isValidDisplayName(_ name: String) -> Bool {
        // Length: 3-30 characters
        guard name.count >= 3 && name.count <= 30 else { return false }

        // Only alphanumeric + underscore + period
        guard name.range(of: "^[a-zA-Z0-9._]+$", options: .regularExpression) != nil else { return false }

        // Cannot start or end with period
        guard !name.hasPrefix(".") && !name.hasSuffix(".") else { return false }

        // No consecutive periods
        guard !name.contains("..") else { return false }

        return true
    }

    // MARK: - Sign In (Story 1.2)

    /// Signs in user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: User object with synced data from Firestore
    /// - Throws: AuthError if login fails
    func signIn(email: String, password: String) async throws -> User {
        // 1. Sign in with Firebase Auth
        let authResult = try await auth.signIn(withEmail: email, password: password)
        let uid = authResult.user.uid

        // 2. Get ID token for Keychain storage
        let idToken = try await authResult.user.getIDToken()

        // 3. Store token in Keychain
        let keychainService = KeychainService()
        try keychainService.save(token: idToken)

        // 4. Fetch user data from Firestore
        let userDoc = try await firestore.collection("users").document(uid).getDocument()

        guard let data = userDoc.data() else {
            throw AuthError.userNotFound
        }

        // 5. Parse user data
        let email = data["email"] as? String ?? ""
        let displayName = data["displayName"] as? String ?? ""
        let photoURL = data["photoURL"] as? String
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        // 6. Create User object
        let user = User(
            id: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            createdAt: createdAt
        )

        // 7. Set user online in Realtime Database
        await setUserOnline(userId: uid)

        return user
    }

    // MARK: - Auto-Login (Story 1.3)

    /// Attempts to auto-login user with stored Keychain token
    /// - Returns: User object if valid token exists, nil otherwise
    func autoLogin() async throws -> User? {
        // 1. Check if there's a current Firebase user
        guard let currentUser = auth.currentUser else {
            return nil
        }

        let uid = currentUser.uid

        // 2. Fetch user data from Firestore
        let userDoc = try await firestore.collection("users").document(uid).getDocument()

        guard let data = userDoc.data() else {
            return nil
        }

        // 3. Parse user data
        let email = data["email"] as? String ?? ""
        let displayName = data["displayName"] as? String ?? ""
        let photoURL = data["photoURL"] as? String
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        // 4. Refresh token and save to Keychain
        guard let currentUser = auth.currentUser else {
            return nil
        }
        let idToken = try await currentUser.getIDToken()
        let keychainService = KeychainService()
        try keychainService.save(token: idToken)

        // 5. Create User object
        let user = User(
            id: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            createdAt: createdAt
        )

        // 6. Set user online in Realtime Database
        await setUserOnline(userId: uid)

        return user
    }

    // MARK: - Logout (Story 1.6)

    /// Signs out the current user and clears Keychain token
    /// - Throws: AuthError if logout fails
    func signOut() async throws {
        // 1. Set presence to offline before signing out
        if let userId = auth.currentUser?.uid {
            await setUserPresence(userId: userId, status: "offline")
        }

        // 2. Sign out from Firebase
        try auth.signOut()

        // 3. Delete token from Keychain
        let keychainService = KeychainService()
        try keychainService.delete()

        // 4. Clear Kingfisher image cache
        KingfisherManager.shared.cache.clearMemoryCache()
        await KingfisherManager.shared.cache.clearDiskCache()
    }

    // MARK: - User Presence Tracking (Realtime Database)

    /// Initialize user presence in Realtime Database
    /// - Parameter userId: User's Firebase UID
    func initializeUserPresence(userId: String) async {
        let db = self.database
        let presenceRef = db.reference().child("userPresence").child(userId)

        let presenceData: [String: Any] = [
            "status": "online",
            "lastSeen": ServerValue.timestamp()
        ]

        do {
            try await presenceRef.setValue(presenceData)

            // Set up disconnect handler (goes offline when connection is lost)
            try await presenceRef.onDisconnectSetValue([
                "status": "offline",
                "lastSeen": ServerValue.timestamp()
            ])
        } catch {
            // Log error but don't fail the operation
            print("Failed to initialize presence: \(error.localizedDescription)")
        }
    }

    /// Update user presence status
    /// - Parameters:
    ///   - userId: User's Firebase UID
    ///   - status: Status string ("online", "offline", "away")
    func setUserPresence(userId: String, status: String) async {
        let db = self.database
        let presenceRef = db.reference().child("userPresence").child(userId)

        let presenceData: [String: Any] = [
            "status": status,
            "lastSeen": ServerValue.timestamp()
        ]

        do {
            try await presenceRef.updateChildValues(presenceData)
        } catch {
            print("Failed to update presence: \(error.localizedDescription)")
        }
    }

    /// Set user presence to online and configure disconnect handler
    /// - Parameter userId: User's Firebase UID
    func setUserOnline(userId: String) async {
        await setUserPresence(userId: userId, status: "online")

        // Set up disconnect handler
        let db = self.database
        let presenceRef = db.reference().child("userPresence").child(userId)
        do {
            try await presenceRef.onDisconnectSetValue([
                "status": "offline",
                "lastSeen": ServerValue.timestamp()
            ])
        } catch {
            print("Failed to set disconnect handler: \(error.localizedDescription)")
        }
    }
}
