import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/chat_message_model.dart';
import '../../../../models/chat_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Streams every support chat, open chats first (sorted by most recently
/// active), then closed chats. Kept as a single stream + client-side sort so
/// the admin inbox does not need a composite Firestore index.
final openChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('chats')
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snapshot) {
    final chats = snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    chats.sort((a, b) {
      if (a.status != b.status) {
        return a.status == ChatStatus.open ? -1 : 1;
      }
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });
    return chats;
  });
});

/// Streams a single chat doc, so the admin sees live status/rating updates
/// (e.g. a rating the customer submits after the admin has already opened
/// the conversation).
final chatProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((doc) => doc.exists ? ChatModel.fromFirestore(doc) : null);
});

/// Streams the messages of a single chat, oldest first.
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList();
  });
});

final chatAdminService = Provider((ref) => ChatAdminService(ref));

class ChatAdminService {
  final Ref _ref;
  ChatAdminService(this._ref);

  Future<void> sendReply(String chatId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final adminId = _ref.read(authProvider).user?.uid ?? '';
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': adminId,
      'senderRole': 'admin',
      'text': trimmed,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    await chatRef.update({
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadForUser': true,
      'unreadForAdmin': false,
    });
  }

  Future<void> markRead(String chatId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({'unreadForAdmin': false});
  }

  Future<void> closeChat(String chatId) async {
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    });
  }
}
