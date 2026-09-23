import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutx_core/flutx_core.dart';
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

class AllUserProfileScreen extends ConsumerStatefulWidget {
  const AllUserProfileScreen({super.key});

  @override
  ConsumerState<AllUserProfileScreen> createState() =>
      _AllUserProfileScreenState();
}

class _AllUserProfileScreenState extends ConsumerState<AllUserProfileScreen> {
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
      ref.read(userProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    // Get the current user
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id;

    // A super admin manages admins and users; a plain admin manages only
    // users. Nobody ever sees/edits another super admin from this screen.
    final filteredUsers = userState.users.where((user) {
      if (user.id == currentUserId) return false;
      if (user.role == UserRoles.superAdmin) return false;
      if (!isSuperAdmin && user.role != UserRoles.user) return false;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 23),
            decoration: BoxDecoration(
              color: Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSuperAdmin ? 'Admins & Users' : 'User Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textAppBlack,
                  ),
                ),

                Container(
                  width: 259,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLaurel,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.bgColor,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Gap.w4,
                          Text(
                            '${filteredUsers.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.bgColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search + Add
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (value) =>
                      ref.read(userProvider.notifier).search(value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search users by email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(userProvider.notifier).search('');
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
              Gap.w16,
              ElevatedButton.icon(
                onPressed: () => _showCreateUserDialog(context, isSuperAdmin),
                icon: const Icon(Icons.add, size: 20),
                label: Text(isSuperAdmin ? 'Add Admin/User' : 'Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLaurel,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Users Table
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Phone',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Role',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Created At',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Pending Orders',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'In Cart',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Body
                  if (userState.isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLaurel,
                        ),
                      ),
                    )
                  else if (filteredUsers.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: AppColors.textSecondaryHintColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No users found',
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
                            filteredUsers.length +
                            (userState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= filteredUsers.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryLaurel,
                                ),
                              ),
                            );
                          }

                          final user = filteredUsers[index];

                          return Material(
                            color: index.isEven
                                ? const Color(0xFFF3F3F3)
                                : Colors.white,
                            child: InkWell(
                              onTap: () => _openUserDetail(context, user),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    // Name
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        user.displayNameOrEmail,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textAppBlack,
                                        ),
                                      ),
                                    ),
                                    // Email
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        user.email,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                    // Phone
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        user.phoneNumber ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                    // Role
                                    Expanded(
                                      child: isSuperAdmin
                                          ? _RoleDropdown(
                                              userId: user.id,
                                              role: user.role,
                                              isLoading: userState.isLoading,
                                            )
                                          : _RoleBadge(role: user.role),
                                    ),
                                    // Created At
                                    Expanded(
                                      child: Text(
                                        user.createdAt != null
                                            ? DateFormat(
                                                'dd MMM yyyy\nhh:mm a',
                                              ).format(user.createdAt)
                                            : '-',
                                        style: const TextStyle(
                                          color: AppColors.textSecondaryColor,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    // Pending Orders
                                    Expanded(
                                      child: _PendingOrdersCount(
                                        userId: user.id,
                                      ),
                                    ),
                                    // In Cart
                                    Expanded(
                                      child: _CartItemsCount(userId: user.id),
                                    ),
                                  ],
                                ),
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

  void _openUserDetail(BuildContext context, UserModel user) {
    context.goNamed(
      RouteEndpoint.userDetails.split('/:').first,
      pathParameters: {'id': user.id},
      extra: user,
    );
  }

  void _showCreateUserDialog(BuildContext context, bool isSuperAdmin) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = UserRoles.user;

    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isSuperAdmin ? 'Add Admin or User' : 'Add New User'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    // A plain admin may only create regular users - enforced
                    // again server-side either way.
                    items:
                        (isSuperAdmin
                                ? UserRoles.assignableRoles
                                : [UserRoles.user])
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(UserRoles.label(role)),
                              ),
                            )
                            .toList(),
                    onChanged: !isSuperAdmin
                        ? null
                        : (value) {
                            if (value != null) {
                              setStateDialog(() => selectedRole = value);
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLaurel,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setStateDialog(() => isLoading = true);

                      final success = await ref
                          .read(userProvider.notifier)
                          .createUser(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            role: isSuperAdmin ? selectedRole : UserRoles.user,
                          );

                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();

                      if (success) {
                        final invitedEmail = ref
                            .read(userProvider)
                            .lastInvitedEmail;
                        if (context.mounted && invitedEmail != null) {
                          _showInviteSentDialog(context, invitedEmail);
                        }
                      } else if (context.mounted) {
                        final message = ref.read(userProvider).errorMessage;
                        final error = message.isEmpty
                            ? 'Failed to invite user. Try again.'
                            : message;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteSentDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Created'),
        content: Text(
          'The account for $email has been created and a password-reset '
          'email was sent to them so they can set their own password.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLaurel,
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PendingOrdersCount extends ConsumerWidget {
  final String userId;

  const _PendingOrdersCount({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider(userId));

    return ordersAsync.when(
      loading: () => const _CountSkeleton(),
      error: (_, _) => const Text(
        '-',
        style: TextStyle(color: AppColors.textSecondaryColor, fontSize: 13),
      ),
      data: (orders) {
        final pending = orders
            .where((o) => o.status == OrderStatus.pending)
            .length;
        return _CountBadge(count: pending, color: Colors.orange);
      },
    );
  }
}

class _CartItemsCount extends ConsumerWidget {
  final String userId;

  const _CartItemsCount({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(userCartItemsProvider(userId));

    return cartAsync.when(
      loading: () => const _CountSkeleton(),
      error: (_, _) => const Text(
        '-',
        style: TextStyle(color: AppColors.textSecondaryColor, fontSize: 13),
      ),
      data: (items) =>
          _CountBadge(count: items.length, color: AppColors.primaryLaurel),
    );
  }
}

// Loading state for the per-row Pending Orders / In Cart cells. Deliberately
// static (no animation): with 100+ rows each firing its own Firestore query,
// that many concurrent animated CircularProgressIndicators overwhelms
// CanvasKit's frame budget and the spinners visually smear into streaks.
class _CountSkeleton extends StatelessWidget {
  const _CountSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Text(
        '0',
        style: TextStyle(color: AppColors.textSecondaryColor, fontSize: 13),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role != UserRoles.user;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFF1B4332) : const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          UserRoles.label(role),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RoleDropdown extends ConsumerWidget {
  final String userId;
  final String role;
  final bool isLoading;

  const _RoleDropdown({
    required this.userId,
    required this.role,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only admin/user are ever assignable from this screen.
    final currentValue = UserRoles.assignableRoles.contains(role)
        ? role
        : UserRoles.user;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: currentValue,
        isDense: true,
        items: UserRoles.assignableRoles
            .map(
              (r) =>
                  DropdownMenuItem(value: r, child: Text(UserRoles.label(r))),
            )
            .toList(),
        onChanged: isLoading
            ? null
            : (value) async {
                if (value == null || value == role) return;
                final success = await ref
                    .read(userProvider.notifier)
                    .updateUserRole(userId, value);
                if (!context.mounted) return;
                if (!success) {
                  final error =
                      ref.read(userProvider).updateError ??
                      'Failed to update role.';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                }
              },
      ),
    );
  }
}
