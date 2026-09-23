import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/route_endpoint.dart';
import '../../../../models/chat_model.dart';

/// Small thumbnail/badge used in the inbox row and pinned at the top of the
/// conversation screen when a chat is tied to a specific product.
class ProductPill extends StatelessWidget {
  final ChatModel chat;
  final bool dense;

  const ProductPill({super.key, required this.chat, this.dense = false});

  @override
  Widget build(BuildContext context) {
    if (chat.productId == null || chat.productId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final image = chat.productImage;
    final title = chat.productTitle ?? 'Product';
    final price = chat.productPrice;

    return InkWell(
      borderRadius: BorderRadius.circular(dense ? 8 : 12),
      onTap: () =>
          context.go('${RouteEndpoint.products}/view/${chat.productId}'),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 12,
          vertical: dense ? 4 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(dense ? 8 : 12),
          border: Border.all(color: Colors.blueGrey.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: image != null && image.isNotEmpty
                  ? Image.network(
                      image,
                      width: dense ? 22 : 40,
                      height: dense ? 22 : 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: dense ? 22 : 40,
                        height: dense ? 22 : 40,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 16,
                        ),
                      ),
                    )
                  : Container(
                      width: dense ? 22 : 40,
                      height: dense ? 22 : 40,
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_bag_outlined, size: 16),
                    ),
            ),
            SizedBox(width: dense ? 6 : 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dense ? 11 : 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  if (price != null)
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: dense ? 10 : 12,
                        color: Colors.grey[600],
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
