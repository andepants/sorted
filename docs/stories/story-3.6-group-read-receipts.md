---
# Story 3.6: Group Read Receipts
# Epic 3: Group Chat
# Status: Draft

id: STORY-3.6
title: "Show Read Receipts for Group Messages"
epic: "Epic 3: Group Chat"
status: draft
priority: P1
estimate: 3  # Story points (45 minutes)
assigned_to: null
created_date: "2025-10-21"
sprint_day: null

---

## Description

**As a** group message sender
**I need** to see who read my messages in a group
**So that** I know which participants have seen my message

This story implements read receipts for group messages:
- Tap message → show read receipt sheet
- Lists all participants with read status ("Read" or "Delivered")
- Shows read timestamp for readers
- Only available for user's own sent messages
- Updates in real-time as participants read
- Synced via RTDB `/messages/{conversationID}/{messageID}/readBy/`

---

## Acceptance Criteria

**This story is complete when:**

- [ ] Tap message in group shows read receipt sheet (own messages only)
- [ ] Sheet lists all participants with read status
- [ ] Shows "Read" with timestamp for readers
- [ ] Shows "Delivered" for non-readers
- [ ] Only available for user's own sent messages (not others')
- [ ] Updates in real-time as participants read message
- [ ] Read receipts stored in RTDB: `/messages/{conversationID}/{messageID}/readBy/{userID}: timestamp`
- [ ] Tapping other users' messages does not show read receipts
- [ ] System messages don't have read receipts

---

## Technical Tasks

**Implementation steps:**

1. **Extend MessageEntity Model** [Source: epic-3-group-chat.md lines 1176-1184]
   - Add field: `readBy: [String: Date] = [:]` (userID → timestamp)
   - Store in SwiftData and sync to RTDB
   - Update MessageService to handle readBy updates

2. **Create ReadReceiptsView Sheet** [Source: epic-3-group-chat.md lines 1186-1252]
   - Create file: `sorted/Features/Chat/Views/ReadReceiptsView.swift`
   - Accept message and participants as parameters
   - Two sections: "Read" and "Delivered"
   - Read section: participants who read (show timestamp)
   - Delivered section: participants who haven't read
   - Sort by read timestamp (most recent first)

3. **Implement Participant Filtering** [Source: epic-3-group-chat.md lines 1244-1250]
   - Read participants: `message.readBy[$0.id] != nil`
   - Delivered participants: `message.readBy[$0.id] == nil && $0.id != message.senderID`
   - Exclude sender from delivered list

4. **Update MessageBubbleView for Tap Gesture** [Source: epic-3-group-chat.md lines 1254]
   - Add long press gesture on message bubbles
   - Only enable for user's own messages (check `senderID == currentUserID`)
   - Present ReadReceiptsView sheet
   - Pass message and participants

5. **Track Read Receipts in MessageService** [Source: epic-3-group-chat.md lines 1255-1256]
   - When user opens MessageThreadView, mark messages as read
   - Update RTDB: `/messages/{conversationID}/{messageID}/readBy/{userID}` = timestamp
   - Sync readBy map to SwiftData MessageEntity

6. **Add RTDB Listener for Read Receipt Updates** [Source: epic-3-group-chat.md lines 1256]
   - Listen to `/messages/{conversationID}/{messageID}/readBy/`
   - When other users read message, update local MessageEntity
   - Real-time updates reflected in ReadReceiptsView

7. **Handle Read Receipt Display Logic**
   - Show read receipt sheet only for own messages
   - Don't show for system messages
   - Don't show for 1:1 chats (use simple checkmark instead)

---

## Technical Specifications

### Files to Create

```
sorted/Features/Chat/Views/ReadReceiptsView.swift (create)
```

### Files to Modify

```
sorted/Core/Models/MessageEntity.swift (modify - add readBy field)
sorted/Core/Services/MessageService.swift (modify - track read receipts)
sorted/Features/Chat/Views/Components/MessageBubbleView.swift (modify - add tap gesture)
sorted/Features/Chat/Views/MessageThreadView.swift (modify - mark messages as read)
```

### RTDB Schema

