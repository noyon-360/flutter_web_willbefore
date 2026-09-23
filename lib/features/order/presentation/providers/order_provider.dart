import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../data/sources/order_remote_data_source.dart';
import '../../data/sources/user_remote_data_source.dart';
import '../../domain/entities/order_entities.dart';
import '../../domain/repositories/order_repositry.dart';
import '../../domain/repositories/user_repository.dart';

class AdminOrderState {
  final List<Order> orders;
  final int usersCount;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchTerm;

  const AdminOrderState({
    this.orders = const [],
    this.usersCount = 0,
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchTerm = '',
  });

  AdminOrderState copyWith({
    List<Order>? orders,
    int? usersCount,
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchTerm,
  }) {
    return AdminOrderState(
      orders: orders ?? this.orders,
      usersCount: usersCount ?? this.usersCount,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: errorMessage ?? this.errorMessage,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

class AdminOrderNotifier extends StateNotifier<AdminOrderState> {
  final OrderRepository _orderRepository;
  final UserProfileRepository _userRepository;

  AdminOrderNotifier(this._orderRepository, this._userRepository)
    : super(const AdminOrderState());

  Future<void> fetchAllOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final usersCount = await _userRepository.getActiveUsersCount();
      final page = await _orderRepository.getOrdersPage(
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      state = AdminOrderState(
        orders: page.items,
        usersCount: usersCount,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        searchTerm: state.searchTerm,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _orderRepository.getOrdersPage(
        cursor: state.nextCursor,
        searchTerm: state.searchTerm.isEmpty ? null : state.searchTerm,
      );
      state = state.copyWith(
        orders: [...state.orders, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  Future<void> search(String term) async {
    state = AdminOrderState(searchTerm: term, isLoading: true);
    await fetchAllOrders();
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);

    try {
      await _orderRepository.updateOrderStatus(orderId, newStatus);

      // Update the order in the local state
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: newStatus);
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders, isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }

  // Inside AdminOrderNotifier
  Future<bool> fulfillOrder({
    required String orderId,
    required String trackingNumber,
    required String trackingUrl,
    required String labelUrl,
    required String shippoTransactionId,
  }) async {
    state = state.copyWith(isUpdating: true);
    try {
      await _orderRepository.fulfillOrder(
        orderId: orderId,
        trackingNumber: trackingNumber,
        trackingUrl: trackingUrl,
        labelUrl: labelUrl,
        shippoTransactionId: shippoTransactionId,
      );

      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) {
          return o.copyWith(
            status: OrderStatus.shipped,
            trackingNumber: trackingNumber,
            trackingUrl: trackingUrl,
            labelUrl: labelUrl,
            shippoTransactionId: shippoTransactionId,
            shippedAt: DateTime.now(),
          );
        }
        return o;
      }).toList();

      state = state.copyWith(orders: updatedOrders, isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateShippingAddress(
    String orderId,
    ShippingAddress shippingAddress,
  ) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      await _orderRepository.updateShippingAddress(orderId, shippingAddress);

      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(shippingAddress: shippingAddress);
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders, isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }

  // Clears a previously purchased label/tracking info so the order can be
  // re-fulfilled with a corrected address or a different rate tier.
  // Voiding the Shippo transaction itself is done separately via
  // AdminShippoService.refundLabel before calling this.
  Future<bool> resetFulfillment(String orderId) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      await _orderRepository.resetFulfillment(orderId);

      // Order.copyWith treats null args as "keep existing value", so the
      // fields being cleared must be rebuilt explicitly instead.
      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) {
          return Order(
            id: o.id,
            userId: o.userId,
            items: o.items,
            shippingAddress: o.shippingAddress,
            subtotal: o.subtotal,
            tax: o.tax,
            total: o.total,
            status: OrderStatus.confirmed,
            paymentIntentId: o.paymentIntentId,
            createdAt: o.createdAt,
            updatedAt: DateTime.now(),
            estimatedDelivery: o.estimatedDelivery,
            trackingNumber: null,
            trackingUrl: null,
            shippoTransactionId: null,
            labelUrl: null,
            shippedAt: null,
          );
        }
        return o;
      }).toList();

      state = state.copyWith(orders: updatedOrders, isUpdating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final adminOrderProvider =
    StateNotifierProvider<AdminOrderNotifier, AdminOrderState>((ref) {
      final orderRemoteDataSource = ref.read(orderRemoteDataSourceProvider);
      final orderRepository = OrderRepositoryImpl(orderRemoteDataSource);

      final userRemoteDataSource = ref.read(userRemoteDataSourceProvider);
      final userRepository = UserRepositoryImpl(userRemoteDataSource);

      return AdminOrderNotifier(orderRepository, userRepository);
    });

/// Orders placed by a single user, for the admin's user-detail view.
final userOrdersProvider = FutureProvider.family<List<Order>, String>((
  ref,
  userId,
) {
  final orderRemoteDataSource = ref.read(orderRemoteDataSourceProvider);
  final orderRepository = OrderRepositoryImpl(orderRemoteDataSource);
  return orderRepository.getUserOrders(userId);
});

/// Items currently sitting in a user's cart (added but not checked out
/// into an order yet), for the admin's user-detail view. Mirrors the
/// buyer app's storage at `users/{userId}/cartItems`.
final userCartItemsProvider = FutureProvider.family<List<CartItem>, String>((
  ref,
  userId,
) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('cartItems')
      .orderBy('createdAt', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => CartItemModel.fromMap(doc.data()).toCartItem())
      .toList();
});
