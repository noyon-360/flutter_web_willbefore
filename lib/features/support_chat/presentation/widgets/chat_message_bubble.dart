import 'package:flutter/material.dart';
import 'package:flutter_web_willbefore/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/route_endpoint.dart';
import '../../../../models/chat_message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.senderRole == ChatSenderRole.admin;
    final isSystem = message.type == ChatMessageType.system;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final bubbleColor = isAdmin ? AppColors.primaryLaurel : Colors.grey[200];
    final textColor = isAdmin ? Colors.white : const Color(0xFF1A1C1E);

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isAdmin)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  message.senderRole == ChatSenderRole.bot ? 'Bot' : 'Customer',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isAdmin ? 14 : 2),
                  bottomRight: Radius.circular(isAdmin ? 2 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.hasProduct) ...[
                    _ProductChip(message: message, isAdmin: isAdmin),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                DateFormat('MMM d, h:mm a').format(message.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  final ChatMessageModel message;
  final bool isAdmin;

  const _ProductChip({required this.message, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final fg = isAdmin ? Colors.white : const Color(0xFF1A1C1E);
    final bg = isAdmin ? Colors.white.withValues(alpha: 0.15) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () =>
          context.go('${RouteEndpoint.products}/view/${message.productId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child:
                  message.productImage != null &&
                      message.productImage!.isNotEmpty
                  ? Image.network(
                      message.productImage!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 32,
                        height: 32,
                        color: Colors.grey[300],
                      ),
                    )
                  : Container(width: 32, height: 32, color: Colors.grey[300]),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.productTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  if (message.productPrice != null)
                    Text(
                      '\$${message.productPrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: fg.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
