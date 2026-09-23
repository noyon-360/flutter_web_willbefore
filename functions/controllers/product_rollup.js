const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {computeScore} = require("./score_config");

const ROLLUP_BATCH_SIZE = 200;
const WRITE_BATCH_SIZE = 500;

/**
 * Sums the SHARD_COUNT counterShards docs under a single product into
 * totals for views/cartAdds/orders.
 * @param {FirebaseFirestore.DocumentReference} productRef The product doc.
 * @return {Promise<{views: number, cartAdds: number, orders: number}>}
 */
async function sumShards(productRef) {
  const shardsSnap = await productRef.collection("counterShards").get();
  const totals = {views: 0, cartAdds: 0, orders: 0};
  shardsSnap.docs.forEach((doc) => {
    const data = doc.data();
    totals.views += Number(data.views) || 0;
    totals.cartAdds += Number(data.cartAdds) || 0;
    totals.orders += Number(data.orders) || 0;
  });
  return totals;
}

/**
 * Rolls up counter shards and recomputes `score` for one page of products,
 * writing the results in batches. Shared by both the scheduled job and the
 * one-time backfill callable.
 * @param {FirebaseFirestore.Firestore} db Firestore instance.
 * @return {Promise<number>} Number of products processed.
 */
async function rollupAllProducts(db) {
  let processed = 0;
  let cursor = null;

  for (;;) {
    let query = db.collection("products")
        .orderBy("__name__")
        .limit(ROLLUP_BATCH_SIZE);
    if (cursor) query = query.startAfter(cursor);

    // eslint-disable-next-line no-await-in-loop
    const pageSnap = await query.get();
    if (pageSnap.empty) break;

    // eslint-disable-next-line no-await-in-loop
    const shardTotals = await Promise.all(
        pageSnap.docs.map((doc) => sumShards(doc.ref)),
    );

    let batch = db.batch();
    let opsInBatch = 0;
    for (let i = 0; i < pageSnap.docs.length; i++) {
      const doc = pageSnap.docs[i];
      const data = doc.data();
      const {views, cartAdds, orders} = shardTotals[i];
      const score = computeScore({
        averageRating: Number(data.averageRating) || 0,
        ratingCount: Number(data.ratingCount) || 0,
        orderCount: orders,
        cartAddCount: cartAdds,
        viewCount: views,
      });

      batch.update(doc.ref, {
        viewCount: views,
        cartAddCount: cartAdds,
        orderCount: orders,
        score,
        scoreUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      opsInBatch++;

      if (opsInBatch === WRITE_BATCH_SIZE) {
        // eslint-disable-next-line no-await-in-loop
        await batch.commit();
        batch = db.batch();
        opsInBatch = 0;
      }
    }
    if (opsInBatch > 0) {
      // eslint-disable-next-line no-await-in-loop
      await batch.commit();
    }

    processed += pageSnap.docs.length;
    cursor = pageSnap.docs[pageSnap.docs.length - 1];
    if (pageSnap.docs.length < ROLLUP_BATCH_SIZE) break;
  }

  return processed;
}

// Every product's viewCount/cartAddCount/orderCount/score are materialized
// on a timer rather than on every individual view/cart-add/order event -
// updating them per-event would recreate the exact hot-document
// contention the shard pattern exists to avoid. A 10-minute lag between a
// real-world event and its reflection in the sort order is an accepted
// trade-off at this scale.
exports.rollupProductAggregates = onSchedule("every 10 minutes", async () => {
  const db = admin.firestore();
  const processed = await rollupAllProducts(db);
  logger.info(`rollupProductAggregates: processed ${processed} products`);
});

// One-time admin-triggered backfill. Firestore excludes any document
// missing the `orderBy` field from query results entirely, so without
// this, every product that predates this feature would silently vanish
// from any score-sorted list/query. Safe to re-run - it's idempotent.
exports.backfillProductAggregates = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in");
  }
  const db = admin.firestore();
  const callerSnap = await db.collection("users")
      .doc(request.auth.uid).get();
  const callerRole = callerSnap.exists ? callerSnap.data().role : null;
  if (callerRole !== "admin" && callerRole !== "super_admin") {
    throw new HttpsError(
        "permission-denied",
        "Only admins can run the backfill",
    );
  }

  let processed = 0;
  let cursor = null;
  for (;;) {
    let query = db.collection("products")
        .orderBy("__name__")
        .limit(WRITE_BATCH_SIZE);
    if (cursor) query = query.startAfter(cursor);

    // eslint-disable-next-line no-await-in-loop
    const pageSnap = await query.get();
    if (pageSnap.empty) break;

    const batch = db.batch();
    pageSnap.docs.forEach((doc) => {
      const data = doc.data();
      batch.set(doc.ref, {
        viewCount: data.viewCount || 0,
        cartAddCount: data.cartAddCount || 0,
        orderCount: data.orderCount || 0,
        ratingSum: data.ratingSum || 0,
        ratingCount: data.ratingCount || 0,
        averageRating: data.averageRating || 0,
        score: data.score || 0,
      }, {merge: true});
    });
    // eslint-disable-next-line no-await-in-loop
    await batch.commit();

    processed += pageSnap.docs.length;
    cursor = pageSnap.docs[pageSnap.docs.length - 1];
    if (pageSnap.docs.length < WRITE_BATCH_SIZE) break;
  }

  logger.info(`backfillProductAggregates: defaulted ${processed} products`);
  return {processed};
});
