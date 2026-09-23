const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {computeScore} = require("./score_config");

// Keeps a product's ratingSum/ratingCount/averageRating/score in sync
// whenever a review is created, edited, or deleted. Reviews are low
// frequency (one write per user per product, ever), so a plain Firestore
// transaction directly on the product doc is safe here - no sharding
// needed, unlike the high-frequency view/cart/order counters.
exports.onProductReviewWritten = onDocumentWritten(
    "productReviews/{reviewId}",
    async (event) => {
      const before = event.data.before.exists ?
        event.data.before.data() : null;
      const after = event.data.after.exists ? event.data.after.data() : null;
      const productId = (after || before || {}).productId;
      if (!productId) {
        logger.warn(`onProductReviewWritten: missing productId on ${
          event.params.reviewId}`);
        return;
      }

      const oldRating = before ? Number(before.rating) || 0 : 0;
      const newRating = after ? Number(after.rating) || 0 : 0;
      const wasCounted = Boolean(before);
      const isCounted = Boolean(after);

      if (wasCounted === isCounted && oldRating === newRating) {
        // No rating-relevant change (e.g. a reviewText-only edit).
        return;
      }

      const db = admin.firestore();
      const productRef = db.collection("products").doc(productId);

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(productRef);
        if (!snap.exists) {
          logger.warn(`onProductReviewWritten: product ${
            productId} not found`);
          return;
        }
        const data = snap.data();
        let ratingSum = Number(data.ratingSum) || 0;
        let ratingCount = Number(data.ratingCount) || 0;

        if (wasCounted) {
          ratingSum -= oldRating;
          ratingCount -= 1;
        }
        if (isCounted) {
          ratingSum += newRating;
          ratingCount += 1;
        }
        ratingCount = Math.max(0, ratingCount);
        const averageRating = ratingCount > 0 ? ratingSum / ratingCount : 0;

        const score = computeScore({
          averageRating,
          ratingCount,
          orderCount: Number(data.orderCount) || 0,
          cartAddCount: Number(data.cartAddCount) || 0,
          viewCount: Number(data.viewCount) || 0,
        });

        tx.update(productRef, {
          ratingSum,
          ratingCount,
          averageRating,
          score,
          scoreUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    },
);
