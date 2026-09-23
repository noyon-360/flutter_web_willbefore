class DashboardStats {
  final double totalRevenue;
  final int totalLiveProducts;
  final int totalUsers;

  DashboardStats({
    required this.totalRevenue,
    required this.totalLiveProducts,
    required this.totalUsers,
  });
}

class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}

// class Product {
//   final String id;
//   final String title;
//   final double actualPrice;
//   final double discountPrice;
//   final int stock;
//   final String category;
//   final String description;
//   final List<String> images;
//   final List<String> sizes;
//   final List<String> colors;
//   final DateTime createdAt;

//   Product({
//     required this.id,
//     required this.title,
//     required this.actualPrice,
//     required this.discountPrice,
//     required this.stock,
//     required this.category,
//     required this.description,
//     required this.images,
//     required this.sizes,
//     required this.colors,
//     required this.createdAt,
//   });
// }

class Promo {
  final String id;
  final String title;
  final String code;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;

  Promo({
    required this.id,
    required this.title,
    required this.code,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
  });
}

enum NavigationItem {
  dashboard,
  categories,
  productList,
  order,
  promo,
  userProfile,
  settings,
  messages,
  // notifications,
}