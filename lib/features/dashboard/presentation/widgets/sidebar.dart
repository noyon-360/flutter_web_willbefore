import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/common/widgets/app_logo.dart';
import 'package:flutter_web_willbefore/core/routes/route_endpoint.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../models/dashboard_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class Sidebar extends ConsumerWidget {
  final NavigationItem selectedItem;
  final Function(NavigationItem) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        width: 250,
        child: Column(
          children: [
            // Logo Section
            Container(padding: const EdgeInsets.all(24), child: AppLogo()),

            /// [Version] Show the update version
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Version unavailable',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Text(
                      'Loading version...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    );
                  }

                  final packageInfo = snapshot.data!;
                  return Text(
                    'Version ${packageInfo.version}+${packageInfo.buildNumber}',
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                },
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildNavItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    item: NavigationItem.dashboard,
                  ),
                  _buildNavItem(
                    icon: Icons.category_outlined,
                    title: 'Categories',
                    item: NavigationItem.categories,
                  ),
                  _buildNavItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Product List',
                    item: NavigationItem.productList,
                  ),
                  _buildNavItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Order',
                    item: NavigationItem.order,
                  ),
                  _buildNavItem(
                    icon: Icons.local_offer_outlined,
                    title: 'Promo',
                    item: NavigationItem.promo,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    title: 'User Profile',
                    item: NavigationItem.userProfile,
                  ),
                  _buildNavItem(
                    icon: Icons.settings_outlined,
                    title: 'Setting',
                    item: NavigationItem.settings,
                  ),
                  /*
                _buildNavItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  item: NavigationItem.notifications,
                ),
                */
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _handleLogout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required NavigationItem item,
  }) {
    final isSelected = selectedItem == item;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          // color: isSelected ? AppColors.primaryLaurel : AppTheme.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            // color: isSelected ? AppColors.primaryLaurel : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        // selectedTileColor: AppColors.primaryLaurel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => onItemSelected(item),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final logoutConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (logoutConfirmed == true && context.mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(authProvider.notifier).logout();
        // Navigate to login screen after logout
        if (context.mounted) {
          context.pushReplacement(RouteEndpoint.login);
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Logout failed: ${e.toString()}')),
          );
        }
      }
    }
  }
}
