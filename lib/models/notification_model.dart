import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  new_product,
  orderShipped,
  orderRefunded,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final NotificationType type;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final String? orderId;
  final String? trackingNumber;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
    required this.type,
    this.imageUrl,
    this.metadata,
    this.orderId,
    this.trackingNumber,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      type: _parseType(data['type']),
      imageUrl: data['imageUrl'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      orderId: data['orderId'],
      trackingNumber: data['tracking_number'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'read': read,
      'type': type.name,
      'imageUrl': imageUrl,
      'metadata': metadata,
      if (orderId != null) 'orderId': orderId,
      if (trackingNumber != null) 'tracking_number': trackingNumber,
    };
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'new_product':
        return NotificationType.new_product;
      case 'orderShipped':
      case 'order_shipped':
        return NotificationType.orderShipped;
      case 'orderRefunded':
      case 'order_refunded':
        return NotificationType.orderRefunded;
      default:
        return NotificationType.general;
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? read,
    NotificationType? type,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    String? orderId,
    String? trackingNumber,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      orderId: orderId ?? this.orderId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }
}
