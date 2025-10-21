/// AuthViewModel.swift
/// View model for authentication screens (SignUp, Login, ForgotPassword)
/// [Source: Epic 1, Stories 1.1, 1.2, 1.4]

import Combine
import Foundation
import SwiftUI

/// Manages authentication state and operations for auth-related views
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isAuthenticated: Bool = false

    /// Current authenticated user (session state, synced with Firestore and local data)
    @Published var currentUser: User?

    // DisplayName availability checking
    @Published var isCheckingAvailability: Bool = false
    @Published var displayNameAvailable: Bool = false
    @Published var displayNameError: String = ""

    // Password validation
    @Published var passwordError: String = ""
    @Published var confirmPasswordError: String = ""

    // Login-specific
    @Published var loginAttemptCount: Int = 0

    // MARK: - Dependencies

    private let authService: AuthService
    private let displayNameService = DisplayNameService()

    /// Initializes the view model with authentication service
    /// - Parameter authService: Auth service instance (injectable for testing)
    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    // MARK: - Sign Up (Story 1.1)

    /// Signs up a new user with email, password, and display name
    /// - Throws: AuthError if validation or signup fails
    func signUp() async {
        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        do {
            // Validate inputs
            try validateSignUpInputs()

            // Create user via AuthService
            let user = try await authService.createUser(
                email: email,
                password: password,
                displayName: displayName
            )

            // Set current user (session state)
            currentUser = user

            // Success - navigate handled by RootView observing isAuthenticated
            isAuthenticated = true

            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    /// Validates sign up form inputs
    /// - Throws: AuthError for invalid inputs
    private func validateSignUpInputs() throws {
        // Email validation
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        // Password validation
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }

        // Password match validation
        guard password == confirmPassword else {
            throw AuthError.unknown(NSError(
                domain: "com.sorted.app",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Passwords do not match"]
            ))
        }

        // DisplayName validation (format)
        guard displayName.count >= 3 else {
            throw AuthError.displayNameTooShort
        }
        guard displayName.count <= 30 else {
            throw AuthError.displayNameTooLong
        }
    }

    /// Checks if display name is available (debounced real-time check)
    /// - Parameter name: Display name to check
    func checkDisplayNameAvailability(_ name: String) async {
        // Reset state
        displayNameAvailable = false
        displayNameError = ""

        // Validate format first
        guard name.count >= 3 && name.count <= 30 else {
            displayNameError = "Username must be 3-30 characters"
            return
        }

        guard name.range(of: "^[a-zA-Z0-9._]+$", options: .regularExpression) != nil else {
            displayNameError = "Only letters, numbers, periods, and underscores allowed"
            return
        }

        guard !name.hasPrefix(".") && !name.hasSuffix(".") else {
            displayNameError = "Cannot start or end with a period"
            return
        }

        guard !name.contains("..") else {
            displayNameError = "No consecutive periods allowed"
            return
        }

        // Check availability in Firestore
        isCheckingAvailability = true
        defer { isCheckingAvailability = false }

        do {
            let isAvailable = try await displayNameService.checkAvailability(name)
            if isAvailable {
                displayNameAvailable = true
            } else {
                displayNameError = "Username already taken"
            }
        } catch {
            displayNameError = "Error checking availability"
        }
    }

    /// Validates password requirements and sets error message
    /// - Parameter password: Password to validate
    func validatePassword(_ password: String) {
        guard !password.isEmpty else {
            passwordError = ""
            return
        }

        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else {
            passwordError = ""
        }
    }

    /// Validates password confirmation match
    /// - Parameter confirmPassword: Confirm password to validate
    func validateConfirmPassword(_ confirmPassword: String) {
        guard !confirmPassword.isEmpty else {
            confirmPasswordError = ""
            return
        }

        if confirmPassword != password {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = ""
        }
    }

    /// Validates email format using regex
    /// - Parameter email: Email address to validate
    /// - Returns: True if valid email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Computed property for form validation
    var isSignUpFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 8 &&
        passwordError.isEmpty &&
        password == confirmPassword &&
        confirmPasswordError.isEmpty &&
        displayNameAvailable &&
        displayNameError.isEmpty
    }

    // MARK: - Login (Story 1.2)

    /// Logs in user with email and password
    func login() async {
        isLoading = true
        errorMessage = nil
        showError = false
        defer { isLoading = false }

        do {
            // Sign in via AuthService
            let user = try await authService.signIn(email: email, password: password)

            // Set current user (session state)
            currentUser = user

            // Success
            isAuthenticated = true

            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            showError = true
            loginAttemptCount += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            showError = true
            loginAttemptCount += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    // MARK: - Auto-Login (Story 1.3)

    /// Checks authentication status on app launch
    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let user = try await authService.autoLogin() {
                // Set current user (session state)
                currentUser = user
                isAuthenticated = true
            } else {
                currentUser = nil
                isAuthenticated = false
            }
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Logout (Story 1.6)

    /// Logs out the current user
    func logout() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.signOut()

            // Clear current user
            currentUser = nil
            isAuthenticated = false

            // Reset form fields
            email = ""
            password = ""
            confirmPassword = ""
            displayName = ""
            displayNameAvailable = false
            displayNameError = ""
        } catch {
            errorMessage = "Logout failed. Please try again."
            showError = true
        }
    }
}
