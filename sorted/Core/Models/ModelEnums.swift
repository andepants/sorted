/// ModelEnums.swift
///
/// Shared enums used across SwiftData models.
/// Centralizing enums prevents compilation order issues during schema creation.
///
/// Created: 2025-10-21

import Foundation

// MARK: - Message Status

/// Message delivery status
enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
}

// Story 2.3 Note:
// MessageStatus aligned with RTDB sync requirements:
// - .sending: Local optimistic UI (before RTDB sync)
// - .sent: RTDB synced successfully
// - .delivered: Recipient device received (FCM confirmation)
// - .read: Recipient opened and viewed message

// MARK: - Sync Status

/// Sync status for offline queue
enum SyncStatus: String, Codable {
    case pending
    case synced
    case failed
}

// MARK: - Message Categorization

/// AI-generated message category
enum MessageCategory: String, Codable {
    case fan
    case business
    case spam
    case urgent
}

/// Message sentiment analysis result
enum MessageSentiment: String, Codable {
    case positive
    case negative
    case urgent
    case neutral
}

/// Sentiment intensity level
enum SentimentIntensity: String, Codable {
    case low
    case medium
    case high
}

// MARK: - Attachments

/// Attachment type
enum AttachmentType: String, Codable {
    case image
    case video
    case audio
    case document
}

/// Attachment upload status
enum UploadStatus: String, Codable {
    case pending
    case uploading
    case completed
    case failed
}

// MARK: - FAQ

/// FAQ category
enum FAQCategory: String, Codable, CaseIterable {
    case equipment = "Equipment"
    case software = "Software"
    case business = "Business"
    case personal = "Personal"
    case career = "Career"
    case other = "Other"
}

// MARK: - User Preferences

/// AI feature toggles (not stored in SwiftData, used for UI)
enum AIFeature {
    case categorization
    case smartReply
    case faq
    case sentiment
    case opportunityScoring
}
