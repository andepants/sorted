/// AuthError.swift
/// Authentication error types with user-friendly messages
/// [Source: Epic 1, Story 1.1]

import Foundation

/// Errors that can occur during authentication operations
enum AuthError: Error, LocalizedError {
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case wrongPassword
    case userNotFound
    case networkError
    case invalidDisplayName
    case displayNameTaken
    case displayNameTooShort
    case displayNameTooLong
    case displayNameInvalidCharacters
    case unknown(Error)

    /// User-friendly error description
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
        case .invalidDisplayName:
            return "Invalid username format."
        case .displayNameTaken:
            return "This username is already taken. Please choose another."
        case .displayNameTooShort:
            return "Username must be at least 3 characters long."
        case .displayNameTooLong:
            return "Username must be 30 characters or less."
        case .displayNameInvalidCharacters:
            return "Username can only contain letters, numbers, periods, and underscores."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
