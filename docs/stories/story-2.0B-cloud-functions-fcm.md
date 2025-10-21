# Story 2.0B: Cloud Functions - FCM Push Notification Trigger

**Epic:** Epic 2 - One-on-One Chat Infrastructure
**Story ID:** 2.0B
**Priority:** P0 (Blocker - Required for Background Messaging)
**Estimated Time:** 45 minutes
**Dependencies:** Story 2.0 (FCM Setup)

---

## Status

✅ **Draft** - Awaiting approval from Sprint Change Proposal

---

## Story

**As a user,**
**I want to receive push notifications when someone sends me a message while my app is backgrounded or closed,**
**so that I don't miss important conversations.**

---

## Acceptance Criteria

1. Cloud Function triggers when new message is created in RTDB `/messages/{conversationID}/{messageID}`
2. Function reads message data (senderID, text, conversationID)
3. Function looks up recipient's FCM token from Firestore `/users/{recipientID}/fcmToken`
4. Function sends FCM notification with proper payload structure
5. Notification includes deep link data (conversationID, messageID)
6. Notification displays sender's display name as title
7. Message text preview shown in notification body (truncated to 100 chars)
8. Function handles errors gracefully (missing token, FCM send failure)
9. Function logs all notification sends for debugging
10. Notification only sent if recipient is NOT the sender (don't notify yourself)
11. Notification respects user preferences (future: mute, do not disturb)

---

## Tasks / Subtasks

- [ ] **Task 1: Initialize Firebase Cloud Functions Project** (AC: 1)
  - [ ] Run `firebase init functions` in project root
  - [ ] Select Node.js 18 runtime
  - [ ] Install Firebase Admin SDK dependencies
  - [ ] Configure functions directory structure

- [ ] **Task 2: Create RTDB Trigger Function** (AC: 1, 2)
  - [ ] Create `functions/src/index.ts`
  - [ ] Define `onMessageCreated` RTDB trigger
  - [ ] Listen to `/messages/{conversationID}/{messageID}` onCreate
  - [ ] Extract message data from snapshot

- [ ] **Task 3: Implement Recipient Lookup** (AC: 2, 3)
  - [ ] Extract participantIDs from conversation
  - [ ] Determine recipient (filter out sender)
  - [ ] Query Firestore for recipient's FCM token
  - [ ] Handle missing token gracefully

- [ ] **Task 4: Build FCM Notification Payload** (AC: 4, 5, 6, 7)
  - [ ] Fetch sender's display name from Firestore
  - [ ] Construct notification title (sender name)
  - [ ] Truncate message text to 100 characters
  - [ ] Add deep link data (conversationID, messageID)
  - [ ] Set notification sound and badge

- [ ] **Task 5: Send FCM Notification** (AC: 4, 8, 9)
  - [ ] Use Firebase Admin SDK to send notification
  - [ ] Handle FCM send errors (invalid token, network failure)
  - [ ] Log notification send success/failure
  - [ ] Return appropriate HTTP status codes

- [ ] **Task 6: Add Self-Send Prevention** (AC: 10)
  - [ ] Check if recipient matches sender
  - [ ] Skip notification if same user
  - [ ] Log skipped self-sends

- [ ] **Task 7: Deploy Cloud Function** (AC: All)
  - [ ] Run `firebase deploy --only functions`
  - [ ] Verify function appears in Firebase Console
  - [ ] Test with manual RTDB write
  - [ ] Verify notification received on physical device

- [ ] **Task 8: Add Error Handling & Logging** (AC: 8, 9)
  - [ ] Wrap function in try-catch
  - [ ] Log all errors with context
  - [ ] Add structured logging (conversationID, messageID, recipientID)
  - [ ] Return 500 on unhandled errors

---

## Dev Notes

### Firebase Cloud Functions Basics

**Runtime:** Node.js 18
**Billing:** Requires Firebase Blaze Plan (pay-as-you-go)
- Free tier: 2M invocations/month, 400K GB-seconds/month
- Estimated cost for MVP: $0 (well within free tier)

**Function Type:** RTDB Trigger (`onValueCreated`)

**Trigger Path:**
```
/messages/{conversationID}/{messageID}
```

**When function runs:**
- New message created in RTDB
- Function receives snapshot of new message
- Function extracts data and sends FCM notification

---

### Data Architecture Boundaries (from Sprint Change Proposal)

**FIRESTORE (Static Data):**
- `/users/{uid}/displayName` - Needed for notification title
- `/users/{uid}/fcmToken` - Needed to send notification

**RTDB (Real-time Data):**
- `/messages/{conversationID}/{messageID}` - Trigger source
- `/conversations/{conversationID}/participants` - Recipient lookup

**Flow:**
1. User A sends message → RTDB `/messages/convID/msgID` created
2. Cloud Function triggers
3. Function reads RTDB conversation → gets participants
4. Function reads Firestore user profiles → gets FCM tokens + display names
5. Function sends FCM notification → User B's device

---

### FCM Notification Payload Structure

```json
{
  "notification": {
    "title": "John Doe",
    "body": "Hey, how are you doing?",
    "sound": "default",
    "badge": "1"
  },
  "data": {
    "conversationID": "user1_user2",
    "messageID": "msg_abc123",
    "type": "new_message",
    "senderID": "user1",
    "timestamp": "1704067200000"
  },
  "token": "fE3Kd..." // Recipient's FCM token
}
```

**Key Fields:**
- `notification.title`: Sender's display name
- `notification.body`: Message text preview (max 100 chars)
- `data.conversationID`: For deep linking to MessageThreadView
- `data.messageID`: For scrolling to specific message (future)
- `data.type`: "new_message" (future: "new_conversation", "typing", etc.)

---

### Cloud Function Code Structure

```typescript
// functions/src/index.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.database();
const firestore = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: Send FCM notification when new message created
 * Trigger: RTDB /messages/{conversationID}/{messageID} onCreate
 */
export const onMessageCreated = functions.database
  .ref('/messages/{conversationID}/{messageID}')
  .onCreate(async (snapshot, context) => {
    try {
      // Extract parameters
      const conversationID = context.params.conversationID;
      const messageID = context.params.messageID;
      const messageData = snapshot.val();

      // Log trigger
      console.log(`[onMessageCreated] Triggered for message ${messageID} in conversation ${conversationID}`);

      // Extract message fields
      const senderID = messageData.senderID;
      const messageText = messageData.text;

      // Validate message data
      if (!senderID || !messageText) {
        console.error('[onMessageCreated] Missing required message fields');
        return null;
      }

      // Get conversation participants
      const conversationSnapshot = await db.ref(`/conversations/${conversationID}`).once('value');
      const conversationData = conversationSnapshot.val();

      if (!conversationData || !conversationData.participants) {
        console.error('[onMessageCreated] Conversation not found or missing participants');
        return null;
      }

      // Determine recipient (participant who is NOT the sender)
      const participants = Object.keys(conversationData.participants);
      const recipientID = participants.find(uid => uid !== senderID);

      if (!recipientID) {
        console.log('[onMessageCreated] No recipient found (self-send or single participant)');
        return null;
      }

      // Get recipient's FCM token from Firestore
      const recipientDoc = await firestore.collection('users').doc(recipientID).get();

      if (!recipientDoc.exists) {
        console.error(`[onMessageCreated] Recipient ${recipientID} not found in Firestore`);
        return null;
      }

      const recipientData = recipientDoc.data();
      const fcmToken = recipientData?.fcmToken;

      if (!fcmToken) {
        console.warn(`[onMessageCreated] Recipient ${recipientID} has no FCM token`);
        return null;
      }

      // Get sender's display name
      const senderDoc = await firestore.collection('users').doc(senderID).get();
      const senderDisplayName = senderDoc.exists ? senderDoc.data()?.displayName : 'Unknown';

      // Truncate message text to 100 characters
      const truncatedText = messageText.length > 100
        ? messageText.substring(0, 97) + '...'
        : messageText;

      // Build FCM notification payload
      const payload: admin.messaging.Message = {
        notification: {
          title: senderDisplayName,
          body: truncatedText,
        },
        data: {
          conversationID: conversationID,
          messageID: messageID,
          type: 'new_message',
          senderID: senderID,
          timestamp: String(messageData.serverTimestamp || Date.now()),
        },
        token: fcmToken,
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send FCM notification
      const response = await messaging.send(payload);

      console.log(`[onMessageCreated] Successfully sent notification to ${recipientID}: ${response}`);

      return response;

    } catch (error) {
      console.error('[onMessageCreated] Error sending notification:', error);
      throw error; // Re-throw to mark function as failed
    }
  });
```

---

### Environment Setup

**Prerequisites:**
- [ ] Firebase CLI installed: `npm install -g firebase-tools`
- [ ] Authenticated: `firebase login`
- [ ] Project selected: `firebase use sorted-app-12345`
- [ ] Blaze plan enabled (pay-as-you-go)

**Initialize Functions:**
```bash
# From project root
firebase init functions

# Select:
# - TypeScript (recommended) or JavaScript
# - ESLint (yes)
# - Install dependencies (yes)
```

**Project Structure:**
```
sorted/
├── functions/
│   ├── src/
│   │   └── index.ts          # Cloud Functions code
│   ├── package.json
│   ├── tsconfig.json
│   └── .eslintrc.js
├── firebase.json              # Firebase config
└── .firebaserc                # Project aliases
```

---

### Testing

**Local Testing (Firebase Emulator):**
```bash
# Start emulators
firebase emulators:start

# Emulators running at:
# - Firestore: http://localhost:8080
# - RTDB: http://localhost:9000
# - Functions: http://localhost:5001
# - Auth: http://localhost:9099
```

**Manual Test:**
1. Start emulators
2. Create test message in RTDB Emulator UI
3. Check Functions logs for trigger
4. Verify notification payload in logs

**Production Testing:**
1. Deploy function: `firebase deploy --only functions`
2. Send real message from iOS app
3. Check Firebase Console → Functions → Logs
4. Verify notification received on physical device

---

### Error Handling

**Common Errors:**

1. **Missing FCM Token:**
   ```
   Recipient has no FCM token
   ```
   **Solution:** User hasn't granted notification permissions or Story 2.0 not complete

2. **Invalid FCM Token:**
   ```
   messaging/invalid-registration-token
   ```
   **Solution:** Token expired or invalid, should delete from Firestore

3. **Conversation Not Found:**
   ```
   Conversation not found or missing participants
   ```
   **Solution:** Message created before conversation, race condition

4. **Firestore Read Failed:**
   ```
   Recipient not found in Firestore
   ```
   **Solution:** User deleted or Epic 1 incomplete

**Error Logging:**
```typescript
console.error('[onMessageCreated] Error:', {
  conversationID,
  messageID,
  recipientID,
  error: error.message,
  stack: error.stack,
});
```

---

### Performance Considerations

**Function Execution Time:**
- Target: <500ms (well within 540s limit)
- Firestore reads: 2 (sender + recipient) ~100ms
- RTDB read: 1 (conversation) ~50ms
- FCM send: ~200ms
- Total: ~350ms

**Cost Optimization:**
- Cache user display names in RTDB (future optimization)
- Batch notifications if multiple messages sent rapidly (future)
- Use Cloud Firestore indexes for faster reads

---

### Deployment

**Deploy Command:**
```bash
firebase deploy --only functions
```

**Expected Output:**
```
✔  functions: Finished running predeploy script.
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (53.2 KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 18 function onMessageCreated(us-central1)...
✔  functions[onMessageCreated(us-central1)]: Successful create operation.

✔  Deploy complete!
```

**Verify Deployment:**
1. Firebase Console → Functions
2. Check `onMessageCreated` appears in list
3. Status should be "Active"
4. Trigger: `database.ref('/messages/{conversationID}/{messageID}').onCreate`

---

### Security Considerations

1. **Function Authorization:**
   - Cloud Functions run with admin privileges
   - No need to check auth in function code
   - RTDB security rules already enforced

2. **Data Validation:**
   - Always validate message data exists
   - Check recipient is not sender
   - Verify FCM token format

3. **Rate Limiting:**
   - Firebase automatically rate limits functions
   - If user sends 100 messages/sec, function will throttle
   - Consider adding rate limiting in client (Story 2.3)

4. **Privacy:**
   - Don't log message content (PII)
   - Log only IDs and metadata
   - Comply with privacy policies

---

### Future Enhancements (Post-MVP)

- [ ] Notification grouping (multiple messages from same user)
- [ ] Rich notifications with inline reply
- [ ] Notification actions (Mark as Read, Mute)
- [ ] Respect user mute/DND preferences
- [ ] Notification sound customization
- [ ] Image/attachment preview in notification
- [ ] Unread badge count management
- [ ] Multi-device notification deduplication

---

## Testing & Verification

### Test Cases

**Test 1: Happy Path - New Message Notification**
1. User A sends message to User B
2. Verify Cloud Function triggers
3. Verify notification sent to User B
4. Tap notification → opens MessageThreadView for conversation

**Test 2: Self-Send Prevention**
1. User A sends message in conversation with themselves (if allowed)
2. Verify NO notification sent
3. Check logs: "No recipient found (self-send)"

**Test 3: Missing FCM Token**
1. User B has no FCM token in Firestore
2. User A sends message
3. Verify function logs: "Recipient has no FCM token"
4. No crash, function returns gracefully

**Test 4: Offline Sender**
1. User A offline, queues message in SwiftData
2. User A goes online, message syncs to RTDB
3. Verify notification sent to User B
4. Verify deep link works

**Test 5: Message Text Truncation**
1. User A sends 500-character message
2. Verify notification body truncated to 100 chars
3. Verify "..." appended
4. Full message visible when app opened

**Test 6: Multiple Rapid Messages**
1. User A sends 5 messages in 1 second
2. Verify 5 notifications sent (no batching yet)
3. Verify all deep links work correctly

---

## Dependencies

### Required Before This Story:
- ✅ Story 2.0 (FCM Setup) - FCM token storage in Firestore
- ✅ Epic 1 (Authentication) - User profiles in Firestore
- ✅ Epic 0 (RTDB Setup) - RTDB configured

### Blocks:
- ⚠️ Story 2.1 (Create Conversation) - Should test notifications after 2.1 complete
- ⚠️ Story 2.3 (Send/Receive Messages) - Full messaging flow requires notifications

### External Dependencies:
- Firebase Blaze Plan (pay-as-you-go) enabled
- Firebase Admin SDK installed
- Cloud Functions API enabled in Google Cloud Console

---

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-01-20 | 1.0 | Initial story created from Sprint Change Proposal | Sarah (PO) |

---

## Dev Agent Record

*This section will be populated by the development agent during implementation.*

### Agent Model Used

_To be filled by dev agent_

### Debug Log References

_To be filled by dev agent_

### Completion Notes List

_To be filled by dev agent_

### File List

_To be filled by dev agent_

---

## QA Results

*This section will be populated by the QA agent after implementation review.*

---

**Story Status:** ✅ Ready for Development (pending Sprint Change Proposal approval)
**Blocker:** None (depends on Story 2.0)
**Estimated Time:** 45 minutes
