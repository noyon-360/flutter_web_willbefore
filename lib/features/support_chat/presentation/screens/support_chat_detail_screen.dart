import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/common/widgets/app_scaffold.dart';
import 'package:flutter_web_willbefore/core/constants/app_colors.dart';

import '../../../../models/chat_model.dart';
import '../providers/support_chat_provider.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/product_pill.dart';

class SupportChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final ChatModel? initialChat;

  const SupportChatDetailScreen({
    super.key,
    required this.chatId,
    this.initialChat,
  });

  @override
  ConsumerState<SupportChatDetailScreen> createState() =>
      _SupportChatDetailScreenState();
}

class _SupportChatDetailScreenState
    extends ConsumerState<SupportChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark the chat read as soon as the admin opens the conversation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatAdminService).markRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final chat =
        ref.watch(chatProvider(widget.chatId)).value ?? widget.initialChat;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          TextButton.icon(
            onPressed: _handleEndChat,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('End chat'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chat?.productId != null && chat!.productId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ProductPill(chat: chat),
              ),
            ),
          if (chat?.rating != null) _buildRatingBanner(chat!),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(message: messages[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildRatingBanner(ChatModel chat) {
    final rating = chat.rating?.round() ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          const SizedBox(width: 8),
          if (chat.ratingComment != null && chat.ratingComment!.isNotEmpty)
            Expanded(
              child: Text(
                '"${chat.ratingComment}"',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type a reply...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _handleSend,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
              foregroundColor: Colors.white,
            ),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref.read(chatAdminService).sendReply(widget.chatId, text);
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleEndChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End chat'),
        content: const Text(
          'This will mark the conversation as closed. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End chat'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(chatAdminService).closeChat(widget.chatId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to close chat: $e')),
        );
      }
    }
  }
}
