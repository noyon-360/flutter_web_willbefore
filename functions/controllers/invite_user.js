const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const ASSIGNABLE_ROLES = ["admin", "user"];
const STAFF_ROLES = ["admin", "super_admin"];

exports.inviteUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must be logged in to invite users.",
    );
  }

  const data = request.data || {};
  const email = typeof data.email === "string" ? data.email.trim() : "";
  const name = typeof data.name === "string" ? data.name.trim() : null;
  const requestedRole = ASSIGNABLE_ROLES.includes(data.role) ?
    data.role : "user";

  if (!email) {
    throw new HttpsError("invalid-argument", "Email is required.");
  }

  const db = admin.firestore();
  const callerSnap = await db.collection("users").doc(request.auth.uid).get();
  const callerRole = callerSnap.exists ? callerSnap.data().role : null;

  if (!STAFF_ROLES.includes(callerRole)) {
    throw new HttpsError(
        "permission-denied",
        "Only admins can invite new users.",
    );
  }
  if (requestedRole === "admin" && callerRole !== "super_admin") {
    throw new HttpsError(
        "permission-denied",
        "Only a super admin can invite new admins.",
    );
  }

  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      // No password is set here - the invited user sets their own via the
      // password-reset email the client sends right after this succeeds.
      displayName: name || undefined,
      // A staff member is creating and vouching for this account directly,
      // and no email service is configured to send a verification link, so
      // there is no way for the invited user to otherwise verify it.
      emailVerified: true,
    });

    await db.collection("users").doc(userRecord.uid).set({
      email: email,
      name: name,
      displayName: name,
      role: requestedRole,
      isActive: true,
      isEmailVerified: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {success: true, uid: userRecord.uid};
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "This email is already in use.");
    }
    throw new HttpsError("unknown", error.message);
  }
});
