/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const functions = require('firebase-functions/v1');

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
admin.initializeApp();
const logger = require("firebase-functions/logger");

const channelMessageRef = "/channel-messages/{channelId}/{messageId}"

exports.listenForNewMessages = functions
.database
.ref(channelMessageRef)
.onCreate(async (snapshot, context) => {
 const data = snapshot.val()
 const channelId = context.params.channelId
 const message = data["text"]
 const ownerUid = data["ownerUid"]

 const messageSenderSnapshot = await admin
 .database()
 .ref("/users/" + ownerUid)
 .once("value")

 const messageSenderDict = messageSenderSnapshot.val()
 const senderName = messageSenderDict["username"]
 await getChannelMembers(channelId, message, senderName)
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started


 async function getChannelMembers(channelId, message, senderName) {
  
  const channelSnapshot = await admin
  .database()
  .ref("/channels/" + channelId)
  .once("value")

  const channelDict = channelSnapshot.val()
  const membersUids = channelDict["membersUids"]

  for (const userId of membersUids) {
    await getUserFcmToken(message, userId, senderName)
  }
 }

 async function getUserFcmToken(message, userId, senderName) {
  
  const userSnapshot = await admin
  .database()
  .ref("/users/" + userId)
  .once("value")

  const userDict = userSnapshot.val()
  const fcmToken = userDict["fcmToken"]
  await sendPushNotifications(message, senderName, fcmToken)
 }

 async function sendPushNotifications(message, senderName, fcmToken) {

  const payload = {
    notification: {
      title: senderName,
      body: message,
    },

    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 5,
        }
      }
    },

    token: fcmToken,
  };

  try {
    await admin.messaging().send(payload);
    console.info("Successfully sent message:", message)
  } catch (error) {
    console.error("Error sending message:", error)
  }
 }