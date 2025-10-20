# Epic 3: Group Chat

**Phase:** Day 2-3 (Extended Messaging)
**Priority:** P1 (High - Core Feature)
**Estimated Time:** 3-4 hours
**Epic Owner:** Development Team Lead
**Dependencies:** Epic 2 (One-on-One Chat Infrastructure)

---

## Overview

Extend the one-on-one messaging infrastructure to support group conversations with multiple participants. Includes group creation, participant management, group info editing, and optimized message delivery for multi-user scenarios.

---

## What This Epic Delivers

- ✅ Create group conversations with multiple participants
- ✅ Group info screen (name, photo, participant list)
- ✅ Add/remove participants from groups
- ✅ Group admin permissions (creator is admin)
- ✅ Leave group functionality
- ✅ Group name and photo editing
- ✅ Participant typing indicators ("Alice and Bob are typing...")
- ✅ Read receipts showing who read each message
- ✅ Group message delivery optimized for multiple recipients

---

## User Stories

### Story 3.1: Create Group Conversation
**As a user, I want to create a group chat with multiple people so we can all communicate together.**

**Acceptance Criteria:**
- [ ] User can tap "New Group" button from conversation list
- [ ] User can select 2+ recipients from contacts list
- [ ] User can set group name and optional group photo
- [ ] Group appears in conversation list immediately
- [ ] All participants receive notification of group creation
- [ ] Creator automatically becomes group admin
- [ ] Group persists locally and syncs to Firestore

**Technical Tasks:**
1. Update ConversationEntity to support group metadata:
   ```swift
   @Model
   final class ConversationEntity {
       @Attribute(.unique) var id: String
       var participantIDs: [String] // Multiple participants for groups
       var isGroup: Bool // true for groups, false for 1:1
       var groupName: String? // nil for 1:1 chats
       var groupPhotoURL: String?
       var adminUserIDs: [String] // Admins who can edit group
       var lastMessage: String?
       var lastMessageTimestamp: Date
       var unreadCount: Int
       var createdAt: Date
       var updatedAt: Date
       var syncStatus: SyncStatus
       var isArchived: Bool

       init(
           id: String,
           participantIDs: [String],
           isGroup: Bool = false,
           groupName: String? = nil,
           groupPhotoURL: String? = nil,
           adminUserIDs: [String] = [],
           lastMessage: String? = nil,
           lastMessageTimestamp: Date = Date(),
           unreadCount: Int = 0,
           createdAt: Date = Date(),
           updatedAt: Date = Date(),
           syncStatus: SyncStatus = .pending,
           isArchived: Bool = false
       ) {
           self.id = id
           self.participantIDs = participantIDs
           self.isGroup = isGroup
           self.groupName = groupName
           self.groupPhotoURL = groupPhotoURL
           self.adminUserIDs = adminUserIDs
           self.lastMessage = lastMessage
           self.lastMessageTimestamp = lastMessageTimestamp
           self.unreadCount = unreadCount
           self.createdAt = createdAt
           self.updatedAt = updatedAt
           self.syncStatus = syncStatus
           self.isArchived = isArchived
       }
   }
   ```

