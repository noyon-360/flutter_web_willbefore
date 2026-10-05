import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/core/constants/user_roles.dart';
import 'package:flutter_web_willbefore/core/routes/route_endpoint.dart';
import 'package:flutter_web_willbefore/features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../order/domain/entities/user_entities.dart';

class DashboardHeader extends ConsumerWidget {
  final String title;
  final List<String> breadcrumbs;
  final VoidCallback onMenuPressed;
  final bool isMobile;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.breadcrumbs,
    required this.onMenuPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.read).length,
      orElse: () => 0,
    );
    final roleLabel = UserRoles.label(ref.watch(currentUserRoleProvider));
    final words = roleLabel.split(' ');
    final roleInitials = words.length > 1
        ? words.map((w) => w[0]).join().toUpperCase()
        : roleLabel.substring(0, 2).toUpperCase();

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: const BoxDecoration(
        // color: AppTheme.backgroundColor,
        border: Border(
          // bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: onMenuPressed,
          ),
          SizedBox(width: isMobile ? 4 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    // color: AppTheme.textPrimary,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: breadcrumbs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final breadcrumb = entry.value;
                        final isLast = index == breadcrumbs.length - 1;

                        return Row(
                          children: [
                            Text(
                              breadcrumb,
                              style: TextStyle(
                                // color: isLast ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontWeight: isLast
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                            if (!isLast) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                // color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // User Profile
          Row(
            children: [
              const SizedBox(width: 12),
              // Notification Bell
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.go(RouteEndpoint.notifications),
                    icon: const Icon(Icons.notifications_outlined),
                    color: Colors.grey[700],
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              if (!isMobile) ...[
                Text(
                  roleLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    // color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              CircleAvatar(
                radius: 20,
                // backgroundColor: AppColors.primaryLaurel,
                child: Text(
                  roleInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
