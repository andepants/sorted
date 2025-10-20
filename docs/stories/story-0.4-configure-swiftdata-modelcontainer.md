---
# Story 0.4: Configure SwiftData ModelContainer

id: STORY-0.4
title: "Configure SwiftData ModelContainer with Core @Model Entities"
epic: "Epic 0: Project Scaffolding & Development Environment Setup"
status: draft
priority: P0
estimate: 3
assigned_to: null
created_date: "2025-10-20"
sprint_day: 0

---

## Description

**As a** developer
**I need** SwiftData configured with all core @Model entities and ModelContainer
**So that** I can persist data locally with offline-first capabilities and sync with Firestore

This story implements the complete SwiftData persistence layer for Sorted, including all 5 core @Model entities (Message, Conversation, User, Attachment, FAQ) with full relationships, the ModelContainer configuration, and preview support for SwiftUI.

---

## Acceptance Criteria

**This story is complete when:**

- [ ] All 5 @Model entities defined (MessageEntity, ConversationEntity, UserEntity, AttachmentEntity, FAQEntity)
- [ ] All entity relationships properly configured with cascade delete rules
- [ ] ModelContainer configured in SortedApp.swift with all entities
- [ ] Schema includes all required properties and relationships from SwiftData Implementation Guide
- [ ] Preview container available for SwiftUI previews with sample data
- [ ] App builds and initializes SwiftData without errors
- [ ] SwiftData store file created on simulator (verified in console logs)

---

## Technical Tasks

**Implementation steps:**

1. **Create Core/Models Directory Structure**
   - Create folder: `Sorted/Core/Models/`
   - This will house all SwiftData @Model entities

2. **Create MessageEntity.swift**
   - Copy complete implementation from SwiftData Implementation Guide Section 1.1
   - Include all properties:
     - Core: id, conversationID, senderID, text, createdAt, updatedAt
     - Status: status, syncStatus, retryCount, lastSyncAttempt, syncError
     - Read receipts: readBy array
     - AI metadata: category, categoryConfidence, sentiment, opportunityScore, faqMatchID, etc.
     - Relationships: conversation (inverse), attachments (cascade)
   - Include helper methods: markAsSynced(), markAsFailed(), shouldRetry, isPendingSync

3. **Create ConversationEntity.swift**
   - Copy complete implementation from SwiftData Implementation Guide Section 1.2
   - Include all properties:
     - Core: id, participantIDs, displayName, avatarURL, isGroup
     - State: isPinned, isMuted, isArchived, unreadCount
     - Last message: lastMessageText, lastMessageAt, lastMessageSenderID
     - AI: supermemoryConversationID
     - Relationships: messages (cascade delete)
   - Include helper methods: updateWithMessage(), incrementUnreadCount(), markAsRead()

4. **Create UserEntity.swift**
   - Copy complete implementation from SwiftData Implementation Guide Section 1.3
   - Include all properties:
     - Core: id, email, displayName, photoURL
     - AI preferences: enableCategorization, enableSmartReply, enableFAQ, etc.
     - Relationships: faqs (cascade delete)
   - Include helper methods: updateProfile(), setAIFeature()

5. **Create AttachmentEntity.swift**
   - Copy complete implementation from SwiftData Implementation Guide Section 1.4
   - Include all properties:
     - Core: id, type, url, localURL, thumbnailURL
     - File metadata: fileSize, mimeType, fileName
     - Upload tracking: uploadStatus, uploadProgress, uploadError
     - Relationships: message (inverse)
   - Include helper methods: updateUploadProgress(), markAsUploaded(), markAsFailed()

6. **Create FAQEntity.swift**
   - Copy complete implementation from SwiftData Implementation Guide Section 1.5
   - Include all properties:
     - Core: id, category, questionPattern, answer
     - Usage tracking: usageCount, lastUsedAt, isEnabled
     - Relationships: user (inverse)
   - Include helper methods: recordUsage(), update()

7. **Configure ModelContainer in SortedApp.swift**
   - Add SwiftData import
   - Create modelContainer property
   - Initialize in init() with all 5 entities
   - Configure with proper Schema and ModelConfiguration
   - Inject into view hierarchy with .modelContainer() modifier
   - Add error handling with fatalError() for initialization failures

8. **Create PreviewContainer for SwiftUI Previews**
   - Create file: `Sorted/Core/Utilities/PreviewContainer.swift`
   - Copy implementation from SwiftData Implementation Guide Section 2.2
   - Configure in-memory ModelContainer for previews
   - Insert sample data (user, conversation, messages)

---

## Technical Specifications

### Files to Create

```
Sorted/Core/Models/
├── MessageEntity.swift (create)
├── ConversationEntity.swift (create)
├── UserEntity.swift (create)
├── AttachmentEntity.swift (create)
└── FAQEntity.swift (create)

Sorted/Core/Utilities/
└── PreviewContainer.swift (create)

Sorted/
└── SortedApp.swift (modify - add ModelContainer)
```

### ModelContainer Configuration

**SortedApp.swift (complete implementation):**
```swift
import SwiftUI
import SwiftData
import Firebase

@main
struct SortedApp: App {
    let modelContainer: ModelContainer

    init() {
        // Initialize Firebase (from Story 0.3)
        FirebaseApp.configure()

        // Initialize SwiftData ModelContainer
        do {
            let schema = Schema([
                MessageEntity.self,
                ConversationEntity.self,
                UserEntity.self,
                AttachmentEntity.self,
                FAQEntity.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

### Entity Relationships

**Relationship Graph:**
```
UserEntity
  ↓ (cascade delete)
  FAQEntity