2. Create GroupCreationView:
   ```swift
   struct GroupCreationView: View {
       @Environment(\.dismiss) private var dismiss
       @Environment(\.modelContext) private var modelContext

       @StateObject private var viewModel: GroupCreationViewModel
       @State private var groupName = ""
       @State private var selectedUserIDs: Set<String> = []
       @State private var groupPhoto: UIImage?
       @State private var showImagePicker = false

       var body: some View {
           NavigationStack {
               Form {
                   Section {
                       HStack {
                           // Group photo
                           Button(action: { showImagePicker = true }) {
                               if let photo = groupPhoto {
                                   Image(uiImage: photo)
                                       .resizable()
                                       .scaledToFill()
                                       .frame(width: 80, height: 80)
                                       .clipShape(Circle())
                               } else {
                                   ZStack {
                                       Circle()
                                           .fill(Color.gray.opacity(0.3))
                                           .frame(width: 80, height: 80)

                                       Image(systemName: "camera.fill")
                                           .foregroundColor(.gray)
                                   }
                               }
                           }

                           VStack(alignment: .leading) {
                               TextField("Group Name", text: $groupName)
                                   .font(.system(size: 18, weight: .semibold))

                               Text("\(selectedUserIDs.count) participants")
                                   .font(.system(size: 14))
                                   .foregroundColor(.secondary)
                           }
                       }
                   }

                   Section("Participants") {
                       ParticipantPickerView(selectedUserIDs: $selectedUserIDs)
                   }
               }
               .navigationTitle("New Group")
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .cancellationAction) {
                       Button("Cancel") { dismiss() }
                   }

                   ToolbarItem(placement: .confirmationAction) {
                       Button("Create") {
                           Task {
                               await createGroup()
                           }
                       }
                       .disabled(groupName.isEmpty || selectedUserIDs.count < 2)
                   }
               }
               .sheet(isPresented: $showImagePicker) {
                   ImagePicker(image: $groupPhoto)
               }
           }
       }

       private func createGroup() async {
           var participantIDs = Array(selectedUserIDs)
           participantIDs.append(AuthService.shared.currentUserID)

           let conversation = ConversationEntity(
               id: UUID().uuidString,
               participantIDs: participantIDs,
               isGroup: true,
               groupName: groupName,
               adminUserIDs: [AuthService.shared.currentUserID]
           )

           // Save locally
           modelContext.insert(conversation)
           try? modelContext.save()

           // Upload group photo if provided
           if let photo = groupPhoto {
               Task.detached {
                   if let url = try? await StorageService.shared.uploadGroupPhoto(
                       photo,
                       groupID: conversation.id
                   ) {
                       await MainActor.run {
                           conversation.groupPhotoURL = url
                           try? modelContext.save()
                       }
                   }
               }
           }

           // Sync to Firestore
           Task.detached {
               try? await ConversationService.shared.syncConversation(conversation)
           }

           dismiss()
       }
   }
   ```

3. Create ParticipantPickerView component
4. Update ConversationListView to show "New Group" button
5. Update ConversationService to handle group creation in Firestore

**References:**
- SwiftData Implementation Guide Section 3.2 (ConversationEntity updates)
- PRD Epic 3: Group Chat

---

### Story 3.2: Group Info Screen
**As a user, I want to view group details so I can see participants and group settings.**

**Acceptance Criteria:**
- [ ] Tap group name in navigation bar opens group info screen
- [ ] Shows group photo, name, participant count
- [ ] Lists all participants with profile pictures
- [ ] Admin badge shown for group admins
- [ ] "Edit Group" button visible only to admins
- [ ] "Leave Group" button at bottom (destructive action)
- [ ] "Add Participants" button for admins

