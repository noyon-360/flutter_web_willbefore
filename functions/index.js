const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");

// const { startShipment } = require("./api");
setGlobalOptions({maxInstances: 10});
admin.initializeApp({
  credential: admin.credential.cert("./serviceAccountKey.json"),
});

exports.startShipment = require("./controllers/start_shipment").startShipment;
exports.inviteUser = require("./controllers/invite_user").inviteUser;

const manageUsers = require("./controllers/manage_users");
exports.updateUserRole = manageUsers.updateUserRole;
exports.deleteAppUser = manageUsers.deleteAppUser;

exports.sendProductNotification =
  require("./controllers/on_new_product").sendProductNotification;
exports.sendSubscriptionNotification =
  require("./controllers/subscription").sendSubscriptionNotification;

exports.onChatMessageCreated =
  require("./controllers/chat_notifications").onChatMessageCreated;

const paginatedLists = require("./controllers/paginated_lists");
exports.getUsersPage = paginatedLists.getUsersPage;
exports.getProductsPage = paginatedLists.getProductsPage;
exports.getProductsPageByScore = paginatedLists.getProductsPageByScore;
exports.getCategoriesPage = paginatedLists.getCategoriesPage;
exports.getPromosPage = paginatedLists.getPromosPage;
exports.getOrdersPage = paginatedLists.getOrdersPage;

exports.onProductReviewWritten =
  require("./controllers/product_reviews").onProductReviewWritten;

const productEngagement = require("./controllers/product_engagement");
exports.onProductViewMarkerCreated =
  productEngagement.onProductViewMarkerCreated;
exports.onCartItemCreated = productEngagement.onCartItemCreated;
exports.onOrderCreated = productEngagement.onOrderCreated;

const productRollup = require("./controllers/product_rollup");
exports.rollupProductAggregates = productRollup.rollupProductAggregates;
exports.backfillProductAggregates = productRollup.backfillProductAggregates;

