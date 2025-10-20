# Epic 1: User Authentication & Profiles

**Phase:** MVP (Day 1 - 24 Hours)
**Priority:** P0 (Blocker)
**Estimated Time:** 2-3 hours
**Epic Owner:** iOS Development Team
**Dependencies:** Epic 0 (Project Scaffolding) must be complete

---

## Overview

Implement complete user authentication system using Firebase Auth with email/password, including sign up, login, password reset, persistent sessions via Keychain, and basic user profile management. This epic establishes the foundation for all user-specific features in the MessageAI app.

---

## What This Epic Delivers

- ✅ Email/password authentication via Firebase Auth
- ✅ Sign up flow with email validation
- ✅ Login flow with error handling
- ✅ Password reset via email
- ✅ Persistent sessions (auto-login after app restart)
- ✅ Secure token storage in iOS Keychain
- ✅ User profile creation in Firestore
- ✅ Profile picture upload to Firebase Storage
- ✅ Display name management
- ✅ Logout functionality with local data cleanup

---

## User Stories

### Story 1.1: User Sign Up with Email/Password
**As a content creator, I can sign up with email/password so I can create an account and access MessageAI.**

**Acceptance Criteria:**
- [ ] Sign up screen with email, password, confirm password, display name fields
- [ ] Email validation (valid format, not already registered)
- [ ] Password strength requirements (8+ characters)
- [ ] Passwords must match (password == confirm password)
- [ ] Display name required (1-50 characters)
- [ ] Loading indicator during sign up
- [ ] Error messages for invalid input or Firebase errors
- [ ] Success: Navigate to main app (conversation list)
- [ ] User profile created in Firestore `/users/{userId}`
- [ ] UserEntity created in SwiftData

**Technical Tasks:**
1. Create `SignUpView.swift` in `Features/Auth/Views/`
   - Email TextField with keyboard type `.emailAddress`
   - Password SecureField
   - Confirm Password SecureField
   - Display Name TextField
   - Sign Up button
   - Link to Login screen ("Already have an account?")
2. Create `AuthViewModel.swift` in `Features/Auth/ViewModels/`
   - `@Published var email: String`
   - `@Published var password: String`
   - `@Published var confirmPassword: String`
   - `@Published var displayName: String`
   - `@Published var isLoading: Bool`
   - `@Published var errorMessage: String?`
   - `func signUp() async throws`
   - Email validation logic
   - Password strength validation
3. Create `AuthService.swift` in `Features/Auth/Services/`
   - `func createUser(email: String, password: String, displayName: String) async throws -> User`
   - Firebase Auth integration: `Auth.auth().createUser(withEmail:password:)`
   - Create Firestore user document: `/users/{userId}`
   - Create local SwiftData UserEntity
4. Create `User` model in `Features/Auth/Models/`
   - Conforms to `Sendable` for Swift 6 concurrency
   - Properties: `id`, `email`, `displayName`, `photoURL`, `createdAt`
5. Add input validation:
   - Email regex validation
   - Password length check (min 8 characters)
   - Display name length check (1-50 characters)
6. Error handling:
   - Firebase errors (email already in use, weak password, etc.)
   - Network errors
   - Validation errors
7. Testing:
   - Unit tests for AuthViewModel validation logic
   - Integration test: Sign up flow end-to-end with Firebase Emulator

**Firebase Integration:**
```swift
// In AuthService.swift
func createUser(email: String, password: String, displayName: String) async throws -> User {
    // Create Firebase Auth user
    let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
    let uid = authResult.user.uid

    // Create Firestore user document
    let userData: [String: Any] = [
        "email": email,
        "displayName": displayName,
        "photoURL": "",
        "createdAt": FieldValue.serverTimestamp()
    ]
    try await Firestore.firestore().collection("users").document(uid).setData(userData)

    // Create local SwiftData UserEntity
    let user = User(id: uid, email: email, displayName: displayName, photoURL: nil, createdAt: Date())
    return user
}
```