**Technical Tasks:**
1. Create GroupInfoView:
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
                           ZStack {
                               Circle().fill(Color.gray.opacity(0.3))
                               Image(systemName: "person.3.fill")
                                   .foregroundColor(.gray)
                           }
                       }
                       .frame(width: 120, height: 120)
                       .clipShape(Circle())

                       // Group name
                       Text(conversation.groupName ?? "Unnamed Group")
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
                   .frame(maxWidth: .infinity)
                   .padding(.vertical)
               }

               Section("Participants") {
                   ForEach(participants) { participant in
                       HStack(spacing: 12) {
                           // Profile picture
                           AsyncImage(url: URL(string: participant.profilePictureURL ?? "")) { image in
                               image.resizable().scaledToFill()
                           } placeholder: {
                               Circle().fill(Color.gray.opacity(0.3))
                           }
                           .frame(width: 44, height: 44)
                           .clipShape(Circle())

                           VStack(alignment: .leading) {
                               Text(participant.displayName)
                                   .font(.system(size: 16, weight: .medium))

                               if conversation.adminUserIDs.contains(participant.id) {
                                   Text("Group Admin")
                                       .font(.system(size: 14))
                                       .foregroundColor(.blue)
                               }
                           }

                           Spacer()

                           if isAdmin && participant.id != AuthService.shared.currentUserID {
                               Button(role: .destructive) {
                                   removeParticipant(participant)
                               } label: {
                                   Image(systemName: "minus.circle.fill")
                                       .foregroundColor(.red)
                               }
                           }
                       }
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
                           .foregroundColor(.red)
                   }
               }
           }
           .navigationTitle("Group Info")
           .navigationBarTitleDisplayMode(.inline)
           .sheet(isPresented: $showEditSheet) {
               EditGroupInfoView(conversation: conversation)
           }
           .sheet(isPresented: $showAddParticipants) {
               AddParticipantsView(conversation: conversation)
           }
           .confirmationDialog("Leave Group?", isPresented: $showLeaveConfirmation) {
               Button("Leave Group", role: .destructive) {
                   Task { await leaveGroup() }
               }
           } message: {
               Text("Are you sure you want to leave this group? You can't undo this action.")
           }
           .task {
               await loadParticipants()
           }
       }

       private func loadParticipants() async {
           // Fetch participant users
           let descriptor = FetchDescriptor<UserEntity>(
               predicate: #Predicate { user in
                   conversation.participantIDs.contains(user.id)
               }
           )

           participants = (try? modelContext.fetch(descriptor)) ?? []
       }

       private func removeParticipant(_ participant: UserEntity) {
           conversation.participantIDs.removeAll { $0 == participant.id }
           try? modelContext.save()

           // Sync to Firestore
           Task.detached {
               try? await ConversationService.shared.syncConversation(conversation)
           }

           // Reload participants
           Task { await loadParticipants() }
       }

       private func leaveGroup() async {
           conversation.participantIDs.removeAll {
               $0 == AuthService.shared.currentUserID
           }
           conversation.isArchived = true
           try? modelContext.save()

           // Sync to Firestore
           try? await ConversationService.shared.syncConversation(conversation)
       }
   }
   ```

2. Create EditGroupInfoView sheet for admins
3. Create AddParticipantsView sheet for admins
4. Update MessageThreadView to link to GroupInfoView on navigation bar tap

**References:**
- UX Design Doc Section 3.3 (Group Info Screen)

---

### Story 3.3: Add and Remove Participants
**As a group admin, I want to add and remove participants so I can manage group membership.**

**Acceptance Criteria:**
- [ ] Only group admins can add/remove participants
- [ ] "Add Participants" button opens contact picker
- [ ] Selected users added to group immediately
- [ ] New participants receive group join notification
- [ ] Removed participants see "You were removed from [group name]"
- [ ] Participant changes sync to all group members in real-time
- [ ] Minimum 2 participants enforced (cannot remove if only 2 left)

**Technical Tasks:**
1. Create AddParticipantsView:
   ```swift
   struct AddParticipantsView: View {
       let conversation: ConversationEntity

       @Environment(\.dismiss) private var dismiss
       @Environment(\.modelContext) private var modelContext

       @State private var selectedUserIDs: Set<String> = []
       @State private var availableUsers: [UserEntity] = []

       var body: some View {
           NavigationStack {
               List {
                   ForEach(availableUsers) { user in
                       Button {
                           if selectedUserIDs.contains(user.id) {
                               selectedUserIDs.remove(user.id)
                           } else {
                               selectedUserIDs.insert(user.id)
                           }
                       } label: {
                           HStack {
                               AsyncImage(url: URL(string: user.profilePictureURL ?? "")) { image in
                                   image.resizable().scaledToFill()
                               } placeholder: {
                                   Circle().fill(Color.gray.opacity(0.3))
                               }
                               .frame(width: 44, height: 44)
                               .clipShape(Circle())

                               Text(user.displayName)

                               Spacer()

                               if selectedUserIDs.contains(user.id) {
                                   Image(systemName: "checkmark.circle.fill")
                                       .foregroundColor(.blue)
                               }
                           }
                       }
                   }
               }
               .navigationTitle("Add Participants")
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .cancellationAction) {
                       Button("Cancel") { dismiss() }
                   }

                   ToolbarItem(placement: .confirmationAction) {
                       Button("Add") {
                           addParticipants()
                       }
                       .disabled(selectedUserIDs.isEmpty)
                   }
               }
               .task {
                   await loadAvailableUsers()
               }
           }
       }

       private func loadAvailableUsers() async {
           // Fetch users not already in group
           let descriptor = FetchDescriptor<UserEntity>(
               predicate: #Predicate { user in
                   !conversation.participantIDs.contains(user.id)
               }
           )

           availableUsers = (try? modelContext.fetch(descriptor)) ?? []
       }

       private func addParticipants() {
           conversation.participantIDs.append(contentsOf: selectedUserIDs)
           conversation.updatedAt = Date()
           try? modelContext.save()

           // Sync to Firestore
           Task.detached {
               try? await ConversationService.shared.syncConversation(conversation)

               // Send system message
               let systemMessage = MessageEntity(
                   id: UUID().uuidString,
                   conversationID: conversation.id,
                   senderID: "system",
                   text: "\(AuthService.shared.currentUser?.displayName ?? "Someone") added \(selectedUserIDs.count) participant(s)",
                   createdAt: Date(),
                   status: .sent,
                   syncStatus: .synced,
                   isSystemMessage: true
               )

               try? await MessageService.shared.syncMessage(systemMessage)
           }

           dismiss()
       }
   }
   ```

2. Add participant removal logic with minimum enforcement
3. Create system messages for join/leave events
4. Update MessageEntity to support system messages:
   ```swift
   @Model
   final class MessageEntity {
       // ... existing properties ...
       var isSystemMessage: Bool = false // true for "Alice joined", etc.
   }
   ```

5. Render system messages differently in MessageBubbleView (centered, gray text)

**References:**
- PRD Epic 3: Group Chat (Participant Management)

---

### Story 3.4: Edit Group Name and Photo
**As a group admin, I want to edit the group name and photo so I can keep group info up to date.**

**Acceptance Criteria:**
- [ ] Only group admins can edit group info
- [ ] "Edit Group Info" button opens edit sheet
- [ ] User can change group name (1-50 characters)
- [ ] User can upload new group photo via image picker
- [ ] Changes save locally and sync to Firestore
- [ ] All group members see updated info in real-time
- [ ] System message posted: "Alice changed the group name to..."

**Technical Tasks:**
1. Create EditGroupInfoView:
   ```swift
   struct EditGroupInfoView: View {
       let conversation: ConversationEntity

       @Environment(\.dismiss) private var dismiss
       @Environment(\.modelContext) private var modelContext

       @State private var groupName: String
       @State private var groupPhoto: UIImage?
       @State private var showImagePicker = false
       @State private var isUploading = false

       init(conversation: ConversationEntity) {
           self.conversation = conversation
           _groupName = State(initialValue: conversation.groupName ?? "")
       }

       var body: some View {
           NavigationStack {
               Form {
                   Section {
                       HStack {
                           Spacer()

                           Button(action: { showImagePicker = true }) {
                               if let photo = groupPhoto {
                                   Image(uiImage: photo)
                                       .resizable()
                                       .scaledToFill()
                                       .frame(width: 100, height: 100)
                                       .clipShape(Circle())
                               } else {
                                   AsyncImage(url: URL(string: conversation.groupPhotoURL ?? "")) { image in
                                       image.resizable().scaledToFill()
                                   } placeholder: {
                                       ZStack {
                                           Circle().fill(Color.gray.opacity(0.3))
                                           Image(systemName: "camera.fill")
                                               .foregroundColor(.gray)
                                       }
                                   }
                                   .frame(width: 100, height: 100)
                                   .clipShape(Circle())
                               }
                           }

                           Spacer()
                       }

                       TextField("Group Name", text: $groupName)
                           .font(.system(size: 18))

                       Text("\(groupName.count)/50 characters")
                           .font(.system(size: 12))
                           .foregroundColor(.secondary)
                   }
               }
               .navigationTitle("Edit Group Info")
               .navigationBarTitleDisplayMode(.inline)
               .toolbar {
                   ToolbarItem(placement: .cancellationAction) {
                       Button("Cancel") { dismiss() }
                   }

                   ToolbarItem(placement: .confirmationAction) {
                       Button("Save") {
                           Task { await saveChanges() }
                       }
                       .disabled(groupName.isEmpty || groupName.count > 50)
                   }
               }
               .sheet(isPresented: $showImagePicker) {
                   ImagePicker(image: $groupPhoto)
               }
               .overlay {
                   if isUploading {
                       ProgressView("Uploading...")
                           .padding()
                           .background(Color(.systemBackground))
                           .cornerRadius(10)
                           .shadow(radius: 10)
                   }
               }
           }
       }

       private func saveChanges() async {
           let oldName = conversation.groupName

           // Update group name
           conversation.groupName = groupName
           conversation.updatedAt = Date()
           try? modelContext.save()

           // Upload new photo if changed
           if let photo = groupPhoto {
               isUploading = true

               if let url = try? await StorageService.shared.uploadGroupPhoto(
                   photo,
                   groupID: conversation.id
               ) {
                   conversation.groupPhotoURL = url
                   try? modelContext.save()
               }

               isUploading = false
           }

           // Sync to Firestore
           Task.detached {
               try? await ConversationService.shared.syncConversation(conversation)

               // Post system message
               if oldName != groupName {
                   let systemMessage = MessageEntity(
                       id: UUID().uuidString,
                       conversationID: conversation.id,
                       senderID: "system",
                       text: "\(AuthService.shared.currentUser?.displayName ?? "Someone") changed the group name to \"\(groupName)\"",
                       createdAt: Date(),
                       status: .sent,
                       syncStatus: .synced,
                       isSystemMessage: true
                   )

                   try? await MessageService.shared.syncMessage(systemMessage)
               }
           }

           dismiss()
       }
   }
   ```

2. Update StorageService to support group photo uploads
3. Add system message for name changes
4. Update Firestore listener to handle group info updates

**References:**
- Architecture Doc Section 5.3 (Conversation Management)

---

### Story 3.5: Group Typing Indicators
**As a user, I want to see who is typing in a group so I know who is responding.**

**Acceptance Criteria:**
- [ ] Shows "Alice is typing..." for single typer
- [ ] Shows "Alice and Bob are typing..." for 2 typers
- [ ] Shows "Alice, Bob, and 2 others are typing..." for 4+ typers
- [ ] Typing indicator disappears after 3 seconds of inactivity
- [ ] Only shows for active conversation (not in conversation list)

**Technical Tasks:**
1. Update TypingIndicatorService to handle multiple users:
   ```swift
   extension TypingIndicatorService {
       func formatTypingText(userIDs: Set<String>, participants: [UserEntity]) -> String {
           let typingUsers = participants.filter { userIDs.contains($0.id) }

           switch typingUsers.count {
           case 0:
               return ""
           case 1:
               return "\(typingUsers[0].displayName) is typing..."
           case 2:
               return "\(typingUsers[0].displayName) and \(typingUsers[1].displayName) are typing..."
           case 3:
               return "\(typingUsers[0].displayName), \(typingUsers[1].displayName), and \(typingUsers[2].displayName) are typing..."
           default:
               let others = typingUsers.count - 2
               return "\(typingUsers[0].displayName), \(typingUsers[1].displayName), and \(others) others are typing..."
           }
       }
   }
   ```

2. Update MessageThreadView to show formatted typing text
3. Add participant name resolution for typing users

**References:**
- UX Design Doc Section 3.2 (Message Thread - Typing Indicators)

---

### Story 3.6: Group Read Receipts
**As a user, I want to see who read my messages in a group so I know who is up to date.**

**Acceptance Criteria:**
- [ ] Tap message in group shows read receipt sheet
- [ ] Sheet lists all participants with read status
- [ ] Shows "Read" with timestamp for readers
- [ ] Shows "Delivered" for non-readers
- [ ] Only available for user's own sent messages
- [ ] Updates in real-time as participants read

**Technical Tasks:**
1. Add read receipts to MessageEntity:
   ```swift
   @Model
   final class MessageEntity {
       // ... existing properties ...
       var readBy: [String: Date] = [:] // userID -> readAt timestamp
   }
   ```

2. Create ReadReceiptsView sheet:
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
       }

       private var unreadParticipants: [UserEntity] {
           participants.filter { message.readBy[$0.id] == nil && $0.id != message.senderID }
       }
   }
   ```

