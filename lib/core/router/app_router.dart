import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/dashboard/views/dashboard_page.dart';
import '../../features/login/views/login_page.dart';
import '../auth/auth_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.status == AuthStatus.authenticated;
      final isInitializing = authProvider.status == AuthStatus.unknown;
      final isLoginRoute = state.matchedLocation == '/login';

      if (isInitializing) return null;
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      if (!isAuthenticated && !isLoginRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
    ],
  );
}

class AppRouterProvider extends StatelessWidget {
  const AppRouterProvider({super.key, required this.builder});

  final Widget Function(BuildContext context, GoRouter router) builder;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final router = buildAppRouter(authProvider);
    return builder(context, router);
  }
}
