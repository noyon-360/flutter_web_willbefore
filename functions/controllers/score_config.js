/**
 * Shared configuration and math for the product ranking score. Every
 * function that touches a product's `score` field (the review trigger,
 * the counter-shard rollup, and the one-time backfill) imports from here
 * so the formula only ever lives in one place.
 */

// Number of shards per counter type (views/cartAdds/orders) under each
// product's `counterShards` subcollection. Spreads concurrent writes for
// the same product across this many documents to stay under Firestore's
// per-document sustained write-rate limit.
const SHARD_COUNT = 10;

// Bayesian shrinkage prior for the average rating: a product needs roughly
// this many ratings before its raw average outweighs the prior mean.
const RATING_PRIOR_MEAN = 3.5;
const RATING_PRIOR_CONFIDENCE = 10;

// Relative weights of each signal in the final score. Illustrative
// defaults - revisit once real traffic/order data exists.
const SCORE_WEIGHTS = {
  rating: 50,
  orders: 30,
  cartAdds: 15,
  views: 5,
};

/**
 * Bayesian-shrunk average rating. Pulls a product's raw average toward the
 * platform-wide prior mean until it has accumulated enough ratings to be
 * trusted on its own - stops a single 5-star review from outranking a
 * product with hundreds of reviews averaging slightly lower.
 * @param {number} averageRating The product's raw average rating (0 if
 *   ratingCount is 0).
 * @param {number} ratingCount The number of ratings behind that average.
 * @return {number} The shrunk rating estimate.
 */
function bayesianRating(averageRating, ratingCount) {
  const count = Math.max(0, ratingCount);
  return (
    (RATING_PRIOR_CONFIDENCE * RATING_PRIOR_MEAN + count * averageRating) /
    (RATING_PRIOR_CONFIDENCE + count)
  );
}

/**
 * Computes the materialized ranking `score` field for a product from its
 * current aggregate signals.
 * @param {object} signals
 * @param {number} signals.averageRating Raw average rating (0 if none).
 * @param {number} signals.ratingCount Number of ratings.
 * @param {number} signals.orderCount Number of orders containing the
 *   product.
 * @param {number} signals.cartAddCount Number of times added to a cart.
 * @param {number} signals.viewCount Number of unique-user views.
 * @return {number} The computed score.
 */
function computeScore({
  averageRating = 0,
  ratingCount = 0,
  orderCount = 0,
  cartAddCount = 0,
  viewCount = 0,
}) {
  return (
    SCORE_WEIGHTS.rating * bayesianRating(averageRating, ratingCount) +
    SCORE_WEIGHTS.orders * Math.log10(1 + Math.max(0, orderCount)) +
    SCORE_WEIGHTS.cartAdds * Math.log10(1 + Math.max(0, cartAddCount)) +
    SCORE_WEIGHTS.views * Math.log10(1 + Math.max(0, viewCount))
  );
}

module.exports = {
  SHARD_COUNT,
  RATING_PRIOR_MEAN,
  RATING_PRIOR_CONFIDENCE,
  SCORE_WEIGHTS,
  bayesianRating,
  computeScore,
};