**UI Flow:**
```
[Sign Up Screen]
  ↓
[Enter Email, Password, Display Name]
  ↓
[Tap "Sign Up" Button]
  ↓
[Validate Input] → [Show Errors if Invalid]
  ↓
[Call AuthViewModel.signUp()]
  ↓
[AuthService.createUser()] → [Create Firebase Auth User]
  ↓
[Create Firestore User Document]
  ↓
[Create SwiftData UserEntity]
  ↓
[Store Auth Token in Keychain]
  ↓
[Navigate to Conversation List]
```

**Time Estimate:** 1-1.5 hours

---

### Story 1.2: User Login with Email/Password
**As a content creator, I can log in with my email/password so I can access my account and messages.**

**Acceptance Criteria:**
- [ ] Login screen with email and password fields
- [ ] "Forgot Password?" link
- [ ] Loading indicator during login
- [ ] Error messages for invalid credentials or network errors
- [ ] Success: Navigate to main app (conversation list)
- [ ] Auth token stored securely in Keychain
- [ ] User data synced from Firestore to SwiftData

**Technical Tasks:**
1. Create `LoginView.swift` in `Features/Auth/Views/`
   - Email TextField
   - Password SecureField
   - Login button
   - "Forgot Password?" button
   - Link to Sign Up screen ("Don't have an account?")
2. Add to `AuthViewModel.swift`:
   - `func login() async throws`
   - Error handling for login failures
3. Add to `AuthService.swift`:
   - `func signIn(email: String, password: String) async throws -> User`
   - Firebase Auth integration: `Auth.auth().signIn(withEmail:password:)`
   - Fetch user data from Firestore
   - Update local SwiftData UserEntity
4. Create `KeychainService.swift` in `Core/Services/`
   - `func save(token: String) throws`
   - `func retrieve() -> String?`
   - `func delete() throws`
   - Secure Keychain storage for Firebase auth token
5. Error handling:
   - Invalid credentials (wrong email/password)
   - User not found
   - Network errors
6. Testing:
   - Unit tests for login validation
   - Integration test: Login flow with Firebase Emulator

**Keychain Integration:**
```swift
// In KeychainService.swift
import Security

class KeychainService {
    private let service = "com.messageai.app"
    private let account = "firebase_auth_token"

    func save(token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary) // Delete old token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    func retrieve() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed
        }
    }
}

enum KeychainError: Error {
    case saveFailed
    case deleteFailed
}
```

**Time Estimate:** 45 mins - 1 hour

---

### Story 1.3: Persistent Login (Auto-Login on App Launch)
**As a content creator, I stay logged in after closing the app so I don't have to log in every time.**

**Acceptance Criteria:**
- [ ] On app launch, check for valid auth token in Keychain
- [ ] If valid token exists, auto-login and navigate to conversation list
- [ ] If no token or invalid token, show login screen
- [ ] Silent refresh of Firebase auth token if needed
- [ ] User data synced from Firestore on auto-login

**Technical Tasks:**
1. Create `RootView.swift` in `App/`
   - Initial loading state
   - Check for auth token on appear
   - Conditionally show LoginView or ConversationListView
2. Add to `AuthViewModel.swift`:
   - `@Published var isAuthenticated: Bool`
   - `func checkAuthStatus() async`
   - Auto-login logic
3. Add to `AuthService.swift`:
   - `func autoLogin() async throws -> User?`
   - Check Keychain for token
   - Verify token with Firebase: `Auth.auth().currentUser`
   - Fetch user data from Firestore
4. Update `MessageAIApp.swift`:
   - Use `RootView` as initial view instead of hardcoded ContentView
5. Testing:
   - Test app launch with valid token (should auto-login)
   - Test app launch with no token (should show login)
   - Test app launch with expired token (should show login)

