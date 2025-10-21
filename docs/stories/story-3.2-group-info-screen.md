---
# Story 3.2: Group Info Screen
# Epic 3: Group Chat
# Status: Draft

id: STORY-3.2
title: "View Group Details and Participant List"
epic: "Epic 3: Group Chat"
status: draft
priority: P1
estimate: 3  # Story points (50 minutes)
assigned_to: null
created_date: "2025-10-21"
sprint_day: null

---

## Description

**As a** group chat participant
**I need** to view group details (name, photo, members)
**So that** I can see who's in the group and manage settings

This story implements the group information screen, providing users with:
- Group photo and name display
- Complete participant list with profile pictures
- Admin badges for group administrators
- Edit Group button (admin-only)
- Add Participants button (admin-only)
- Leave Group button with confirmation

---

## Acceptance Criteria

**This story is complete when:**

- [ ] Tap group name in MessageThreadView navigation bar opens GroupInfoView
- [ ] Shows group photo, name, and participant count
- [ ] Lists all participants with profile pictures and display names
- [ ] Admin badge shown next to group admins
- [ ] "Edit Group" button visible only to admins
- [ ] "Leave Group" button visible at bottom (destructive action)
- [ ] "Add Participants" button visible to admins
- [ ] Deleted user accounts shown as "Deleted User" with placeholder avatar
- [ ] Lazy loading for participant lists with 50+ members
- [ ] Concurrent participant removal handled gracefully (no duplicate removal errors)
- [ ] User automatically navigates back if removed while viewing group
- [ ] Last admin cannot leave without transferring admin rights first
- [ ] "Leave Group" shows admin transfer dialog if user is last admin
- [ ] If last admin force-leaves, oldest member automatically becomes admin

---

## Technical Tasks

**Implementation steps:**

1. **Create GroupInfoView** [Source: epic-3-group-chat.md lines 553-757]
   - Create file: `sorted/Features/Chat/Views/GroupInfoView.swift`
   - Display group photo (AsyncImage with circle shape)
   - Display group name and participant count
   - Show "Edit Group Info" button (if admin)
   - List all participants with profile pictures
   - Show admin badge for admins
   - Add "Add Participants" button (if admin)
   - Add "Leave Group" button (destructive action)
   - Use `.confirmationDialog()` for leave confirmation

2. **Implement Participant List**
   - Fetch participant users from SwiftData using FetchDescriptor
   - Filter UserEntity by `participantIDs` array
   - Display in List with HStack layout
   - Show profile picture (AsyncImage with fallback)
   - Show display name
   - Show "Group Admin" label if user in `adminUserIDs`
   - Show remove button (red minus circle) for admins

3. **Implement Leave Group Logic** [Source: epic-3-group-chat.md lines 721-755]
   - Check if user is last admin
   - If last admin and other participants exist → show admin transfer dialog
   - Remove current user from `participantIDs`
   - Remove current user from `adminUserIDs`
   - Set `isArchived: true` for current user
   - Update `syncStatus: .pending`
   - Sync to RTDB via ConversationService
   - Send system message: "{User} left the group"
   - Navigate back to ConversationListView

4. **Implement Remove Participant Logic** [Source: epic-3-group-chat.md lines 689-719]
   - Admin-only action
   - Remove participant from `participantIDs`
   - Update `updatedAt` timestamp
   - Set `syncStatus: .pending`
   - Sync to RTDB
   - Send system message: "{Admin} removed {Participant}"
   - Reload participants list

5. **Update MessageThreadView Navigation**
   - Make group name in navigation bar tappable
   - Present GroupInfoView in NavigationLink or sheet
   - Pass conversation entity to GroupInfoView

6. **Handle Edge Cases**
   - Deleted users: Show "Deleted User" with placeholder avatar
   - Concurrent removal: Handle gracefully, no duplicate errors
   - User removed while viewing: Auto-navigate back
   - Last admin leaving: Force admin transfer or prevent
   - Lazy loading: Use LazyVStack for 50+ participants

---

## Technical Specifications

### Files to Create

```
sorted/Features/Chat/Views/GroupInfoView.swift (create)
```

### Files to Modify