ConversationEntity
  ↓ (cascade delete)
  MessageEntity
    ↓ (cascade delete)
    AttachmentEntity
```

**Inverse Relationships:**
- MessageEntity.conversation ↔ ConversationEntity.messages
- AttachmentEntity.message ↔ MessageEntity.attachments
- FAQEntity.user ↔ UserEntity.faqs

### Dependencies

**Required:**
- STORY-0.1 (Xcode Project) complete
- STORY-0.2 (SPM Dependencies) complete
- STORY-0.3 (Firebase Backend) complete

**Blocks:**
- All Day 1 stories (chat, authentication, etc.)

**External:**
- SwiftData Implementation Guide available

---

## Testing & Validation

### Test Procedure

1. **Build Test**
   - Clean build folder (⇧⌘K)
   - Build project (⌘B)
   - Verify: No SwiftData errors
   - Verify: All @Model entities compile correctly

2. **Initialization Test**
   - Run app on simulator (⌘R)
   - Check console for initialization log:
     ```
     ✅ SwiftData ModelContainer initialized successfully
        Entities: MessageEntity, ConversationEntity, UserEntity, AttachmentEntity, FAQEntity
     ```
   - Verify: No fatalError() triggered

3. **Store File Verification**
   - After running app, check for SwiftData store file
   - Location: `~/Library/Developer/CoreSimulator/Devices/[UUID]/data/Containers/Data/Application/[UUID]/Library/Application Support/default.store`
   - Verify: File exists (indicates successful persistence)

4. **Preview Test**
   - Update ContentView.swift to use PreviewContainer:
     ```swift
     #Preview {
         ContentView()
             .modelContainer(PreviewContainer.shared)
     }
     ```
   - Open preview in Xcode
   - Verify: Preview renders without SwiftData errors

5. **Entity Relationship Test**
   - Add test code in SortedApp.swift init():
     ```swift
     // Test entity creation
     let context = modelContainer.mainContext
     let testUser = UserEntity(
         id: "test-user",
         email: "test@example.com",
         displayName: "Test User"
     )
     context.insert(testUser)
     try? context.save()
     print("✅ Test entity created and saved")
     ```
   - Run app and verify entity saves successfully

### Success Criteria

- [ ] All 5 @Model entities compile without errors
- [ ] ModelContainer initializes successfully
- [ ] Console logs show successful SwiftData initialization
- [ ] SwiftData store file created on device/simulator
- [ ] Preview container works with sample data
- [ ] Test entity creation and save works
- [ ] No SwiftData-related crashes or errors

---

## References

**Architecture Docs:**
- [Technology Stack](../architecture/technology-stack.md#21-ios-technologies)
- [Data Architecture](../architecture/data-architecture.md)

**Implementation Guides:**
- [SwiftData Implementation Guide](../swiftdata-implementation-guide.md) (PRIMARY REFERENCE)
  - Section 1: @Model Entities (1.1-1.5)
  - Section 2: ModelContainer Setup (2.1-2.2)

**Epic:**
- [Epic 0: Project Scaffolding](../epics/epic-0-project-scaffolding.md#story-04-configure-swiftdata-modelcontainer)

**Related Stories:**
- STORY-0.1: Initialize Xcode Project (prerequisite)
- STORY-0.2: Install SPM Dependencies (prerequisite)
- STORY-0.3: Set Up Firebase Backend (prerequisite)
- STORY-0.5: Create Project File Structure (parallel)

---

## Notes & Considerations

### Implementation Notes

- **CRITICAL**: Copy entity implementations EXACTLY from SwiftData Implementation Guide
  - Do not modify property names or types
  - All properties are required for future stories
- Use `@Attribute(.unique)` for id properties to prevent duplicates
- All timestamps should use `Date()` type (not String or Int)
- Enums must conform to `Codable` for SwiftData persistence
- ModelContainer MUST be initialized in `init()`, not in `body`

### Edge Cases

- **Initialization Failure**: If ModelContainer fails to initialize, app will crash with fatalError()
  - This is intentional - app cannot function without SwiftData
  - Check console for specific error message
- **Schema Migration**: First-time setup has no migration issues
  - Future schema changes will require migration logic (out of scope for Story 0.4)
- **Relationship Cycles**: Ensure inverse relationships are properly configured to avoid retain cycles

### Performance Considerations

- SwiftData initialization is fast (~50ms) - minimal impact on app launch
- First-time schema creation may take ~200ms
- In-memory preview container has no disk I/O overhead
- Cascade deletes are efficient (handled by SwiftData automatically)

### Security Considerations

- SwiftData store is encrypted by iOS when device is locked (no additional encryption needed)
- Store file is in app sandbox - not accessible by other apps
- User IDs should match Firebase Auth UIDs for consistency
- Do NOT store sensitive data (passwords, API keys) in SwiftData - use Keychain instead

---

## Metadata

**Created by:** SM Agent (Bob)
**Created date:** 2025-10-20
**Last updated:** 2025-10-20
**Sprint:** Day 0 of 7-day sprint
**Epic:** Epic 0: Project Scaffolding
**Story points:** 3
**Priority:** P0 (Blocker)

---

## Story Lifecycle

- [x] **Draft** - Story created, needs review
- [ ] **Ready** - Story reviewed and ready for development
- [ ] **In Progress** - Developer working on story
- [ ] **Blocked** - Story blocked by dependency or issue
- [ ] **Review** - Implementation complete, needs QA review
- [ ] **Done** - Story complete and validated

**Current Status:** Draft
