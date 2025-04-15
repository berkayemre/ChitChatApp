/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
require("dotenv").config();
const functions = require('firebase-functions/v1');

// The Firebase Admin SDK to access Firestore.
const admin = require("firebase-admin");
const { StreamChat } = require("stream-chat");
admin.initializeApp();
const logger = require("firebase-functions/logger");

const channelMessageRef = "/channel-messages/{channelId}/{messageId}";

exports.sendNotificationsForMessages = functions.database
.ref(channelMessageRef)
.onCreate(async (snapshot, context) => {
  const data = snapshot.val();
  const textMessage = data.text;
  const senderName = data.channelNameAtSend;
  const chatPartnerFCMTokens = data.chatPartnerFCMTokens;
  const messageType = data.type;

  let notificationMessage = textMessage;

  if(messageType === "photo") {
    notificationMessage = "Sent a Photo Message";
  } else if (messageType === "video") {
    notificationMessage = "Sent a Video Message";
  } else if (messageType === "audio") {
    notificationMessage = "Sent a Voice Message";
  }

  for(const fcmToken of chatPartnerFCMTokens) {
    await sendPushNotifications(notificationMessage, senderName, fcmToken);
  }
});



exports.sendMessageReactionNotifications = functions.https.onCall(
  async (data, context) => {
    const fcmToken = data.fcmToken;
    const channelNameAtSend = data.channelNameAtSend;
    const notificationMessage = data.notificationMessage;
    await sendPushNotifications(notificationMessage, channelNameAtSend, fcmToken);
  }
);

listenForNewMessages = functions
.database
.ref(channelMessageRef)
.onCreate(async (snapshot, context) => {
 const data = snapshot.val();
 const channelId = context.params.channelId;
 const message = data["text"];
 const ownerUid = data["ownerUid"];

 const messageSenderSnapshot = await admin
 .database()
 .ref("/users/" + ownerUid)
 .once("value");

 const messageSenderDict = messageSenderSnapshot.val();
 const senderName = messageSenderDict["username"];
 await getChannelMembers(channelId, message, senderName);
});




 async function getChannelMembers(channelId, message, senderName) {
  
  const channelSnapshot = await admin
  .database()
  .ref("/channels/" + channelId)
  .once("value");

  const channelDict = channelSnapshot.val();
  const membersUids = channelDict["membersUids"];

  for (const userId of membersUids) {
    await getUserFcmToken(message, userId, senderName);
  }
 }

 async function getUserFcmToken(message, userId, senderName) {
  
  const userSnapshot = await admin
  .database()
  .ref("/users/" + userId)
  .once("value");

  const userDict = userSnapshot.val();
  const fcmToken = userDict["fcmToken"];
  await sendPushNotifications(message, senderName, fcmToken);
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
    console.info("Successfully sent message:", message);
  } catch (error) {
    console.error("Error sending message:", error);
  }
}


const apiKey = process.env.APIKEY;
const apiSecret = process.env.API_SECRET;

const streamClient = StreamChat.getInstance(apiKey, apiSecret);

exports.createStreamUser = functions.auth.user()
.onCreate(async(user) => {
  logger.log("Firebase user was created", user);

  const response = await streamClient.upsertUser({
    id: user.uid,
    name: user.displayName,
    email: user.email,
    image: user.photoURL,
  });
  logger.log("Stream user was created", response);
  return response;
});

exports.deleteStreamUser = functions.auth.user()
.onDelete(async(user) => {
  logger.log("Firebase user was deleted", user);
  const response = await streamClient.deleteUser(user.uid);
  logger.log("Stream user was deleted", response);
  return response;
});

exports.getStreamUserToken = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The functions must be called while authenticated"
    );
  } else {
    try {
      return streamClient.createToken(context.auth.uid, undefined, Math.floor(new Date().getTime() / 1000));
    } catch(err) {
      console.error(`Unable to get user token with ID ${context.auth.uid} on Stream. Error ${err}`);
      throw new functions.https.HttpsError(
        "aborted",
        "Could not get Stream user"
      );
    }
  }
});


exports.revokeStreamUserToken = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The functions must be called while authenticated"
    );
  } else {
    try {
      return streamClient.revokeUserToken(context.auth.uid);
    } catch(err) {
      console.error(`Unable to revoke user token with ID ${context.auth.uid} on Stream. Error ${err}`);
      throw new functions.https.HttpsError(
        "aborted",
        "Could not get Stream user"
      );
    }
  }
});