3. Update MessageBubbleView to show read receipt sheet on long press
4. Update MessageService to track read receipts in Firestore
5. Add Firestore listener for read receipt updates

**References:**
- PRD Epic 3: Group Chat (Read Receipts)

---

## Dependencies & Prerequisites

### Required Epics:
- [x] Epic 0: Project Scaffolding
- [x] Epic 1: User Authentication
- [x] Epic 2: One-on-One Chat Infrastructure

### Required Services:
- [x] ConversationService with group support
- [x] MessageService with group message delivery
- [x] StorageService for group photo uploads

---

## Testing & Verification

### Verification Checklist:
- [ ] Create group with 3+ participants works
- [ ] Group appears in all participants' conversation lists
- [ ] Group messages deliver to all participants
- [ ] Group info screen shows all participants
- [ ] Add/remove participants works (admin only)
- [ ] Edit group name/photo works (admin only)
- [ ] Leave group removes user from participant list
- [ ] Typing indicators show multiple users correctly
- [ ] Read receipts track who read messages

### Test Procedure:
1. **Group Creation:**
   - User A creates group with User B and User C
   - All users see group in conversation list
   - Send message from User A
   - Verify User B and User C receive message

2. **Participant Management:**
   - User A (admin) adds User D
   - Verify all users see User D in participant list
   - User A removes User D
   - Verify User D sees "You were removed"