**RootView Implementation:**
```swift
import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoading {
                ProgressView("Loading...")
            } else if authViewModel.isAuthenticated {
                ConversationListView()
            } else {
                LoginView()
            }
        }
        .task {
            await authViewModel.checkAuthStatus()
        }
    }
}
```

**Time Estimate:** 30 mins

---

### Story 1.4: Password Reset Flow
**As a content creator, I can reset my password via email if I forget it.**

**Acceptance Criteria:**
- [ ] "Forgot Password?" button on login screen
- [ ] Password reset screen with email input
- [ ] Send reset email button
- [ ] Loading indicator during email send
- [ ] Success message: "Reset email sent, check your inbox"
- [ ] Error handling for invalid email or network errors
- [ ] Navigate back to login after success

**Technical Tasks:**
1. Create `ForgotPasswordView.swift` in `Features/Auth/Views/`
   - Email TextField
   - Send Reset Email button
   - Back to Login button
2. Add to `AuthViewModel.swift`:
   - `func sendPasswordReset(email: String) async throws`
3. Add to `AuthService.swift`:
   - `func resetPassword(email: String) async throws`
   - Firebase Auth: `Auth.auth().sendPasswordReset(withEmail:)`
4. Error handling:
   - Invalid email format
   - User not found
   - Network errors
5. Testing:
   - Unit test for email validation
   - Manual test: Receive reset email in inbox

**Time Estimate:** 30 mins

---

### Story 1.5: User Profile Management (Display Name & Photo)
**As a content creator, I can set my display name and profile picture so others can identify me.**

**Acceptance Criteria:**
- [ ] Profile settings screen accessible from main app
- [ ] Display name field (editable)
- [ ] Profile picture (tap to change)
- [ ] Image picker for selecting profile photo
- [ ] Upload progress indicator
- [ ] Save button
- [ ] Success message after save
- [ ] Profile updates sync to Firestore
- [ ] Profile updates sync to local SwiftData UserEntity

**Technical Tasks:**
1. Create `ProfileView.swift` in `Features/Settings/Views/`
   - AsyncImage showing current profile picture
   - Display name TextField
   - "Change Photo" button
   - Save button
2. Create `ProfileViewModel.swift` in `Features/Settings/ViewModels/`
   - `@Published var displayName: String`
   - `@Published var photoURL: URL?`
   - `@Published var isUploading: Bool`
   - `func updateProfile() async throws`
   - `func uploadProfileImage(_ image: UIImage) async throws -> URL`
3. Add to `AuthService.swift`:
   - `func updateUserProfile(displayName: String?, photoURL: URL?) async throws`
   - Update Firestore user document
   - Update local SwiftData UserEntity
4. Create `StorageService.swift` in `Core/Services/`
   - `func uploadImage(_ image: UIImage, path: String) async throws -> URL`
   - Firebase Storage upload
   - Image compression before upload
5. Image picker integration:
   - Use `PHPickerViewController` wrapped in SwiftUI
   - Or use `PhotosPicker` (iOS 16+)
6. Testing:
   - Unit tests for profile update logic
   - Integration test: Upload image to Firebase Storage

**Firebase Storage Upload:**
```swift
// In StorageService.swift
import FirebaseStorage
import UIKit

class StorageService {
    private let storage = Storage.storage()

    func uploadImage(_ image: UIImage, path: String) async throws -> URL {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.imageCompressionFailed
        }

        // Create storage reference
        let storageRef = storage.reference().child(path)

        // Upload
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }
}

enum StorageError: Error {
    case imageCompressionFailed
}
```

**Time Estimate:** 1 hour

---

### Story 1.6: Logout Functionality
**As a content creator, I can log out of my account so I can switch accounts or secure my device.**

