const {createPaginatedListFunction} = require("./paginated_list");

exports.getUsersPage = createPaginatedListFunction({
  collection: "users",
  orderByField: "createdAt",
  searchField: "email",
});

exports.getProductsPage = createPaginatedListFunction({
  collection: "products",
  orderByField: "createdAt",
  searchField: "title",
});

exports.getProductsPageByScore = createPaginatedListFunction({
  collection: "products",
  orderByField: "score",
  searchField: "title",
});

exports.getCategoriesPage = createPaginatedListFunction({
  collection: "categories",
  orderByField: "createdAt",
  searchField: "name",
});

exports.getPromosPage = createPaginatedListFunction({
  collection: "promos",
  orderByField: "createdAt",
  searchField: "title",
});

exports.getOrdersPage = createPaginatedListFunction({
  collection: "orders",
  orderByField: "createdAt",
  searchField: "shippingAddress.email",
});
