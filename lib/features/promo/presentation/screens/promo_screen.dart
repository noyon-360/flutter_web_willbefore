import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_endpoint.dart';
import '../providers/promos_provider.dart';

class PromosScreen extends ConsumerStatefulWidget {
  const PromosScreen({super.key});

  @override
  ConsumerState<PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends ConsumerState<PromosScreen> {
  @override
  Widget build(BuildContext context) {
    final promosState = ref.watch(promosProvider);
    final promos = promosState.promos;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Promo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textAppBlack,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('${RouteEndpoint.promos}/add'),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Promo',
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

          // Promos Table
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
                            'Promo Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Under of products',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAppBlack,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Under of products',
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
                  if (promosState.isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLaurel,
                        ),
                      ),
                    )
                  else if (promos.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 64,
                              color: AppColors.textSecondaryHintColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No promos found',
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
                        itemCount: promos.length,
                        itemBuilder: (context, index) {
                          final promo = promos[index];
                          final isLast = index == promos.length - 1;

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
                                // Promo Name with Image
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      // Promo Image
                                      Container(
                                        width: 80,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: AppColors.bgColor,
                                        ),
                                        child: promo.imageUrl != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  promo.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return const Icon(
                                                          Icons.local_offer,
                                                          color: AppColors
                                                              .primaryLaurel,
                                                          size: 24,
                                                        );
                                                      },
                                                ),
                                              )
                                            : const Icon(
                                                Icons.local_offer,
                                                color: AppColors.primaryLaurel,
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Promo Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              promo.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textAppBlack,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Up to ${promo.discountPercentage.toInt()}% off',
                                              style: const TextStyle(
                                                color: AppColors
                                                    .textSecondaryColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Code
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.borderColor,
                                      ),
                                    ),
                                    child: Text(
                                      promo.code,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textAppBlack,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),

                                // Usage Count
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    promo.usageLimit > 0
                                        ? '${promo.usedCount}/${promo.usageLimit}'
                                        : '${promo.usedCount}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                ),

                                // Actions
                                SizedBox(
                                  width: 100,
                                  child: Wrap(
                                    spacing: 0,
                                    runSpacing: 0,
                                    children: [
                                      IconButton(
                                        onPressed: () => context.go(
                                          '${RouteEndpoint.promos}/view/${promo.id}',
                                        ),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 18,
                                          color: AppColors.textSecondaryColor,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => context.go(
                                          '${RouteEndpoint.promos}/edit/${promo.id}',
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: AppColors.primaryLaurel,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: promosState.isDeleting
                                            ? null
                                            : () => _showDeleteDialog(
                                                context,
                                                promo.id,
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

  void _showDeleteDialog(BuildContext context, String promoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Promo'),
          content: const Text(
            'Are you sure you want to delete this promotional campaign? This action cannot be undone.',
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
                    .read(promosProvider.notifier)
                    .deletePromo(promoId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Promo deleted successfully!'),
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