**Acceptance Criteria:**
- [ ] Logout button in settings/profile screen
- [ ] Confirmation dialog: "Are you sure you want to log out?"
- [ ] On confirm: Sign out from Firebase Auth
- [ ] Clear auth token from Keychain
- [ ] Clear local SwiftData cache (optional, can keep for offline access)
- [ ] Navigate back to login screen

**Technical Tasks:**
1. Add logout button to `ProfileView.swift`
2. Add to `AuthViewModel.swift`:
   - `func logout() async throws`
   - Confirmation logic
3. Add to `AuthService.swift`:
   - `func signOut() async throws`
   - Firebase Auth: `try Auth.auth().signOut()`
   - Keychain: `keychainService.delete()`
   - Optionally clear SwiftData
4. Navigation logic:
   - Update `isAuthenticated` state to trigger RootView re-render
5. Testing:
   - Test logout flow end-to-end
   - Verify token removed from Keychain
   - Verify user redirected to login screen

**Time Estimate:** 15-20 mins

---

## Technical Dependencies

### Required Services:
- ✅ Firebase Auth (configured in Epic 0)
- ✅ Firebase Firestore (for user profiles)
- ✅ Firebase Storage (for profile pictures)
- ✅ iOS Keychain (for secure token storage)
- ✅ SwiftData UserEntity (from Epic 0)

### Required Libraries:
- ✅ Firebase iOS SDK (FirebaseAuth, FirebaseFirestore, FirebaseStorage)
- ✅ SwiftUI (for all UI)
- ✅ SwiftData (for local user persistence)

---

## Data Models

### User Model (Swift)
```swift
// Features/Auth/Models/User.swift
import Foundation

struct User: Sendable, Codable, Identifiable {
    let id: String  // Firebase Auth UID
    var email: String
    var displayName: String
    var photoURL: String?
    let createdAt: Date

    init(id: String, email: String, displayName: String, photoURL: String? = nil, createdAt: Date) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
    }
}
```

### Firestore Schema
```
/users/{userId}
  - email: string
  - displayName: string
  - photoURL: string (Firebase Storage URL)
  - createdAt: timestamp
```

### SwiftData UserEntity
See `docs/swiftdata-implementation-guide.md` Section 3 for complete UserEntity definition.

---

## Architecture Pattern: MVVM

### Flow:
```
[View (SwiftUI)]
    ↓ User Action (e.g., tap Login)
[@MainActor ViewModel]
    ↓ async function call
[AuthService]
    ↓ Firebase SDK calls
[Firebase Backend]
    ↓ Response
[AuthService] → ViewModel (@Published update) → View (auto re-render)
```

