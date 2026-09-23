import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutx_core/flutx_core.dart'; // Added flutx_core import for DPrint logging
import '../../domain/entities/order_entities.dart';
import '../../../product/domain/entrity/product.dart';
import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final ShippingAddressModel shippingAddress;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final String? paymentIntentId;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? shippoTransactionId;
  final String? labelUrl;
  final DateTime? updatedAt;
  final DateTime? shippedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.createdAt,
    this.estimatedDelivery,
    this.paymentIntentId,
    this.trackingNumber,
    this.trackingUrl,
    this.shippoTransactionId,
    this.labelUrl,
    this.updatedAt,
    this.shippedAt,
  });

  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      userId: order.userId,
      items: order.items,
      shippingAddress: ShippingAddressModel.fromEntity(order.shippingAddress),
      subtotal: order.subtotal,
      tax: order.tax,
      total: order.total,
      status: order.status.name,
      createdAt: order.createdAt,
      estimatedDelivery: order.estimatedDelivery,
      paymentIntentId: order.paymentIntentId,
      trackingNumber: order.trackingNumber,
      trackingUrl: order.trackingUrl,
      shippoTransactionId: order.shippoTransactionId,
      labelUrl: order.labelUrl,
      updatedAt: order.updatedAt,
      shippedAt: order.shippedAt,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    DPrint.log('🐞 DEBUG: Converting document to OrderModel: $data');

    List<CartItem> items = [];
    try {
      final itemsData = data['items'] as List<dynamic>?;
      if (itemsData != null) {
        items = itemsData
            .map((item) {
              try {
                return CartItemModel.fromMap(item).toCartItem();
              } catch (e) {
                DPrint.log('🚨 Error converting cart item: $e');

                // Try one more level of nesting if CartItemModel failed
                // (In case product data is nested under 'product' or 'data' key)
                final nestedItem = item['product'] is Map
                    ? item['product'] as Map<String, dynamic>
                    : (item['data'] is Map
                          ? item['data'] as Map<String, dynamic>
                          : item);

                // Return a placeholder CartItem to prevent complete failure
                return CartItem(
                  id:
                      item['id']?.toString() ??
                      'error-${DateTime.now().millisecondsSinceEpoch}',
                  quantity: (item['quantity'] ?? 1).toInt(),
                  selectedSize: item['selectedSize']?.toString(),
                  selectedColor: item['selectedColor']?.toString(),
                  product: Product(
                    id:
                        nestedItem['id']?.toString() ??
                        nestedItem['productId']?.toString() ??
                        'unknown',
                    title:
                        nestedItem['title']?.toString() ??
                        nestedItem['name']?.toString() ??
                        nestedItem['productName']?.toString() ??
                        'Unknown Product',
                    description: nestedItem['description']?.toString() ?? '',
                    actualPrice:
                        (nestedItem['actualPrice'] ??
                                nestedItem['price'] ??
                                nestedItem['productPrice'] ??
                                0.0)
                            .toDouble(),
                    stock: 0,
                    categoryId: '',
                    sizes: [],
                    colors: [],
                    colorCodes: [],
                    imageUrls: nestedItem['imageUrls'] != null
                        ? List<String>.from(nestedItem['imageUrls'])
                        : (nestedItem['image'] != null
                              ? [nestedItem['image'].toString()]
                              : []),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
              }
            })
            .cast<CartItem>()
            .toList();
      }
      DPrint.log('✅ Successfully converted ${items.length} items');
    } catch (e) {
      DPrint.log('🚨 Error processing items array: $e');
      items = [];
    }

    DateTime? parseTimestamp(dynamic timestamp) {
      try {
        if (timestamp is Timestamp) {
          return timestamp.toDate();
        }
        if (timestamp is int) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        return null;
      } catch (e) {
        DPrint.log('🚨 Error parsing timestamp: $e');
        return null;
      }
    }

    ShippingAddressModel shippingAddress;
    try {
      final addressData = data['shippingAddress'];
      if (addressData is Map) {
        shippingAddress = ShippingAddressModel.fromMap(
          Map<String, dynamic>.from(addressData),
        );
      } else {
        DPrint.log('⚠️ Invalid shipping address data, using defaults');
        shippingAddress = ShippingAddressModel.fromMap({});
      }
    } catch (e) {
      DPrint.log('🚨 Error converting shipping address: $e');
      shippingAddress = ShippingAddressModel.fromMap({});
    }

    final orderModel = OrderModel(
      id: id,
      userId: data['userId']?.toString() ?? '',
      items: items,
      shippingAddress: shippingAddress,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      status: data['status']?.toString() ?? 'pending',
      createdAt: parseTimestamp(data['createdAt']) ?? DateTime.now(),
      estimatedDelivery: parseTimestamp(data['estimatedDelivery']),
      paymentIntentId: data['paymentIntentId']?.toString(),
      trackingNumber: data['trackingNumber']?.toString(),
      trackingUrl: data['trackingUrl']?.toString(),
      shippoTransactionId: data['shippoTransactionId']?.toString(),
      labelUrl: data['labelUrl']?.toString(),
      updatedAt: parseTimestamp(data['updatedAt']),
      shippedAt: parseTimestamp(data['shippedAt']),
    );

    DPrint.log('✅ Successfully created OrderModel with ${items.length} items');
    return orderModel;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items
          .map((item) => CartItemModel.fromCartItem(item).toMap())
          .toList(),
      'shippingAddress': shippingAddress.toMap(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'paymentIntentId': paymentIntentId,
      'trackingNumber': trackingNumber,
      'trackingUrl': trackingUrl,
      'shippoTransactionId': shippoTransactionId,
      'labelUrl': labelUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
    };
  }

  Order toEntity() {
    return Order(
      id: id,
      userId: userId,
      items: items,
      shippingAddress: shippingAddress.toEntity(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => OrderStatus.pending,
      ),
      createdAt: createdAt,
      estimatedDelivery: estimatedDelivery,
      paymentIntentId: paymentIntentId,
      trackingNumber: trackingNumber,
      trackingUrl: trackingUrl,
      shippoTransactionId: shippoTransactionId,
      labelUrl: labelUrl,
      updatedAt: updatedAt,
      shippedAt: shippedAt,
    );
  }
}

class ShippingAddressModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const ShippingAddressModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  factory ShippingAddressModel.fromEntity(ShippingAddress address) {
    return ShippingAddressModel(
      firstName: address.fullName.split(' ').first,
      lastName: address.fullName.split(' ').last,
      email: address.email,
      phoneNumber: address.phoneNumber,
      address: address.addressLine1,
      city: address.city,
      state: address.state,
      zipCode: address.postalCode,
      country: address.country,
    );
  }

  factory ShippingAddressModel.fromMap(Map<String, dynamic> map) {
    return ShippingAddressModel(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  ShippingAddress toEntity() {
    return ShippingAddress(
      phoneNumber: phoneNumber,
      city: city,
      state: state,
      country: country,
      fullName: '$firstName $lastName',
      addressLine1: address,
      postalCode: zipCode,
      email: email, // Added email field to entity conversion
    );
  }
}
