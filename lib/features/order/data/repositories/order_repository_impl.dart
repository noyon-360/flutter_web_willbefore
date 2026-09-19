import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order_entities.dart';
import '../../domain/repositories/order_repositry.dart';
import '../sources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  OrderRepositoryImpl(this._remoteDataSource, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  // @override
  // Future<Order> createOrder({
  //   required List<CartItem> items,
  //   required ShippingAddress shippingAddress,
  //   required String paymentIntentId,
  // }) async {
  //   final user = _auth.currentUser;
  //   if (user == null) {
  //     throw Exception('User not authenticated');
  //   }

  //   final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
  //   final tax = subtotal * 0.0; // No tax for now
  //   final total = subtotal + tax;

  //   final order = Order(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     userId: user.uid,
  //     items: items,
  //     shippingAddress: shippingAddress,
  //     subtotal: subtotal,
  //     tax: tax,
  //     total: total,
  //     status: OrderStatus.pending, // Default status is pending
  //     createdAt: DateTime.now(),
  //     // estimatedDelivery: DateTime.now().add(const Duration(days: 7)),
  //     paymentIntentId: paymentIntentId,
  //     updatedAt: DateTime.now(),
  //     // orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}', updatedAt: null,
  //   );

  //   await _remoteDataSource.createOrder(order);
  //   return order;
  // }

  @override
  Future<List<Order>> getUserOrders([String? userId]) async {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) {
      return [];
    }

    return _remoteDataSource.getUserOrders(targetUserId);
  }

  @override
  Stream<List<Order>> getUserOrdersStream([String? userId]) {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) {
      return Stream.value([]);
    }

    return _remoteDataSource.getUserOrdersStream(targetUserId).map((orders) {
      return orders.where((order) => order.userId == targetUserId).toList();
    });
  }

  @override
  Future<List<Order>> getAllOrders() async {
    return await _remoteDataSource.getAllOrders();
  }

  @override
  Stream<List<Order>> getAllOrdersStream() {
    return _remoteDataSource.getAllOrdersStream();
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _remoteDataSource.updateOrderStatus(orderId, status);
  }

  @override
  Future<void> fulfillOrder({
    required String orderId,
    required String trackingNumber,
    required String trackingUrl,
    required String labelUrl,
    required String shippoTransactionId,
  }) async {
    await _remoteDataSource.fulfillOrder(
      orderId: orderId,
      trackingNumber: trackingNumber,
      trackingUrl: trackingUrl,
      labelUrl: labelUrl,
      shippoTransactionId: shippoTransactionId,
    );
  }

  @override
  Future<void> updateShippingAddress(
    String orderId,
    ShippingAddress shippingAddress,
  ) async {
    await _remoteDataSource.updateShippingAddress(orderId, shippingAddress);
  }

  @override
  Future<void> resetFulfillment(String orderId) async {
    await _remoteDataSource.resetFulfillment(orderId);
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    return await _remoteDataSource.getOrderById(orderId);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrderRepositoryImpl(remoteDataSource);
});