### Example:
```swift
// LoginView.swift
Button("Login") {
    Task {
        await viewModel.login()
    }
}

// AuthViewModel.swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService()

    func login() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await authService.signIn(email: email, password: password)
            // Success - RootView will auto-navigate
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## Testing Strategy

### Unit Tests:
- [ ] Email validation logic
- [ ] Password strength validation
- [ ] AuthViewModel state transitions
- [ ] KeychainService save/retrieve/delete

### Integration Tests:
- [ ] Sign up flow with Firebase Emulator
- [ ] Login flow with Firebase Emulator
- [ ] Auto-login on app launch
- [ ] Profile update with Firestore

### Manual Testing:
- [ ] Sign up with real email (receive verification email if enabled)
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (should show error)
- [ ] Forgot password (receive reset email)
- [ ] Auto-login after app restart
- [ ] Logout and verify redirect to login
- [ ] Upload profile picture

---

## Error Handling

### Common Firebase Auth Errors:
```swift
enum AuthError: Error, LocalizedError {
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case wrongPassword
    case userNotFound
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "This email is already registered. Please log in."
        case .weakPassword:
            return "Password must be at least 8 characters long."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

### Error Mapping:
```swift
// In AuthService.swift
func mapFirebaseError(_ error: Error) -> AuthError {
    let nsError = error as NSError

    switch nsError.code {
    case AuthErrorCode.invalidEmail.rawValue:
        return .invalidEmail
    case AuthErrorCode.emailAlreadyInUse.rawValue:
        return .emailAlreadyInUse
    case AuthErrorCode.weakPassword.rawValue:
        return .weakPassword
    case AuthErrorCode.wrongPassword.rawValue:
        return .wrongPassword
    case AuthErrorCode.userNotFound.rawValue:
        return .userNotFound
    case AuthErrorCode.networkError.rawValue:
        return .networkError
    default:
        return .unknown(error)
    }
}
```

---

## UI/UX Specifications

See `docs/ux-design.md` Section 4.1 for complete onboarding and authentication UI specifications.

### Key UI Elements:
- **Sign Up Screen**: Email, Password, Confirm Password, Display Name, Sign Up button
- **Login Screen**: Email, Password, Login button, Forgot Password link
- **Forgot Password Screen**: Email, Send Reset Email button
- **Profile Screen**: Profile picture (tap to change), Display Name field, Save button

### Design System:
- Use iOS native `.textFieldStyle(.roundedBorder)` for inputs
- Use `.buttonStyle(.borderedProminent)` for primary actions
- Show `.progressView()` during async operations
- Use `.alert()` for error messages

---

## Success Criteria

**Epic 1 is complete when:**
- ✅ User can sign up with email/password
- ✅ User can log in with email/password
- ✅ User stays logged in after app restart (Keychain persistence)
- ✅ User can reset password via email
- ✅ User can set display name and profile picture
- ✅ User can log out successfully
- ✅ Auth token stored securely in Keychain
- ✅ User profile synced to Firestore
- ✅ User data cached in SwiftData
- ✅ All error states handled gracefully
- ✅ Unit and integration tests pass

---

## Time Estimates

| Story | Estimated Time |
|-------|---------------|
| 1.1 User Sign Up | 1-1.5 hours |
| 1.2 User Login | 45 mins - 1 hour |
| 1.3 Persistent Login | 30 mins |
| 1.4 Password Reset | 30 mins |
| 1.5 Profile Management | 1 hour |
| 1.6 Logout | 15-20 mins |
| **Total** | **2-3 hours** |

---

## Implementation Order

**Recommended sequence:**
1. Story 1.1 (Sign Up) - Foundation for auth
2. Story 1.2 (Login) - Core login flow
3. Story 1.3 (Persistent Login) - Keychain integration
4. Story 1.6 (Logout) - Complete auth cycle
5. Story 1.4 (Password Reset) - Forgot password flow
6. Story 1.5 (Profile Management) - Profile pictures (can be last)

---

## References

- **PRD Section 8.1.1**: Authentication specifications
- **PRD Section 10.1**: Firebase Firestore schema (users collection)
- **SwiftData Implementation Guide**: Section 3 (UserEntity)
- **UX Design Doc**: Section 4.1 (Onboarding & Authentication UI)
- **Architecture Doc**: Section 8 (Security - Keychain, Firebase Auth)

---

## Notes for Development Team

### Critical Security Considerations:
- **Never log passwords** - Use `SecureField` in SwiftUI
- **Store auth tokens in Keychain only** - Never UserDefaults or plain files
- **Use HTTPS only** - Firebase SDK enforces this by default
- **Validate all inputs** - Email format, password strength

### Tips for Success:
- Test with Firebase Emulators during development (faster, no costs)
- Use real Firebase for final testing (to test email delivery)
- Handle all Firebase Auth error codes explicitly
- Use Swift 6 async/await (no completion handlers)

### Potential Blockers:
- **Firebase email verification**: Can enable later, not required for MVP
- **Profile picture upload time**: Compress images before upload (0.7 quality)
- **Keychain access**: Test on real device if simulator has issues

---

**Epic Status:** Ready for implementation
**Blockers:** Epic 0 must be complete
**Risk Level:** Low (well-documented Firebase Auth patterns)
