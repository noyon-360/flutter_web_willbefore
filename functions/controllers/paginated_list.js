const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;

/**
 * Recursively converts Firestore Timestamps to millisecond epoch ints so
 * the response is plain JSON the Flutter client can decode without any
 * Firestore-specific parsing.
 * @param {*} value Any Firestore field value.
 * @return {*} The same value with Timestamps converted to ints.
 */
function serializeValue(value) {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }
  if (Array.isArray(value)) {
    return value.map(serializeValue);
  }
  if (value && typeof value === "object" && !(value instanceof Date)) {
    const result = {};
    for (const key of Object.keys(value)) {
      result[key] = serializeValue(value[key]);
    }
    return result;
  }
  return value;
}

/**
 * Creates a callable Cloud Function returning one page of documents from a
 * Firestore collection, with optional prefix search on a single field.
 *
 * Request data: { cursor?: string, searchTerm?: string, pageSize?: number }
 * Response: { items: object[], nextCursor: string|null, hasMore: boolean }
 *
 * @param {object} config
 * @param {string} config.collection Firestore collection name.
 * @param {string} [config.orderByField] Field used for default (non-search)
 *   ordering. Defaults to "createdAt".
 * @param {string} [config.searchField] Field used for prefix search
 *   (supports dot notation for nested fields). When a searchTerm is
 *   provided, results are ordered by this field instead.
 * @param {number} [config.pageSize] Default page size.
 * @param {boolean} [config.requireAdmin] Whether only admins may call this.
 *   Defaults to true, matching the rest of the admin dashboard's functions.
 * @return {Function} The callable Cloud Function.
 */
function createPaginatedListFunction({
  collection,
  orderByField = "createdAt",
  searchField = null,
  pageSize = DEFAULT_PAGE_SIZE,
  requireAdmin = true,
}) {
  return onCall(async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in");
    }
    if (requireAdmin) {
      const callerSnap = await admin.firestore()
          .collection("users").doc(request.auth.uid).get();
      const callerRole = callerSnap.exists ? callerSnap.data().role : null;
      if (callerRole !== "admin" && callerRole !== "super_admin") {
        throw new HttpsError(
            "permission-denied",
            "Only admins can access this data",
        );
      }
    }

    const data = request.data || {};
    const searchTerm = typeof data.searchTerm === "string" ?
      data.searchTerm.trim() : "";
    const cursor = typeof data.cursor === "string" ? data.cursor : null;
    const limit = Math.max(
        1,
        Math.min(Number(data.pageSize) || pageSize, MAX_PAGE_SIZE),
    );

    const db = admin.firestore();
    const isSearching = searchTerm.length > 0 && Boolean(searchField);

    let query = isSearching ?
      db.collection(collection)
          .orderBy(searchField)
          .startAt(searchTerm)
          .endAt(`${searchTerm}`) :
      db.collection(collection).orderBy(orderByField, "desc");

    if (cursor) {
      const cursorDoc = await db.collection(collection).doc(cursor).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    query = query.limit(limit);

    const snapshot = await query.get();
    const items = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...serializeValue(doc.data()),
    }));
    const lastDoc = snapshot.docs.length > 0 ?
      snapshot.docs[snapshot.docs.length - 1] : null;

    return {
      items,
      nextCursor: lastDoc ? lastDoc.id : null,
      hasMore: snapshot.docs.length === limit,
    };
  });
}

module.exports = {createPaginatedListFunction};