**Message with Read Receipts:**
```
/messages/{conversationID}/{messageID}/
  ├── senderID: "user1"
  ├── text: "Hey everyone!"
  ├── serverTimestamp: 1704067200000
  ├── status: "sent"
  ├── isSystemMessage: false
  └── readBy/
      ├── user2: 1704067300000
      ├── user3: 1704067400000
      └── user4: 1704067500000
```

### Data Models

**MessageEntity (Extended):**
```swift
@Model
final class MessageEntity {
    // ... existing fields ...
    var isSystemMessage: Bool = false
    var readBy: [String: Date] = [:]  // userID -> readAt timestamp
}
```

### Code Examples

**ReadReceiptsView:**
```swift
struct ReadReceiptsView: View {
    let message: MessageEntity
    let participants: [UserEntity]

    var body: some View {
        NavigationStack {
            List {
                Section("Read") {
                    ForEach(readParticipants) { participant in
                        HStack {
                            AsyncImage(url: URL(string: participant.profilePictureURL ?? "")) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())

                            VStack(alignment: .leading) {
                                Text(participant.displayName)
                                    .font(.system(size: 16))

                                if let readAt = message.readBy[participant.id] {
                                    Text(readAt, style: .relative)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                if !unreadParticipants.isEmpty {
                    Section("Delivered") {
                        ForEach(unreadParticipants) { participant in
                            HStack {
                                AsyncImage(url: URL(string: participant.profilePictureURL ?? "")) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())

                                Text(participant.displayName)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Read By")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var readParticipants: [UserEntity] {
        participants.filter { message.readBy[$0.id] != nil }
            .sorted { (message.readBy[$0.id] ?? Date()) > (message.readBy[$1.id] ?? Date()) }
    }

    private var unreadParticipants: [UserEntity] {
        participants.filter { message.readBy[$0.id] == nil && $0.id != message.senderID }
    }
}
```

**MessageBubbleView Integration:**
```swift
struct MessageBubbleView: View {
    let message: MessageEntity
    let conversation: ConversationEntity

    @State private var showReadReceipts = false

    private var isOwnMessage: Bool {
        message.senderID == AuthService.shared.currentUserID
    }

    private var canShowReadReceipts: Bool {
        isOwnMessage && conversation.isGroup && !message.isSystemMessage
    }

    var body: some View {
        // Message bubble UI...
        .onLongPressGesture {
            if canShowReadReceipts {
                showReadReceipts = true
            }
        }
        .sheet(isPresented: $showReadReceipts) {
            ReadReceiptsView(message: message, participants: participants)
        }
    }
}
```

**Track Read Receipts (MessageService):**
```swift
extension MessageService {
    /// Mark message as read by current user
    func markAsRead(messageID: String, conversationID: String) async throws {
        let currentUserID = AuthService.shared.currentUserID ?? ""
        let timestamp = Date()

        // Update RTDB
        let messageRef = Database.database().reference()
            .child("messages")
            .child(conversationID)
            .child(messageID)
            .child("readBy")
            .child(currentUserID)

        try await messageRef.setValue(timestamp.timeIntervalSince1970 * 1000)

        // Update local SwiftData
        // ... fetch and update MessageEntity.readBy ...
    }
}
```

### Dependencies

**Required:**
- ✅ Story 3.1: Create Group Conversation (groups exist)
- ✅ MessageEntity model exists
- ✅ MessageService exists
- ✅ RTDB `/messages/` path configured

**Blocks:**
- None (independent feature)

**External:**
- RTDB configured with message read receipts
- Firestore `/users` collection for participant profiles

---

## Testing & Validation

### Test Procedure

1. **Show Read Receipts (Own Message):**
   - User A sends message in group (3 participants: A, B, C)
   - User A long-presses own message
   - ReadReceiptsView sheet appears
   - Shows "Delivered" section with User B and User C
   - User B reads message
   - User A's sheet updates to show User B in "Read" section with timestamp

