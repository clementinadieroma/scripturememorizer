import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/verse.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/collection/presentation/favorites_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/progress_screen.dart';
import '../features/verse/presentation/browse_screen.dart';
import '../features/verse/presentation/verse_detail_screen.dart';
import 'providers.dart';
import 'shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // MVP: allow guest access to main app; auth routes optional
      if (isLoggedIn && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/browse',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BrowseScreen(),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesScreen(),
            ),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProgressScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/verse',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final verse = state.extra as Verse?;
          if (verse == null) {
            return const Scaffold(
              body: Center(child: Text('Verse not found')),
            );
          }
          return VerseDetailScreen(verse: verse);
        },
      ),
    ],
  );
});

/// Bridges Firebase auth stream to GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
