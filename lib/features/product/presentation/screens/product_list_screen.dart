import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_endpoint.dart';
import '../../domain/requests/update_product_request.dart';
import '../providers/products_providers.dart';
import '../providers/send_product_notification.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final products = productsState.products;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textAppBlack,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('${RouteEndpoint.products}/add'),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add product',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLaurel,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search + sort
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) =>
                      ref.read(productsProvider.notifier).search(value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search products by title...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(productsProvider.notifier).search('');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: productsState.sortByScore,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: const [
                      DropdownMenuItem(
                        value: false,
                        child: Text('Sort: Newest'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Sort: Top score'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      ref
                          .read(productsProvider.notifier)
                          .setSortByScore(value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Products Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Product Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'ID',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Actual_Price',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Discount_Price',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Stocks',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Views',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Rating',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: Text(
                            'Action',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Body
                  if (productsState.isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLaurel,
                        ),
                      ),
                    )
                  else if (products.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 64,
                              color: AppColors.textSecondaryHintColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondaryHintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            products.length +
                            (productsState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= products.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryLaurel,
                                ),
                              ),
                            );
                          }

                          final product = products[index];
                          final isLast = index == products.length - 1;

                          DPrint.info("Products : ${product.colors}");

                          return InkWell(
                            onTap: () {
                              context.go(
                                '${RouteEndpoint.products}/view/${product.id}',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isLast
                                        ? Colors.transparent
                                        : AppColors.borderColor,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Product Name with Image
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        // Product Image
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: AppColors.bgColor,
                                          ),
                                          child: product.imageUrls.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    product.imageUrls.first,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return const Icon(
                                                            Icons.inventory,
                                                            color: AppColors
                                                                .primaryLaurel,
                                                            size: 24,
                                                          );
                                                        },
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.inventory,
                                                  color:
                                                      AppColors.primaryLaurel,
                                                  size: 24,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Product Name
                                        Expanded(
                                          child: Text(
                                            product.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textAppBlack,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ID
                                  Expanded(
                                    child: Text(
                                      product.id.substring(0, 8),
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryColor,
                                      ),
                                    ),
                                  ),

                                  // Actual Price
                                  Expanded(
                                    child: Text(
                                      '\$${product.actualPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textAppBlack,
                                      ),
                                    ),
                                  ),

                                  // Discount Price
                                  Expanded(
                                    child: Text(
                                      product.discountPrice != null
                                          ? '\$${product.discountPrice!.toStringAsFixed(2)}'
                                          : '-',
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryColor,
                                      ),
                                    ),
                                  ),

                                  // Stock
                                  Expanded(
                                    child: Text(
                                      '${product.stock}',
                                      style: TextStyle(
                                        color: product.stock > 20
                                            ? Colors.green
                                            : product.stock > 5
                                            ? Colors.orange
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // Views
                                  Expanded(
                                    child: Text(
                                      '${product.viewCount}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryColor,
                                      ),
                                    ),
                                  ),

                                  // Rating
                                  Expanded(
                                    child: product.ratingCount > 0
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 14,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${product.averageRating.toStringAsFixed(1)} (${product.ratingCount})',
                                                style: const TextStyle(
                                                  color: AppColors
                                                      .textSecondaryColor,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            '—',
                                            style: TextStyle(
                                              color: AppColors
                                                  .textSecondaryColor,
                                            ),
                                          ),
                                  ),

                                  // Date
                                  Expanded(
                                    child: Text(
                                      DateFormat(
                                        'dd MMM yyyy hh:mm a',
                                      ).format(product.createdAt),
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  // Actions
                                  SizedBox(
                                    width: 140,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: productsState.isUpdating
                                              ? null
                                              : () async {
                                                  final request =
                                                      UpdateProductRequest(
                                                        id: product.id,
                                                        title: product.title,
                                                        description:
                                                            product.description,
                                                        actualPrice:
                                                            product.actualPrice,
                                                        discountPrice: product
                                                            .discountPrice,
                                                        stock: product.stock,
                                                        categoryId:
                                                            product.categoryId,
                                                        promoId:
                                                            product.promoId,
                                                        sizes: product.sizes,
                                                        colors: product.colors,
                                                        colorCodes:
                                                            product.colorCodes,
                                                        newImages: [],
                                                        existingImageUrls:
                                                            product.imageUrls,
                                                        isActive:
                                                            !product.isActive,
                                                        facilities:
                                                            product.facilities,
                                                      );

                                                  final success = await ref
                                                      .read(
                                                        productsProvider
                                                            .notifier,
                                                      )
                                                      .updateProduct(request);

                                                  if (success && mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          product.isActive
                                                              ? 'Product hidden successfully!'
                                                              : 'Product published successfully!',
                                                        ),
                                                        backgroundColor:
                                                            AppColors
                                                                .primaryLaurel,
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: Icon(
                                            product.isActive
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            size: 18,
                                            color: product.isActive
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          tooltip: product.isActive
                                              ? 'Hide Product'
                                              : 'Publish Product',
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              confirmAndSendProductNotification(
                                                context,
                                                product,
                                              ),
                                          icon: const Icon(
                                            Icons.notifications_active_outlined,
                                            size: 18,
                                            color: Colors.blueAccent,
                                          ),
                                          tooltip: 'Notify all users',
                                        ),
                                        // IconButton(
                                        // onPressed: () => context.go(
                                        //   '${RouteEndpoint.products}/edit/${product.id}',
                                        // ),
                                        //   icon: const Icon(
                                        //     Icons.edit_outlined,
                                        //     size: 18,
                                        //     color: AppColors.primaryLaurel,
                                        //   ),
                                        // ),
                                        IconButton(
                                          onPressed: productsState.isDeleting
                                              ? null
                                              : () => _showDeleteDialog(
                                                  context,
                                                  product.id,
                                                ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text(
            'Are you sure you want to delete this product? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Capture messenger before async gap to avoid
                // "Looking up a deactivated widget's ancestor is unsafe"
                final messenger = ScaffoldMessenger.of(context);
                final success = await ref
                    .read(productsProvider.notifier)
                    .deleteProduct(productId);
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
