import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutx_core/core/debug_print.dart';
import 'package:intl/intl.dart';

import '../../../../core/common/widgets/app_cached_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/categories_provider.dart';
import '../widgets/add_category_dialog.dart';
import '../widgets/edit_categories_dialog.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final categories = categoriesState.categories;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textAppBlack,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Categories',
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

          const SizedBox(height: 24),

          // Categories Table
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
                            'Categories Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
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
                  if (categoriesState.isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLaurel,
                        ),
                      ),
                    )
                  else if (categories.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: AppColors.textSecondaryHintColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No categories found',
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
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isLast = index == categories.length - 1;

                          DPrint.log("Category Image ${category.imageUrl}");

                          return Container(
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
                                // Category Name with Image
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      // Category Image
                                      Container(
                                        width: 60,
                                        height: 60,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: AppColors.bgColor,
                                        ),
                                        child: category.imageUrl != null
                                            ? AppCachedImage(
                                                imageUrl: category.imageUrl!,

                                                errorIcon: Icons.category,
                                                errorIconColor:
                                                    AppColors.iconSelectedColor,
                                              )
                                            // ClipRRect(
                                            //     borderRadius:
                                            //         BorderRadius.circular(8),
                                            //     child: Image.network(
                                            //       category.imageUrl!,
                                            //       fit: BoxFit.cover,
                                            //       errorBuilder: (context, error,
                                            //           stackTrace) {
                                            //         return const Icon(
                                            //           Icons.category,
                                            //           color: AppColors
                                            //               .primaryLaurel,
                                            //           size: 24,
                                            //         );
                                            //       },
                                            //     ),
                                            // )
                                            : const Icon(
                                                Icons.category,
                                                color: AppColors.primaryLaurel,
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Category Name
                                      Expanded(
                                        child: Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textAppBlack,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Date
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    DateFormat(
                                      'dd MMM yyyy hh:mm a',
                                    ).format(category.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                ),

                                // Actions
                                SizedBox(
                                  width: 100,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _showEditCategoryDialog(
                                              context,
                                              category,
                                            ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: AppColors.primaryLaurel,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: categoriesState.isDeleting
                                            ? null
                                            : () => _showDeleteDialog(
                                                context,
                                                category.id,
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

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
  }

  void _showEditCategoryDialog(BuildContext context, category) {
    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(category: category),
    );
  }

  void _showDeleteDialog(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: const Text(
            'Are you sure you want to delete this category? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await ref
                    .read(categoriesProvider.notifier)
                    .deleteCategory(categoryId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category deleted successfully!'),
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
