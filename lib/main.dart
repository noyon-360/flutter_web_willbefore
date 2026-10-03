import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_willbefore/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_strategy/url_strategy.dart';

import 'core/routes/route_endpoint.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

final FirebaseFunctions functions = FirebaseFunctions.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  await NotificationService().initialize();

  // functions.useFunctionsEmulator('localhost', 5001);

  setPathUrlStrategy();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(
    //   const SystemUiOverlayStyle(
    //     statusBarColor: Colors.transparent,
    //     statusBarIconBrightness: Brightness.dark,
    //   ),
    // );

    return ProviderScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: AppTheme.light,

        routerConfig: AppRouter.router,
        builder: (context, child) => _AuthGate(child: child),
      ),
    );
  }
}

/// Holds the UI back until the persisted Firebase session is restored, and
/// tells the router to re-evaluate its redirect when auth state changes.
class _AuthGate extends ConsumerWidget {
  const _AuthGate({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (prev, next) {
      if (prev?.isAuthenticated != next.isAuthenticated ||
          prev?.isInitialized != next.isInitialized) {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        AppRouter.refresh.notifyListeners();
      }
    });

    if (!ref.watch(authProvider.select((s) => s.isInitialized))) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child ?? const SizedBox.shrink();
  }
}
