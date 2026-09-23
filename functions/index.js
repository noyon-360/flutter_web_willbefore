const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");

// const { startShipment } = require("./api");
setGlobalOptions({maxInstances: 10});
admin.initializeApp({
  credential: admin.credential.cert("./serviceAccountKey.json"),
});

exports.startShipment = require("./controllers/start_shipment").startShipment;
exports.inviteUser = require("./controllers/invite_user").inviteUser;
exports.sendProductNotification =
  require("./controllers/on_new_product").sendProductNotification;
exports.sendSubscriptionNotification =
  require("./controllers/subscription").sendSubscriptionNotification;

const paginatedLists = require("./controllers/paginated_lists");
exports.getUsersPage = paginatedLists.getUsersPage;
exports.getProductsPage = paginatedLists.getProductsPage;
exports.getCategoriesPage = paginatedLists.getCategoriesPage;
exports.getPromosPage = paginatedLists.getPromosPage;
exports.getOrdersPage = paginatedLists.getOrdersPage;

