/// MessageValidator.swift
///
/// Validates message content before sending to RTDB.
/// Checks for empty messages, max length (10,000 chars), and UTF-8 encoding.
///
/// Created: 2025-10-21 (Story 2.3)

import Foundation

/// Validates message content before sending
struct MessageValidator {
    // MARK: - Constants

    static let maxLength = 10_000
    static let minLength = 1

    // MARK: - Validation Error

    enum ValidationError: LocalizedError {
        case empty
        case tooLong
        case invalidCharacters

        var errorDescription: String? {
            switch self {
            case .empty:
                return "Message cannot be empty"
            case .tooLong:
                return "Message is too long (max 10,000 characters)"
            case .invalidCharacters:
                return "Message contains invalid characters"
            }
        }
    }

    // MARK: - Validation

    /// Validates message text
    /// - Parameter text: The message text to validate
    /// - Throws: ValidationError if validation fails
    static func validate(_ text: String) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= minLength else {
            throw ValidationError.empty
        }

        guard trimmed.count <= maxLength else {
            throw ValidationError.tooLong
        }

        // UTF-8 encoding validation (optional)
        guard trimmed.data(using: .utf8) != nil else {
            throw ValidationError.invalidCharacters
        }
    }
}
