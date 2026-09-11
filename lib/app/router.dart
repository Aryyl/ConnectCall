import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/history/call_history_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';

// ── Route Names ─────────────────────────────────────────────────────────────

abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  // Shell branches
  static const String contacts = '/contacts';
  static const String history = '/history';
  static const String profile = '/profile';
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(User? initialUser) : _currentUser = initialUser {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _currentUser?.uid) {
        _currentUser = user;
        notifyListeners();
      }
    });
  }

  User? _currentUser;
  User? get currentUser => _currentUser;

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Navigator Key ─────────────────────────────────────────────────────────────

final navigatorKey = GlobalKey<NavigatorState>();

// ── Router Provider ───────────────────────────────────────────────────────────

final routerProvider = Provider.family<GoRouter, User?>((ref, initialUser) {
  final authNotifier = _AuthNotifier(initialUser);
  ref.onDispose(authNotifier.dispose);

  // ZEGOCLOUD navigator key is set in main.dart before runApp() to avoid a
  // race condition on cold-start from an offline push notification.

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthenticated = authNotifier.currentUser != null;
      final isAuthPage =
          location == AppRoutes.login || location == AppRoutes.register;

      // Let the SplashScreen widget handle its own timer + navigation.
      if (location == AppRoutes.splash) return null;

      if (!isAuthenticated) {
        return isAuthPage ? null : AppRoutes.login;
      } else {
        // Authenticated users must not sit on auth / splash pages.
        if (isAuthPage || location == AppRoutes.splash) {
          // If ZEGOCLOUD currently has an active call (e.g. the app was
          // cold-started by accepting an offline call notification), skip
          // the redirect entirely. ZEGOCLOUD manages its own call screen on
          // top of the Navigator stack — forcing a go('/contacts') here
          // would wipe it out.
          final isCallActive =
              ZegoUIKitPrebuiltCallInvitationService().isInCalling;
          if (isCallActive) return null;
          return AppRoutes.contacts;
        }
        return null;
      }
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Persistent Shell (bottom navigation) ────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          // Branch 0 — Contacts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.contacts,
                name: 'contacts',
                builder: (context, state) => const ContactsScreen(),
              ),
            ],
          ),
          // Branch 1 — Recents
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                name: 'history',
                builder: (context, state) => const CallHistoryScreen(),
              ),
            ],
          ),
          // Branch 2 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
