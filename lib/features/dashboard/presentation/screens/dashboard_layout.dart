import 'package:flutter/material.dart';
import 'package:flutter_web_willbefore/core/routes/route_endpoint.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/dashboard_models.dart';
import '../widgets/sidebar.dart';
import '../widgets/dashboard_header.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  static const double _mobileBreakpoint = 700;
  static const double _desktopBreakpoint = 1100;

  /// Manual sidebar choice; null means follow the screen width.
  bool? _collapsedOverride;
  _ScreenSize? _lastSize;

  NavigationItem _getCurrentNavigationItem(String location) {
    if (location.startsWith(RouteEndpoint.dashboard)) {
      return NavigationItem.dashboard;
    }
    if (location.startsWith('/categories')) return NavigationItem.categories;
    if (location.startsWith('/products')) return NavigationItem.productList;
    if (location.startsWith('/orders')) return NavigationItem.order;
    if (location.startsWith('/promos')) return NavigationItem.promo;
    if (location.startsWith('/profile')) return NavigationItem.userProfile;
    if (location.startsWith('/settings')) return NavigationItem.settings;
    if (location.startsWith(RouteEndpoint.supportChats)) {
      return NavigationItem.messages;
    }
    // if (location.startsWith('/notifications')) return NavigationItem.notifications;
    return NavigationItem.dashboard;
  }

  String _getPageTitle(String location) {
    if (location.startsWith(RouteEndpoint.dashboard)) return 'Overview';
    if (location.startsWith('/categories')) return 'Categories';
    if (location.startsWith('/products/add')) return 'Add Product';
    if (location.startsWith('/products/edit')) return 'Edit Product';
    if (location.startsWith('/products/view')) return 'Product Details';
    if (location.startsWith('/products')) return 'Product List';
    if (location.startsWith('/orders')) return 'Orders';
    if (location.startsWith('/promos/add')) return 'Add Promo';
    if (location.startsWith('/promos')) return 'Promos';
    if (location.startsWith('/profile')) return 'User Profile';
    if (location.startsWith('/settings')) return 'Settings';
    if (location.startsWith(RouteEndpoint.supportChats)) return 'Messages';
    // if (location.startsWith('/notifications')) return 'Notifications';
    return 'Dashboard';
  }

  List<String> _getBreadcrumbs(String location) {
    if (location.startsWith(RouteEndpoint.dashboard)) {
      return ['Dashboard', 'Overview'];
    }
    if (location.startsWith('/categories')) return ['Dashboard', 'Categories'];
    if (location.startsWith('/products/add')) {
      return ['Dashboard', 'Product List', 'Add Product'];
    }
    if (location.startsWith('/products/edit')) {
      return ['Dashboard', 'Product List', 'Edit Product'];
    }
    if (location.startsWith('/products/view')) {
      return ['Dashboard', 'Product List', 'Product Details'];
    }
    if (location.startsWith('/products')) return ['Dashboard', 'Product List'];
    if (location.startsWith('/orders')) return ['Dashboard', 'Orders'];
    if (location.startsWith('/promos/add')) {
      return ['Dashboard', 'Promo List', 'Add Promo'];
    }
    if (location.startsWith('/promos')) return ['Dashboard', 'Promo List'];
    if (location.startsWith('/profile')) return ['Dashboard', 'User Profile'];
    if (location.startsWith('/settings')) return ['Dashboard', 'Settings'];
    if (location.startsWith(RouteEndpoint.supportChats)) {
      return ['Dashboard', 'Messages'];
    }
    // if (location.startsWith('/notifications')) return ['Dashboard', 'Notifications'];
    return ['Dashboard'];
  }

  void _onNavigationItemSelected(BuildContext context, NavigationItem item) {
    switch (item) {
      case NavigationItem.dashboard:
        context.go(RouteEndpoint.dashboard);
        break;
      case NavigationItem.categories:
        context.go('/categories');
        break;
      case NavigationItem.productList:
        context.go('/products');
        break;
      case NavigationItem.order:
        context.go('/orders');
        break;
      case NavigationItem.promo:
        context.go('/promos');
        break;
      case NavigationItem.userProfile:
        context.go('/profile');
        break;
      case NavigationItem.settings:
        context.go('/settings');
        break;
      case NavigationItem.messages:
        context.go(RouteEndpoint.supportChats);
        break;
      /*
      case NavigationItem.notifications:
        context.go('/notifications');
        break;
      */
    }
  }

  _ScreenSize _sizeFor(double width) {
    if (width < _mobileBreakpoint) return _ScreenSize.mobile;
    if (width < _desktopBreakpoint) return _ScreenSize.medium;
    return _ScreenSize.large;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentItem = _getCurrentNavigationItem(location);
    final pageTitle = _getPageTitle(location);
    final breadcrumbs = _getBreadcrumbs(location);

    final size = _sizeFor(MediaQuery.sizeOf(context).width);
    // Reset the manual choice when the screen crosses a breakpoint.
    if (_lastSize != size) {
      _collapsedOverride = null;
      _lastSize = size;
    }
    final isMobile = size == _ScreenSize.mobile;
    final collapsed = _collapsedOverride ?? size == _ScreenSize.medium;

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                selectedItem: currentItem,
                onItemSelected: (item) {
                  Navigator.of(context).pop();
                  _onNavigationItemSelected(context, item);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              selectedItem: currentItem,
              collapsed: collapsed,
              onItemSelected: (item) =>
                  _onNavigationItemSelected(context, item),
            ),
          Expanded(
            child: Column(
              children: [
                Builder(
                  builder: (context) => DashboardHeader(
                    title: pageTitle,
                    breadcrumbs: breadcrumbs,
                    isMobile: isMobile,
                    onMenuPressed: () {
                      if (isMobile) {
                        Scaffold.of(context).openDrawer();
                      } else {
                        setState(() => _collapsedOverride = !collapsed);
                      }
                    },
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScreenSize { mobile, medium, large }