3. **Group Editing:**
   - User A changes group name
   - Verify all users see new name
   - User A changes group photo
   - Verify all users see new photo

---

## Success Criteria

**Epic 3 is complete when:**
- ✅ Users can create group conversations with 2+ participants
- ✅ Group info screen shows participants and settings
- ✅ Admins can add/remove participants
- ✅ Admins can edit group name and photo
- ✅ Users can leave groups
- ✅ Typing indicators show multiple users
- ✅ Read receipts show who read messages
- ✅ All group operations sync in real-time

---

## Time Estimates

| Story | Estimated Time |
|-------|---------------|
| 3.1 Create Group Conversation | 60 mins |
| 3.2 Group Info Screen | 45 mins |
| 3.3 Add and Remove Participants | 45 mins |
| 3.4 Edit Group Name and Photo | 30 mins |
| 3.5 Group Typing Indicators | 20 mins |
| 3.6 Group Read Receipts | 40 mins |
| **Total** | **3-4 hours** |

---

## Implementation Order

**Recommended sequence:**
1. Story 3.1 (Create Group) - Foundation
2. Story 3.2 (Group Info) - Management UI
3. Story 3.3 (Add/Remove Participants) - Core management
4. Story 3.4 (Edit Group Info) - Customization
5. Story 3.5 (Typing Indicators) - Polish
6. Story 3.6 (Read Receipts) - Advanced feature

---

## References

- **SwiftData Implementation Guide**: `docs/swiftdata-implementation-guide.md`
- **Architecture Doc**: `docs/architecture.md` (Section 5: Data Flow)
- **UX Design Doc**: `docs/ux-design.md` (Section 3.3: Group Info)
- **PRD**: `docs/prd.md` (Epic 3: Group Chat)

---

**Epic Status:** Ready for implementation
**Blockers:** None (depends on Epic 2)
**Risk Level:** Low (extends Epic 2 infrastructure)
