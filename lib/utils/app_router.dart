// lib/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/create_pin_screen.dart';
import '../screens/lock_screen.dart';
import '../screens/home_screen.dart';
import '../screens/note_edit_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/change_pin_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildPage(
        state,
        const SplashScreen(),
        transitionType: _TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/create-pin',
      pageBuilder: (context, state) => _buildPage(
        state,
        const CreatePinScreen(),
        transitionType: _TransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/lock',
      pageBuilder: (context, state) => _buildPage(
        state,
        const LockScreen(),
        transitionType: _TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _buildPage(
        state,
        const HomeScreen(),
        transitionType: _TransitionType.fade,
      ),
    ),
    GoRoute(
      path: '/note/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'];
        return _buildPage(
          state,
          NoteEditScreen(noteId: id == 'new' ? null : id),
          transitionType: _TransitionType.slideUp,
        );
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _buildPage(
        state,
        const SearchScreen(),
        transitionType: _TransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _buildPage(
        state,
        const SettingsScreen(),
        transitionType: _TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/about',
      pageBuilder: (context, state) => _buildPage(
        state,
        const AboutScreen(),
        transitionType: _TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/privacy',
      pageBuilder: (context, state) => _buildPage(
        state,
        const PrivacyScreen(),
        transitionType: _TransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: '/change-pin',
      pageBuilder: (context, state) => _buildPage(
        state,
        const ChangePinScreen(isFakePin: false),
        transitionType: _TransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: '/change-fake-pin',
      pageBuilder: (context, state) => _buildPage(
        state,
        const ChangePinScreen(isFakePin: true),
        transitionType: _TransitionType.slideUp,
      ),
    ),
  ],
);

enum _TransitionType { fade, slideUp, slideRight }

CustomTransitionPage<void> _buildPage(
  GoRouterState state,
  Widget child, {
  _TransitionType transitionType = _TransitionType.fade,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      switch (transitionType) {
        case _TransitionType.fade:
          return FadeTransition(opacity: curved, child: child);

        case _TransitionType.slideUp:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );

        case _TransitionType.slideRight:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
      }
    },
  );
}
