const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

const STAFF_ROLES = ["admin", "super_admin"];

/**
 * Fetches every FCM token registered under a user's fcmTokens subcollection.
 * @param {FirebaseFirestore.Firestore} db The Firestore instance.
 * @param {string} userId The user's uid.
 * @return {Promise<{tokens: string[],
 *   refs: FirebaseFirestore.DocumentReference[]}>} The tokens found, along
 *   with their doc refs (for stale-token cleanup).
 */
async function getTokensForUser(db, userId) {
  const tokensSnap = await db
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .get();

  const tokens = [];
  const refs = [];
  tokensSnap.docs.forEach((doc) => {
    const data = doc.data();
    if (data.token) {
      tokens.push(data.token);
      refs.push(doc.ref);
    }
  });
  return {tokens, refs};
}

/**
 * Removes any tokens (and their matching refs) that also belong to the
 * sender. A device can end up registered under more than one account (e.g.
 * a stale token left behind by a previous login on the same device), which
 * would otherwise let someone receive a push about their own message.
 * @param {string[]} tokens Candidate recipient tokens.
 * @param {FirebaseFirestore.DocumentReference[]} refs Matching doc refs.
 * @param {Set<string>} senderTokens Token strings belonging to the sender.
 * @return {{tokens: string[], refs: FirebaseFirestore.DocumentReference[]}}
 *   The filtered tokens/refs, with the sender's own tokens removed.
 */
function excludeSenderTokens(tokens, refs, senderTokens) {
  const filteredTokens = [];
  const filteredRefs = [];
  tokens.forEach((token, idx) => {
    if (!senderTokens.has(token)) {
      filteredTokens.push(token);
      filteredRefs.push(refs[idx]);
    }
  });
  return {tokens: filteredTokens, refs: filteredRefs};
}

/**
 * Sends a multicast FCM push and cleans up any stale/invalid tokens.
 * @param {string[]} tokens The FCM tokens to send to.
 * @param {FirebaseFirestore.DocumentReference[]} refs The matching token
 *   doc refs, used to delete stale tokens.
 * @param {{title: string, body: string, data: Object<string, string>}} msg
 *   The notification payload.
 * @return {Promise<void>}
 */
async function sendPush(tokens, refs, msg) {
  if (tokens.length === 0) return;

  const message = {
    tokens,
    notification: {
      title: msg.title,
      body: msg.body,
    },
    data: msg.data || {},
    android: {
      notification: {
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);

  const staleDeletes = [];
  response.responses.forEach((resp, idx) => {
    if (
      !resp.success &&
      resp.error &&
      (resp.error.code === "messaging/registration-token-not-registered" ||
        resp.error.code === "messaging/invalid-registration-token")
    ) {
      staleDeletes.push(refs[idx].delete());
    }
  });
  if (staleDeletes.length > 0) {
    await Promise.all(staleDeletes);
  }
}

// Fires whenever a message is added to a support chat. Notifies the other
// side of the conversation: admins get a push when the customer writes in,
// and the customer gets a push + an in-app notification doc when an admin
// replies.
exports.onChatMessageCreated = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return;

      const message = snap.data();
      const {chatId} = event.params;
      const db = admin.firestore();

      const chatSnap = await db.collection("chats").doc(chatId).get();
      if (!chatSnap.exists) {
        logger.warn(`onChatMessageCreated: chat ${chatId} not found`);
        return;
      }
      const chat = chatSnap.data();
      const preview = (message.text || "").slice(0, 120);
      const senderId = message.senderId;

      if (message.senderRole === "user") {
        // Notify every admin/super_admin device, except the sender's own.
        const usersSnap = await db
            .collection("users")
            .where("role", "in", STAFF_ROLES)
            .get();

        let tokens = [];
        let refs = [];
        for (const staffDoc of usersSnap.docs) {
          if (staffDoc.id === senderId) continue;
          const {tokens: staffTokens, refs: staffRefs} =
            // eslint-disable-next-line no-await-in-loop
            await getTokensForUser(db, staffDoc.id);
          tokens.push(...staffTokens);
          refs.push(...staffRefs);
        }

        if (senderId) {
          const {tokens: senderTokens} = await getTokensForUser(db, senderId);
          ({tokens, refs} =
            excludeSenderTokens(tokens, refs, new Set(senderTokens)));
        }

        await sendPush(tokens, refs, {
          title: chat.userName ?
            `New message from ${chat.userName}` :
            "New support message",
          body: preview,
          data: {
            type: "chat_reply",
            chatId,
          },
        });
      } else if (message.senderRole === "admin") {
        const userId = chat.userId;
        if (!userId) {
          logger.warn(`onChatMessageCreated: chat ${chatId} has no userId`);
          return;
        }

        // 1. Write an in-app notification doc, matching the existing
        // NotificationModel shape used elsewhere in the app.
        await db
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .add({
              title: "New reply from support",
              message: preview,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              read: false,
              type: "chat_reply",
              imageUrl: null,
              metadata: {chatId},
            });

        // 2. Push to the customer's devices, except the sender's own.
        let {tokens, refs} = await getTokensForUser(db, userId);
        if (senderId) {
          const {tokens: senderTokens} = await getTokensForUser(db, senderId);
          ({tokens, refs} =
            excludeSenderTokens(tokens, refs, new Set(senderTokens)));
        }
        await sendPush(tokens, refs, {
          title: "New reply from support",
          body: preview,
          data: {
            type: "chat_reply",
            chatId,
          },
        });
      }
    },
);
