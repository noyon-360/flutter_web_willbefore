part of 'route_endpoint.dart';

final authGuardProvider = Provider<AuthGuardState>((ref) {
  final authState = ref.watch(authProvider);
  return AuthGuardState(
    isAuthenticated: authState.isAuthenticated,
    isInitialized: authState.isInitialized,
  );
});

class AuthGuardState {
  final bool isAuthenticated;

  final bool isInitialized;

  AuthGuardState({required this.isAuthenticated, required this.isInitialized});
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteEndpoint.dashboard,

    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final authGuard = container.read(authGuardProvider);

      final isLoginRoute = state.matchedLocation == RouteEndpoint.login;

      // If not authenticated and trying to access proteced route
      if (!authGuard.isAuthenticated && !isLoginRoute) {
        return RouteEndpoint.login;
      }

      // If authenticated and on loing page, redirect to dashboard
      if (authGuard.isAuthenticated && isLoginRoute) {
        return RouteEndpoint.dashboard;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: RouteEndpoint.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // GoRoute(
      //   path: '/signup',
      //   name: 'signup',
      //   builder: (context, state) => const SignupScreen(),
      // ),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardLayout(child: child);
        },
        routes: [
          GoRoute(
            path: RouteEndpoint.dashboard,
            name: 'dashboard',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: RouteEndpoint.categories,
            name: 'categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: RouteEndpoint.products,
            name: 'products',
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-product',
                builder: (context, state) => const AddProductScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                name: 'edit-product',
                builder: (context, state) {
                  final productId = state.pathParameters['id']!;
                  return EditProductScreen(productId: productId);
                },
              ),
              GoRoute(
                path: 'view/:id',
                name: 'view-product',
                builder: (context, state) {
                  final productId = state.pathParameters['id']!;
                  return ProductViewScreen(productId: productId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: RouteEndpoint.ordersDetails, // e.g., 'orders-details/:id'
                name: RouteEndpoint.ordersDetails.split('/:').first,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final order = state.extra as Order?;
                  return OrderDetailsScreen(orderId: id, initialOrder: order);
                },
              ),

              GoRoute(
                path: RouteEndpoint.fullfillOrder, // 'ful-fill-Order/:id'
                name: RouteEndpoint.fullfillOrder.split('/:').first,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final order = state.extra as Order?;
                  return FullfillOrderScreen(orderId: id, initialOrder: order);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteEndpoint.promos,
            name: 'promos',
            builder: (context, state) => const PromosScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-promo',
                builder: (context, state) => const AddPromoScreen(),
              ),
              // GoRoute(
              //   path: 'view',
              //   name: 'add-promo',
              //   builder: (context, state) => const AddPromoScreen(),
              // ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const AllUserProfileScreen(),
            routes: [
              GoRoute(
                path: RouteEndpoint.userDetails, // 'user-details/:id'
                name: RouteEndpoint.userDetails.split('/:').first,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final user = state.extra as UserModel?;
                  return UserDetailScreen(userId: id, initialUser: user);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const AdminSettingScreen(),
          ),
          GoRoute(
            path: RouteEndpoint.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: RouteEndpoint.supportChats,
            name: 'support-chats',
            builder: (context, state) => const SupportChatListScreen(),
            routes: [
              GoRoute(
                path: RouteEndpoint
                    .supportChatDetail, // ':chatId' -> '/support-chats/:chatId'
                name: 'support-chat-detail',
                builder: (context, state) {
                  final chatId = state.pathParameters['chatId']!;
                  final chat = state.extra as ChatModel?;
                  return SupportChatDetailScreen(
                    chatId: chatId,
                    initialChat: chat,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