```
sorted/Features/Chat/Views/MessageThreadView.swift (modify - add navigation to GroupInfoView)
sorted/Core/Services/ConversationService.swift (modify - handle participant removal sync)
```

### Data Flow

**Participant Loading:**
```
1. GroupInfoView appears
2. Extract participantIDs from conversation
3. Query SwiftData for UserEntity matching IDs
4. Display in List
5. Filter deleted users → show placeholder
```

**Leave Group:**
```
1. User taps "Leave Group"
2. confirmationDialog appears
3. User confirms
4. Check if last admin → show transfer dialog if needed
5. Remove self from participantIDs and adminUserIDs
6. Archive conversation locally
7. Sync to RTDB
8. Send system message
9. Navigate back
```

**Remove Participant:**
```
1. Admin taps remove button
2. Remove participant from participantIDs
3. Update conversation
4. Sync to RTDB
5. Send system message
6. Reload participant list
```

### Code Examples

**GroupInfoView Structure:**
```swift
struct GroupInfoView: View {
    let conversation: ConversationEntity

    @Environment(\.modelContext) private var modelContext
    @State private var participants: [UserEntity] = []
    @State private var showEditSheet = false
    @State private var showAddParticipants = false
    @State private var showLeaveConfirmation = false

    private var isAdmin: Bool {
        conversation.adminUserIDs.contains(AuthService.shared.currentUserID)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // Group photo
                    AsyncImage(url: URL(string: conversation.groupPhotoURL ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                            .overlay {
                                Image(systemName: "person.3.fill")
                            }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())

                    Text(conversation.displayName ?? "Unnamed Group")
                        .font(.system(size: 22, weight: .bold))

                    Text("\(conversation.participantIDs.count) participants")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    if isAdmin {
                        Button("Edit Group Info") {
                            showEditSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Section("Participants") {
                ForEach(participants) { participant in
                    ParticipantRow(
                        participant: participant,
                        isAdmin: conversation.adminUserIDs.contains(participant.id),
                        canRemove: isAdmin && participant.id != AuthService.shared.currentUserID,
                        onRemove: { removeParticipant(participant) }
                    )
                }

                if isAdmin {
                    Button {
                        showAddParticipants = true
                    } label: {
                        Label("Add Participants", systemImage: "plus.circle.fill")
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showLeaveConfirmation = true
                } label: {
                    Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Group Info")
        .task {
            await loadParticipants()
        }
    }
}
```

**Leave Group Logic:**
```swift
private func leaveGroup() async {
    let currentUserID = AuthService.shared.currentUserID ?? ""
    let isLastAdmin = conversation.adminUserIDs.count == 1 &&
                      conversation.adminUserIDs.contains(currentUserID)

    // If last admin, must transfer admin rights first
    if isLastAdmin && conversation.participantIDs.count > 1 {
        showAdminTransferDialog = true
        return
    }

    // Remove self from participants and admins
    conversation.participantIDs.removeAll { $0 == currentUserID }
    conversation.adminUserIDs.removeAll { $0 == currentUserID }
    conversation.isArchived = true
    conversation.syncStatus = .pending
    try? modelContext.save()

    // Sync to RTDB
    try? await ConversationService.shared.syncConversationToRTDB(conversation)

    // Send system message
    let displayName = AuthService.shared.currentUser?.displayName ?? "Someone"
    let systemMessage = MessageEntity(
        id: UUID().uuidString,
        conversationID: conversation.id,
        senderID: "system",
        text: "\(displayName) left the group",
        createdAt: Date(),
        status: .sent,
        syncStatus: .synced,
        isSystemMessage: true
    )
    try? await MessageService.shared.sendMessageToRTDB(systemMessage)
}
```

### Dependencies

**Required:**
- ✅ Story 3.1: Create Group Conversation (group entities exist)
- ✅ UserEntity model exists
- ✅ ConversationService with RTDB sync
- ✅ MessageService for system messages

**Blocks:**
- Story 3.3: Add/Remove Participants (uses similar UI patterns)
- Story 3.4: Edit Group Info (launched from GroupInfoView)

**External:**
- SwiftData ModelContext available
- Firestore user profiles accessible

---

## Testing & Validation

### Test Procedure

1. **Access Group Info:**
   - Open group conversation (MessageThreadView)
   - Tap group name in navigation bar
   - GroupInfoView appears

