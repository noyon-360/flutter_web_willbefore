import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_endpoint.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../promo/presentation/providers/promos_provider.dart';
import '../../domain/entrity/product.dart';
import '../providers/products_providers.dart';

/// Read-only product details view.
///
/// Reached either from the Product List (tapping a row) or from a support
/// chat's product card/pill. Shows an "Edit" button that navigates on to the
/// existing [EditProductScreen] rather than duplicating the edit form here.
class ProductViewScreen extends ConsumerWidget {
  final String productId;

  const ProductViewScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsProvider);

    Product? product;
    try {
      product = productsState.products.firstWhere((p) => p.id == productId);
    } catch (_) {}

    if (product == null) {
      if (productsState.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLaurel),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_outlined,
              size: 64,
              color: AppColors.textSecondaryHintColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Product not found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondaryHintColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RouteEndpoint.products),
              child: const Text('Back to Product List'),
            ),
          ],
        ),
      );
    }

    final categoriesState = ref.watch(categoriesProvider);
    final promosState = ref.watch(promosProvider);

    String categoryName = '-';
    try {
      categoryName = categoriesState.categories
          .firstWhere((c) => c.id == product!.categoryId)
          .name;
    } catch (_) {}

    String? promoLabel;
    if (product.promoId != null) {
      try {
        final promo = promosState.promos.firstWhere(
          (p) => p.id == product!.promoId,
        );
        promoLabel = '${promo.title} (${promo.code})';
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 1200;

          final left = _buildLeftColumn(product!, categoryName, promoLabel);
          final right = _buildRightColumn(context, product);

          if (isWideScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: left),
                const SizedBox(width: 32),
                Expanded(child: right),
              ],
            );
          }
          return Column(children: [left, const SizedBox(height: 32), right]);
        },
      ),
    );
  }

  Widget _buildLeftColumn(
    Product product,
    String categoryName,
    String? promoLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textAppBlack,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    product.isOnSale
                        ? product.formattedDiscountPrice!
                        : product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLaurel,
                    ),
                  ),
                  if (product.isOnSale) ...[
                    const SizedBox(width: 8),
                    Text(
                      product.formattedPrice,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _card(
          title: 'Details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Category', categoryName),
              _detailRow('Promo', promoLabel ?? 'No promo'),
              _detailRow('Stock', '${product.stock} (${product.stockStatus})'),
              _detailRow(
                'Status',
                product.isActive ? 'Active / Published' : 'Private / Hidden',
              ),
              if (product.sizes.isNotEmpty)
                _detailRow('Sizes', product.sizes.join(', ')),
              _detailRow(
                'Created',
                DateFormat('dd MMM yyyy hh:mm a').format(product.createdAt),
              ),
              _detailRow(
                'Updated',
                DateFormat('dd MMM yyyy hh:mm a').format(product.updatedAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _card(
          title: 'Description',
          child: product.description.trim().isEmpty
              ? Text(
                  'No description added.',
                  style: TextStyle(
                    color: AppColors.textSecondaryHintColor,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Html(
                  data: product.description,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      color: AppColors.textAppBlack,
                    ),
                  },
                ),
        ),
        if (product.colors.isNotEmpty) ...[
          const SizedBox(height: 24),
          _card(
            title: 'Colors',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(product.colors.length, (index) {
                Color? swatch;
                if (index < product.colorCodes.length) {
                  final hex = product.colorCodes[index];
                  final parsed = int.tryParse(hex, radix: 16);
                  if (parsed != null) swatch = Color(parsed);
                }
                return Chip(
                  avatar: swatch != null
                      ? CircleAvatar(backgroundColor: swatch)
                      : null,
                  label: Text(product.colors[index]),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          title: 'Images',
          child: product.imageUrls.isEmpty
              ? Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.inventory,
                      color: AppColors.primaryLaurel,
                      size: 32,
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: product.imageUrls.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                context.go('${RouteEndpoint.products}/edit/${product.id}'),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Edit Product',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(RouteEndpoint.products),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Back to Product List',
              style: TextStyle(color: AppColors.textSecondaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textAppBlack,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textAppBlack),
            ),
          ),
        ],
      ),
    );
  }
}
