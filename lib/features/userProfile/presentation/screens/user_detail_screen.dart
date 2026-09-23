import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/routes/route_endpoint.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../order/data/models/user_model.dart';
import '../../../order/domain/entities/order_entities.dart';
import '../../../order/presentation/providers/order_provider.dart';
import '../provider/all_user_provider.dart';

class UserDetailScreen extends ConsumerWidget {
  final String userId;
  final UserModel? initialUser;

  const UserDetailScreen({super.key, required this.userId, this.initialUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userProvider).users;
    UserModel? user;
    for (final u in users) {
      if (u.id == userId) {
        user = u;
        break;
      }
    }
    user ??= initialUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final currentUser = user;

    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final ordersAsync = ref.watch(userOrdersProvider(userId));
    final cartItemsAsync = ref.watch(userCartItemsProvider(userId));
    final userState = ref.watch(userProvider);

    // A plain admin can only delete regular users; a super admin can delete
    // admins and users (never another super admin, already excluded from
    // ever reaching this screen).
    final canDelete = isSuperAdmin || currentUser.role == UserRoles.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Profile Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: !canDelete || userState.isLoading
                ? null
                : () => _confirmAndDelete(context, ref, currentUser),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete User',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(currentUser),
            const SizedBox(height: 24),
            if (isSuperAdmin) ...[
              _buildRoleCard(context, ref, currentUser),
              const SizedBox(height: 24),
            ],
            _buildOrdersSummary(ordersAsync),
            const SizedBox(height: 24),
            _buildOrdersList(context, ordersAsync),
            const SizedBox(height: 24),
            _buildCartItems(cartItemsAsync),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.displayNameOrEmail}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(userProvider.notifier).deleteUser(user.id);

    if (!context.mounted) return;

    if (success) {
      context.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully!'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      final error =
          ref.read(userProvider).deleteError ?? 'Failed to delete user.';
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    final isAdminRole = user.role != UserRoles.user;

    return _card(
      title: 'Profile Information',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLaurel,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayNameOrEmail,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textAppBlack,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAdminRole
                            ? const Color(0xFF1B4332)
                            : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        UserRoles.label(user.role),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.email_outlined, user.email),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.phone_outlined,
                  user.phoneNumber?.isNotEmpty == true
                      ? user.phoneNumber!
                      : 'No phone number',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.calendar_today_outlined,
                  'Joined ${DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt)}',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  user.isEmailVerified
                      ? Icons.verified_outlined
                      : Icons.error_outline,
                  user.isEmailVerified
                      ? 'Email verified'
                      : 'Email not verified',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(BuildContext context, WidgetRef ref, UserModel user) {
    final userState = ref.watch(userProvider);
    final currentRole = UserRoles.assignableRoles.contains(user.role)
        ? user.role
        : UserRoles.user;

    return _card(
      title: 'Manage Role',
      child: Row(
        children: [
          const Text(
            'Current role:',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryColor),
          ),
          const SizedBox(width: 16),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentRole,
              items: UserRoles.assignableRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(UserRoles.label(r)),
                    ),
                  )
                  .toList(),
              onChanged: userState.isLoading
                  ? null
                  : (value) async {
                      if (value == null || value == user.role) return;
                      final success = await ref
                          .read(userProvider.notifier)
                          .updateUserRole(user.id, value);
                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Role updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        final error =
                            ref.read(userProvider).updateError ??
                            'Failed to update role.';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSummary(AsyncValue<List<Order>> ordersAsync) {
    return ordersAsync.when(
      loading: () => _card(
        title: 'Order Summary',
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _card(
        title: 'Order Summary',
        child: Text(
          'Failed to load orders: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (orders) {
        final totalOrders = orders.length;
        final completedOrders = orders
            .where((o) => o.status == OrderStatus.shipped)
            .length;
        final cancelledOrders = orders
            .where((o) => o.status == OrderStatus.cancelled)
            .length;
        final totalSpent = orders
            .where((o) => o.status != OrderStatus.cancelled)
            .fold<double>(0, (sum, o) => sum + o.total);

        return _card(
          title: 'Order Summary',
          child: Row(
            children: [
              _summaryTile('Total Orders', '$totalOrders', Colors.indigo),
              _summaryTile('Completed', '$completedOrders', Colors.green),
              _summaryTile('Cancelled', '$cancelledOrders', Colors.red),
              _summaryTile(
                'Total Spent',
                '\$${totalSpent.toStringAsFixed(2)}',
                AppColors.primaryLaurel,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    AsyncValue<List<Order>> ordersAsync,
  ) {
    return ordersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
      data: (orders) {
        if (orders.isEmpty) {
          return _card(
            title: 'Orders',
            child: const Text(
              'This user has not placed any orders yet.',
              style: TextStyle(color: AppColors.textSecondaryColor),
            ),
          );
        }

        return _card(
          title: 'Orders',
          child: Column(
            children: orders.asMap().entries.map((entry) {
              final index = entry.key;
              final order = entry.value;
              return Column(
                children: [
                  InkWell(
                    onTap: () => context.go(
                      '${RouteEndpoint.orders}/orders-details/${order.id}',
                      extra: order,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '#${order.id.substring(0, order.id.length >= 8 ? 8 : order.id.length)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat('dd MMM yyyy').format(order.createdAt),
                              style: const TextStyle(
                                color: AppColors.textSecondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: order.status.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.status.displayName,
                              style: TextStyle(
                                color: order.status.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textSecondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < orders.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCartItems(AsyncValue<List<CartItem>> cartItemsAsync) {
    return cartItemsAsync.when(
      loading: () => _card(
        title: 'Cart Items',
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _card(
        title: 'Cart Items',
        child: Text(
          'Failed to load cart: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _card(
            title: 'Cart Items',
            child: const Text(
              "This user's cart is currently empty.",
              style: TextStyle(color: AppColors.textSecondaryColor),
            ),
          );
        }

        return _card(
          title: 'Cart Items (not yet ordered)',
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: item.product.imageUrls.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.product.imageUrls.first,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.shopping_bag_outlined,
                                              color: Colors.orange,
                                            ),
                                  ),
                                )
                              : const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.orange,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  'Qty: ${item.quantity}',
                                  if (item.selectedSize != null)
                                    'Size: ${item.selectedSize}',
                                  if (item.selectedColor != null)
                                    'Color: ${item.selectedColor}',
                                ].join('  •  '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryLaurel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < items.length - 1) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
