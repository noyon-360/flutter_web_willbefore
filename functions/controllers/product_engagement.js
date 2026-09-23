const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {SHARD_COUNT} = require("./score_config");

/**
 * Increments one field of a random shard under a product's counterShards
 * subcollection. Spreading writes across SHARD_COUNT documents keeps any
 * single product well under Firestore's per-document sustained write-rate
 * limit even under heavy concurrent traffic, since the increment never
 * touches the product document itself.
 * @param {string} productId The product being credited.
 * @param {"views"|"cartAdds"|"orders"} field Which counter to increment.
 * @param {number} [amount] How much to increment by. Defaults to 1.
 * @return {Promise<void>}
 */
async function incrementShard(productId, field, amount = 1) {
  const shardId = String(Math.floor(Math.random() * SHARD_COUNT));
  await admin.firestore()
      .collection("products").doc(productId)
      .collection("counterShards").doc(shardId)
      .set({[field]: admin.firestore.FieldValue.increment(amount)},
          {merge: true});
}

// Fires exactly once per unique (product, user) pair: the client writes
// products/{productId}/viewEvents/{userId} as a plain `set()`, and
// Firestore rules reject the write outright if that doc already exists
// (allow create: if !exists(...)), so a repeat view never reaches here at
// all - this trigger only ever sees genuinely first-time views.
exports.onProductViewMarkerCreated = onDocumentCreated(
    "products/{productId}/viewEvents/{userId}",
    async (event) => {
      const {productId} = event.params;
      await incrementShard(productId, "views");
    },
);

// Fires when a new cart line item is created (not on quantity updates -
// counts "was this product added to a cart", not total units added, which
// is simpler and less gameable).
exports.onCartItemCreated = onDocumentCreated(
    "users/{userId}/cartItems/{itemId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const {productId} = snap.data();
      if (!productId) return;
      await incrementShard(productId, "cartAdds");
    },
);

// Fires when a new order is created. Credits each distinct product in the
// order once (order-count semantic, not unit-quantity) - only the
// top-level orders/{orderId} doc is watched, not its mirror under
// users/{uid}/orders/{orderId}, since both are written in the same batch
// and would otherwise double-count.
exports.onOrderCreated = onDocumentCreated(
    "orders/{orderId}",
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      const items = snap.data().items;
      if (!Array.isArray(items)) return;

      const productIds = new Set(
          items.map((item) => item.productId).filter(Boolean),
      );
      await Promise.all(
          Array.from(productIds).map((productId) =>
            incrementShard(productId, "orders")),
      );
    },
);

module.exports.incrementShard = incrementShard;
