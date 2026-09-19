import '../entities/order_entities.dart';

abstract class OrderRepository {
  // Future<Order> createOrder({
  //   required List<CartItem> items,
  //   required ShippingAddress shippingAddress,
  //   required String paymentIntentId,
  // });

  Future<List<Order>> getUserOrders([String? userId]);
  Stream<List<Order>> getUserOrdersStream([String? userId]);
  Future<List<Order>> getAllOrders();
  Stream<List<Order>> getAllOrdersStream();
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> fulfillOrder({
    required String orderId,
    required String trackingNumber,
    required String trackingUrl,
    required String labelUrl,
    required String shippoTransactionId,
  });
  Future<void> updateShippingAddress(
    String orderId,
    ShippingAddress shippingAddress,
  );
  Future<void> resetFulfillment(String orderId);
  Future<Order?> getOrderById(String orderId);
}
