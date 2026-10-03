import 'package:flutter/material.dart';

import '../../../product/domain/entrity/product.dart';

enum OrderStatus {
  pending,
  confirmed,
  cancelled,
  shipped;

  /// Human-readable name (used in UI)
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Colour badge for each status
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

class ShippingAddress {
  final String fullName;
  final String phoneNumber;
  final String email; // Added email field for compatibility with OrderModel
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  const ShippingAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.email, // Made email required
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  ShippingAddress copyWith({
    String? fullName,
    String? phoneNumber,
    String? email, // Added email to copyWith
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return ShippingAddress(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email, // Added email to copyWith
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingAddress &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          phoneNumber == other.phoneNumber &&
          email == other.email && // Added email to equality check
          addressLine1 == other.addressLine1 &&
          addressLine2 == other.addressLine2 &&
          city == other.city &&
          state == other.state &&
          postalCode == other.postalCode &&
          country == other.country;

  @override
  int get hashCode =>
      fullName.hashCode ^
      phoneNumber.hashCode ^
      email.hashCode ^ // Added email to hashCode
      addressLine1.hashCode ^
      addressLine2.hashCode ^
      city.hashCode ^
      state.hashCode ^
      postalCode.hashCode ^
      country.hashCode;
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final ShippingAddress shippingAddress;
  final double subtotal;
  final double tax;
  final double total;
  final OrderStatus status;
  final String? paymentIntentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? shippoTransactionId;
  final String? labelUrl;
  final DateTime? shippedAt;
  final Map<String, dynamic>? metadata;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.paymentIntentId,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDelivery,
    this.trackingNumber,
    this.trackingUrl,
    this.shippoTransactionId,
    this.labelUrl,
    this.shippedAt,
    this.metadata,
  });

  Order copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    ShippingAddress? shippingAddress,
    double? subtotal,
    double? tax,
    double? total,
    OrderStatus? status,
    String? paymentIntentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedDelivery,
    String? trackingNumber,
    String? trackingUrl,
    String? shippoTransactionId,
    String? labelUrl,
    DateTime? shippedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      shippoTransactionId: shippoTransactionId ?? this.shippoTransactionId,
      labelUrl: labelUrl ?? this.labelUrl,
      shippedAt: shippedAt ?? this.shippedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order{id: $id, userId: $userId, total: $total, status: $status}';
  }
}

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;

  const CartItem({
    required this.id,
    required this.product,

    required this.quantity,
    this.selectedSize,
    this.selectedColor,
  });

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }

  double get totalPrice {
    return product.effectivePrice * quantity;
  }

  String get formattedTotalPrice {
    return '\$${totalPrice.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
