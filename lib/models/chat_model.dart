import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatStatus { open, closed }

class ChatModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhoto;
  final ChatStatus status;
  final String? topic;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final double? productPrice;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool unreadForAdmin;
  final bool unreadForUser;
  final num? rating;
  final String? ratingComment;
  final DateTime? ratedAt;
  final DateTime createdAt;
  final DateTime? closedAt;

  ChatModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userPhoto,
    this.status = ChatStatus.open,
    this.topic,
    this.productId,
    this.productTitle,
    this.productImage,
    this.productPrice,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadForAdmin = false,
    this.unreadForUser = false,
    this.rating,
    this.ratingComment,
    this.ratedAt,
    required this.createdAt,
    this.closedAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userPhoto: data['userPhoto'],
      status: _parseStatus(data['status']),
      topic: data['topic'],
      productId: data['productId'],
      productTitle: data['productTitle'],
      productImage: data['productImage'],
      productPrice: (data['productPrice'] as num?)?.toDouble(),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadForAdmin: data['unreadForAdmin'] ?? false,
      unreadForUser: data['unreadForUser'] ?? false,
      rating: data['rating'],
      ratingComment: data['ratingComment'],
      ratedAt: (data['ratedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'status': status.name,
      'topic': topic,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'productPrice': productPrice,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadForAdmin': unreadForAdmin,
      'unreadForUser': unreadForUser,
      'rating': rating,
      'ratingComment': ratingComment,
      'ratedAt': ratedAt != null ? Timestamp.fromDate(ratedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };
  }

  static ChatStatus _parseStatus(String? status) {
    switch (status) {
      case 'closed':
        return ChatStatus.closed;
      case 'open':
      default:
        return ChatStatus.open;
    }
  }

  ChatModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    ChatStatus? status,
    String? topic,
    String? productId,
    String? productTitle,
    String? productImage,
    double? productPrice,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? unreadForAdmin,
    bool? unreadForUser,
    num? rating,
    String? ratingComment,
    DateTime? ratedAt,
    DateTime? createdAt,
    DateTime? closedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      status: status ?? this.status,
      topic: topic ?? this.topic,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadForAdmin: unreadForAdmin ?? this.unreadForAdmin,
      unreadForUser: unreadForUser ?? this.unreadForUser,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      ratedAt: ratedAt ?? this.ratedAt,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
