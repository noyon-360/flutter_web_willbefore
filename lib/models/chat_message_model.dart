import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatSenderRole { user, admin, bot }

enum ChatMessageType { text, autoReply, productCard, system }

class ChatMessageModel {
  final String id;
  final String senderId;
  final ChatSenderRole senderRole;
  final String text;
  final ChatMessageType type;
  final DateTime createdAt;
  final bool read;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final double? productPrice;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.type = ChatMessageType.text,
    required this.createdAt,
    this.read = false,
    this.productId,
    this.productTitle,
    this.productImage,
    this.productPrice,
  });

  bool get hasProduct => productId != null && productId!.isNotEmpty;

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderRole: _parseSenderRole(data['senderRole']),
      text: data['text'] ?? '',
      type: _parseType(data['type']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      productId: (data['productId'] as String?)?.isNotEmpty == true
          ? data['productId'] as String
          : null,
      productTitle: (data['productTitle'] as String?)?.isNotEmpty == true
          ? data['productTitle'] as String
          : null,
      productImage: (data['productImage'] as String?)?.isNotEmpty == true
          ? data['productImage'] as String
          : null,
      productPrice: (data['productPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderRole': senderRole.name,
      'text': text,
      'type': _typeToString(type),
      'createdAt': FieldValue.serverTimestamp(),
      'read': read,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'productPrice': productPrice,
    };
  }

  static ChatSenderRole _parseSenderRole(String? role) {
    switch (role) {
      case 'admin':
        return ChatSenderRole.admin;
      case 'bot':
        return ChatSenderRole.bot;
      case 'user':
      default:
        return ChatSenderRole.user;
    }
  }

  static ChatMessageType _parseType(String? type) {
    switch (type) {
      case 'auto_reply':
        return ChatMessageType.autoReply;
      case 'product_card':
        return ChatMessageType.productCard;
      case 'system':
        return ChatMessageType.system;
      case 'text':
      default:
        return ChatMessageType.text;
    }
  }

  static String _typeToString(ChatMessageType type) {
    switch (type) {
      case ChatMessageType.autoReply:
        return 'auto_reply';
      case ChatMessageType.productCard:
        return 'product_card';
      case ChatMessageType.system:
        return 'system';
      case ChatMessageType.text:
        return 'text';
    }
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    ChatSenderRole? senderRole,
    String? text,
    ChatMessageType? type,
    DateTime? createdAt,
    bool? read,
    String? productId,
    String? productTitle,
    String? productImage,
    double? productPrice,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
    );
  }
}