2. **Cannot Show Read Receipts (Others' Messages):**
   - User B sends message in group
   - User A long-presses User B's message
   - No read receipt sheet appears (not own message)

3. **Read Section with Timestamps:**
   - User A sends message
   - User B reads immediately
   - User C reads 5 minutes later
   - User A opens read receipts
   - "Read" section shows:
     - User C (5 minutes ago)
     - User B (now)
   - Sorted by most recent read first

4. **Delivered Section:**
   - User A sends message to group (5 participants)
   - User B and User C read
   - User D and User E don't read
   - User A opens read receipts
   - "Read" section: User B, User C
   - "Delivered" section: User D, User E

5. **Real-Time Updates:**
   - User A sends message
   - User A opens read receipts sheet
   - Sheet stays open
   - User B reads message
   - User A's sheet auto-updates (User B moves to "Read" section)

6. **System Messages (No Read Receipts):**
   - User A creates group (system message appears)
   - User A long-presses system message
   - No read receipt sheet appears

7. **1:1 Chat Compatibility:**
   - User A sends message in 1:1 chat
   - Simple checkmark shown (not read receipt sheet)
   - Group behavior doesn't affect 1:1

8. **Offline Read Tracking:**
   - User B reads message offline
   - Read receipt queued locally
   - User B reconnects
   - Read receipt syncs to RTDB
   - User A sees update

### Success Criteria

- [ ] Builds without errors
- [ ] Runs on iOS 17+ simulator and device
- [ ] Long press own message → ReadReceiptsView appears
- [ ] Long press others' messages → no action
- [ ] "Read" section shows participants who read
- [ ] "Delivered" section shows participants who haven't read
- [ ] Read timestamps display correctly ("5 minutes ago", "now", etc.)
- [ ] Real-time updates as participants read
- [ ] System messages don't show read receipts
- [ ] Sender excluded from delivered list
- [ ] Sorted by most recent read first
- [ ] Offline read tracking works
- [ ] 1:1 chat compatibility maintained

---

## References

**Architecture Docs:**
- `docs/architecture/unified-project-structure.md` - File organization
- `docs/architecture/data-models.md` - MessageEntity schema

**PRD Sections:**
- `docs/prd.md` - Epic 3: Group Chat (Read Receipts)

**Epic Documentation:**
- `docs/epics/epic-3-group-chat.md` - Story 3.6 specification (lines 1164-1260)

**Related Stories:**
- Story 2.4: Message Delivery Status (read receipt foundation)
- Story 3.1: Create Group Conversation (group infrastructure)

---

## Notes & Considerations

### Implementation Notes

**Read Receipt Tracking:**
- Update RTDB when user opens MessageThreadView
- Mark all visible messages as read
- Update `/messages/{conversationID}/{messageID}/readBy/{userID}` = timestamp

**Long Press Gesture:**
- Only enable for own messages in groups
- Disable for system messages
- Disable for 1:1 chats (use simple checkmark)

**Timestamp Display:**
- Use `.relative` style: "5 minutes ago", "now", "yesterday"
- Sort by most recent read first
- Show exact timestamp on tap (optional enhancement)

### Edge Cases

- All participants read → empty "Delivered" section
- No participants read → empty "Read" section
- Participant removed while sheet open → remove from list
- Message deleted → read receipts preserved
- Offline read → queue and sync when online
- User deletes account → show "Deleted User" in read receipts

### Performance Considerations

- Load participants asynchronously
- Cache participant profiles with AsyncImage
- Debounce read receipt updates (max 1 update per second)
- Limit RTDB listener to current conversation only
- Use LazyVStack for large participant lists

### Security Considerations

- Only participants can see read receipts (RTDB rules)
- Read timestamps cannot be forged (server timestamp)
- Sender can only see read status, not unread count
- Removed users cannot update read receipts

---

## Metadata

**Created by:** @sm (Scrum Master Bob)
**Created date:** 2025-10-21
**Last updated:** 2025-10-21
**Sprint:** Day 2-3 of 7-day sprint
**Epic:** Epic 3: Group Chat
**Story points:** 3
**Priority:** P1

---

## Story Lifecycle

- [x] **Draft** - Story created, needs review
- [ ] **Ready** - Story reviewed and ready for development
- [ ] **In Progress** - Developer working on story
- [ ] **Blocked** - Story blocked by dependency or issue
- [ ] **Review** - Implementation complete, needs QA review
- [ ] **Done** - Story complete and validated

**Current Status:** Draft