2. **View Group Details:**
   - Verify group photo displays
   - Verify group name displays
   - Verify participant count correct
   - Verify all participants listed

3. **Participant List:**
   - Verify profile pictures load
   - Verify display names show
   - Verify admin badge shows for admins
   - Verify deleted users show as "Deleted User"

4. **Admin-Only Features:**
   - Log in as admin
   - Verify "Edit Group" button visible
   - Verify "Add Participants" button visible
   - Verify remove buttons show for other participants
   - Log in as non-admin
   - Verify admin buttons hidden

5. **Leave Group:**
   - Tap "Leave Group"
   - confirmationDialog appears
   - Tap "Leave Group" (confirm)
   - User removed from group
   - Navigates back to ConversationListView
   - System message appears: "{User} left the group"

6. **Last Admin Edge Case:**
   - Create group as User A (admin)
   - Add User B (not admin)
   - User A taps "Leave Group"
   - Admin transfer dialog appears
   - User A must transfer admin or cancel

7. **Remove Participant (Admin):**
   - Log in as admin
   - Tap remove button on participant
   - Participant removed
   - System message: "{Admin} removed {Participant}"
   - Participant list updates

8. **Concurrent Removal:**
   - Admin A and Admin B both remove User C simultaneously
   - No errors, User C removed once
   - Single system message posted

9. **Lazy Loading (50+ Participants):**
   - Create group with 60 participants
   - Open GroupInfoView
   - Verify smooth scrolling
   - Verify LazyVStack used

### Success Criteria

- [ ] Builds without errors
- [ ] Runs on iOS 17+ simulator and device
- [ ] GroupInfoView displays group details correctly
- [ ] Participant list loads and displays
- [ ] Admin badges shown correctly
- [ ] Admin-only buttons hidden for non-admins
- [ ] Leave Group works with confirmation
- [ ] Last admin prevented from leaving (or forced transfer)
- [ ] Remove participant works (admin only)
- [ ] System messages created for leave/remove
- [ ] Deleted users handled gracefully
- [ ] Concurrent removal handled
- [ ] Lazy loading works for large groups
- [ ] Navigation to/from GroupInfoView smooth

---

## References

**Architecture Docs:**
- `docs/architecture/unified-project-structure.md` - File organization
- `docs/ux-design.md` - Section 3.3: Group Info Screen

**PRD Sections:**
- `docs/prd.md` - Epic 3: Group Chat

**Epic Documentation:**
- `docs/epics/epic-3-group-chat.md` - Story 3.2 specification (lines 519-765)

**Related Stories:**
- Story 3.1: Create Group Conversation (creates groups)
- Story 3.3: Add/Remove Participants (extends functionality)
- Story 3.4: Edit Group Info (launched from here)

---

## Notes & Considerations

### Implementation Notes

**Admin Detection:**
- Use `conversation.adminUserIDs.contains(AuthService.shared.currentUserID)` to check admin status
- Admin-only buttons: Edit Group, Add Participants, Remove Participant

**System Messages:**
- Send system message for leave: "{DisplayName} left the group"
- Send system message for removal: "{Admin} removed {Participant}"
- `senderID: "system"`, `isSystemMessage: true`

**Navigation:**
- GroupInfoView presented via NavigationLink from MessageThreadView
- Tapping group name in navigation bar triggers presentation
- Auto-dismiss if user removed while viewing

### Edge Cases

- User removed while viewing GroupInfoView → auto-dismiss
- Last admin leaving → show admin transfer dialog
- Deleted user accounts → show "Deleted User" placeholder
- Concurrent participant removal → handle gracefully
- Network failure during leave → queue for sync
- Large participant lists (50+) → lazy loading

### Performance Considerations

- Use LazyVStack for participant lists (not eager ForEach)
- Fetch participants asynchronously in `.task`
- Cache profile pictures with AsyncImage
- Debounce remove actions (prevent rapid taps)

### Security Considerations

- Only admins can remove participants (check `isAdmin` before removal)
- Only admins can access "Edit Group" and "Add Participants"
- Validate admin status server-side (RTDB rules)
- Last admin cannot leave without transfer (enforced in UI and server)

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
