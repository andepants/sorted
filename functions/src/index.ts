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
 * Cloud Function: Send FCM notification when new message created
 *
 * Triggers when a new message is written to RTDB and sends a push notification
 * to the recipient with message preview and deep link data.
 *
 * Story 2.0B Implementation
 *
 * @trigger onCreate("/messages/{conversationID}/{messageID}")
 */
export const onMessageCreated = functions.database
  .ref("/messages/{conversationID}/{messageID}")
  .onCreate(async (snapshot, context) => {
    try {
      // Extract parameters
      const conversationID = context.params.conversationID;
      const messageID = context.params.messageID;
      const messageData = snapshot.val();

      // Log trigger
      console.log(`[onMessageCreated] Triggered for message ${messageID} in conversation ${conversationID}`);

      // Validate message data exists
      if (!messageData) {
        console.error("[onMessageCreated] Message data is null or undefined");
        return null;
      }

      // Extract message fields
      const senderID = messageData.senderID;
      const messageText = messageData.text;

      // Validate required fields
      if (!senderID || !messageText) {
        console.error("[onMessageCreated] Missing required message fields (senderID or text)");
        return null;
      }

      // Get conversation participants
      const conversationSnapshot = await admin.database()
        .ref(`conversations/${conversationID}`)
        .once("value");
      const conversationData = conversationSnapshot.val();

      if (!conversationData || !conversationData.participants) {
        console.error("[onMessageCreated] Conversation not found or missing participants");
        return null;
      }

      // Determine recipient (participant who is NOT the sender)
      const participants = Object.keys(conversationData.participants);
      const recipientID = participants.find((uid) => uid !== senderID);

      if (!recipientID) {
        console.log("[onMessageCreated] No recipient found (self-send or single participant)");
        return null;
      }

      // Get recipient's FCM token from Firestore
      const recipientDoc = await admin.firestore()
        .collection("users")
        .doc(recipientID)
        .get();

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
      const senderDoc = await admin.firestore()
        .collection("users")
        .doc(senderID)
        .get();
      const senderDisplayName = senderDoc.exists ?
        senderDoc.data()?.displayName :
        "Unknown";

      // Truncate message text to 100 characters
      const truncatedText = messageText.length > 100 ?
        messageText.substring(0, 97) + "..." :
        messageText;

      // Build FCM notification payload
      const payload: admin.messaging.Message = {
        notification: {
          title: senderDisplayName,
          body: truncatedText,
        },
        data: {
          conversationID: conversationID,
          messageID: messageID,
          type: "new_message",
          senderID: senderID,
          timestamp: String(messageData.serverTimestamp || Date.now()),
        },
        token: fcmToken,
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      // Send FCM notification
      const response = await admin.messaging().send(payload);

      console.log(`[onMessageCreated] Successfully sent notification to ${recipientID}: ${response}`);

      return response;
    } catch (error) {
      console.error("[onMessageCreated] Error sending notification:", error);
      throw error; // Re-throw to mark function as failed
    }
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
