/**
 * Firebase Cloud Functions for Sorted App
 *
 * This file contains server-side triggers for:
 * - FCM push notifications (Story 2.0B)
 * - Atomic sequence number assignment (Story 2.3)
 * - Conversation metadata updates (Story 2.3)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Placeholder: Triggered when a new message is created in RTDB
 * Will send FCM notification to message recipients
 *
 * Implementation in Story 2.0B
 *
 * @trigger onCreate("/messages/{conversationID}/{messageID}")
 */
export const onMessageCreated = functions.database
  .ref("/messages/{conversationID}/{messageID}")
  .onCreate(async (snapshot, context) => {
    // TODO: Implement FCM notification logic in Story 2.0B
    const { conversationID, messageID } = context.params;
    const messageData = snapshot.val();

    console.log(`New message created: ${messageID} in conversation ${conversationID}`);
    console.log("Message data:", messageData);

    return null;
  });

/**
 * Placeholder: Assigns atomic sequence numbers to messages
 * Prevents client-side sequence number manipulation
 *
 * Implementation in Story 2.3
 *
 * @trigger onCreate("/messages/{conversationID}/{messageID}")
 */
export const assignSequenceNumber = functions.database
  .ref("/messages/{conversationID}/{messageID}")
  .onCreate(async (snapshot, context) => {
    // TODO: Implement sequence number assignment in Story 2.3
    const { conversationID, messageID } = context.params;

    // Get current conversation sequence counter
    const conversationRef = admin.database().ref(`conversations/${conversationID}`);
    const sequenceRef = conversationRef.child("lastSequenceNumber");

    // Atomic increment and assign
    const result = await sequenceRef.transaction((current) => {
      return (current || 0) + 1;
    });

    if (result.committed) {
      // Assign sequence number to message
      await snapshot.ref.update({
        sequenceNumber: result.snapshot.val(),
      });

      console.log(`Assigned sequence number ${result.snapshot.val()} to message ${messageID}`);
    }

    return null;
  });

/**
 * Placeholder: Updates conversation metadata when new message arrives
 * Updates lastMessage, lastMessageTimestamp
 *
 * Implementation in Story 2.3
 *
 * @trigger onCreate("/messages/{conversationID}/{messageID}")
 */
export const updateConversationLastMessage = functions.database
  .ref("/messages/{conversationID}/{messageID}")
  .onCreate(async (snapshot, context) => {
    // TODO: Implement conversation metadata update in Story 2.3
    const { conversationID } = context.params;
    const messageData = snapshot.val();

    // Update conversation last message
    const conversationRef = admin.database().ref(`conversations/${conversationID}`);
    await conversationRef.update({
      lastMessage: messageData.text,
      lastMessageTimestamp: admin.database.ServerValue.TIMESTAMP,
      updatedAt: admin.database.ServerValue.TIMESTAMP,
    });

    console.log(`Updated conversation ${conversationID} with latest message`);

    return null;
  });
