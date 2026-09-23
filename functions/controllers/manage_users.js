const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

const STAFF_ROLES = ["admin", "super_admin"];
const ASSIGNABLE_ROLES = ["admin", "user"];

/**
 * Reads a user's role from their Firestore users/{uid} doc.
 * @param {string} uid The user's Firebase Auth uid.
 * @return {Promise<string|null>} The user's role, or null if not found.
 */
async function getRole(uid) {
  const snap = await admin.firestore().collection("users").doc(uid).get();
  return snap.exists ? snap.data().role : null;
}

// Only a super admin can promote/demote between admin and user. Super admin
// accounts themselves are never changed through this function.
exports.updateUserRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const data = request.data || {};
  const userId = data.userId;
  const role = data.role;

  if (!userId || !ASSIGNABLE_ROLES.includes(role)) {
    throw new HttpsError(
        "invalid-argument",
        "A valid userId and role ('admin' or 'user') are required.",
    );
  }
  if (userId === request.auth.uid) {
    throw new HttpsError(
        "permission-denied",
        "You cannot change your own role.",
    );
  }

  const callerRole = await getRole(request.auth.uid);
  if (callerRole !== "super_admin") {
    throw new HttpsError(
        "permission-denied",
        "Only a super admin can change user roles.",
    );
  }

  const targetRef = admin.firestore().collection("users").doc(userId);
  const targetSnap = await targetRef.get();
  if (!targetSnap.exists) {
    throw new HttpsError("not-found", "User not found.");
  }
  if (targetSnap.data().role === "super_admin") {
    throw new HttpsError(
        "permission-denied",
        "Super admin roles cannot be changed here.",
    );
  }

  await targetRef.update({
    role: role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {success: true};
});

// Admins may only delete regular users; super admins may delete admins and
// users, but never other super admins (and never themselves).
exports.deleteAppUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  const userId = (request.data || {}).userId;
  if (!userId) {
    throw new HttpsError("invalid-argument", "userId is required.");
  }
  if (userId === request.auth.uid) {
    throw new HttpsError(
        "permission-denied",
        "You cannot delete your own account.",
    );
  }

  const callerRole = await getRole(request.auth.uid);
  if (!STAFF_ROLES.includes(callerRole)) {
    throw new HttpsError(
        "permission-denied",
        "Only admins can delete users.",
    );
  }

  const targetRef = admin.firestore().collection("users").doc(userId);
  const targetSnap = await targetRef.get();
  if (!targetSnap.exists) {
    throw new HttpsError("not-found", "User not found.");
  }

  const targetRole = targetSnap.data().role;
  if (targetRole === "super_admin") {
    throw new HttpsError(
        "permission-denied",
        "Super admin accounts cannot be deleted here.",
    );
  }
  if (callerRole === "admin" && targetRole !== "user") {
    throw new HttpsError(
        "permission-denied",
        "Admins can only delete regular users.",
    );
  }

  await targetRef.delete();
  try {
    await admin.auth().deleteUser(userId);
  } catch (error) {
    // "already gone" is fine - that's the outcome we wanted anyway. Any
    // other failure (permissions, network, quota, ...) must NOT be
    // swallowed: it leaves a live Auth account for a user whose Firestore
    // profile no longer exists, which breaks role/profile lookups for
    // that account everywhere else in the app. Log it loudly and tell the
    // caller the deletion was only partial so it can be retried/escalated.
    if (error.code !== "auth/user-not-found") {
      logger.error(
          `deleteAppUser: failed to delete Auth account ${userId} ` +
          `after removing its Firestore profile`,
          error,
      );
      throw new HttpsError(
          "internal",
          "User profile was deleted, but the login account could not be " +
          "removed. Please try again or contact support.",
      );
    }
  }
  return {success: true};
});
