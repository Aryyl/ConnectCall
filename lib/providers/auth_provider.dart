import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/presence_service.dart';

// ── Service Provider ───────────────────────────────────────────────────────

/// Provides the [AuthService] singleton, injecting Firebase instances.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

// ── Auth State Stream ──────────────────────────────────────────────────────

/// Streams the Firebase auth state.
/// - [AsyncData(null)] → not signed in.
/// - [AsyncData(User)] → signed in.
/// - [AsyncLoading()] → resolving (show splash).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Current AppUser Profile ────────────────────────────────────────────────

/// Fetches the [AppUser] Firestore profile for the currently signed-in user.
/// Returns null if not signed in or profile not yet created.
final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final firebaseUser = authState.valueOrNull;
  if (firebaseUser == null) return null;
  return ref.read(authServiceProvider).fetchUserProfile(firebaseUser.uid);
});

// ── Login Notifier ─────────────────────────────────────────────────────────

/// State for the login form action.
///
/// Null = idle, non-null loading/error/data is communicated via
/// [AsyncValue] on the notifier itself.
class LoginNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Attempts to sign in. On success, [authStateProvider] will automatically
  /// emit the new user and the router redirect will take over — no manual
  /// navigation needed.
  ///
  /// Also initializes ZEGOCLOUD immediately after login using the Firebase
  /// Auth user (no Firestore round-trip), so offline calls work right away.
  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signIn(
            email: email,
            password: password,
          ),
    );
    // Init ZEGOCLOUD + mark online as soon as login succeeds.
    if (state is! AsyncError) {
      final firebaseUser = ref.read(authServiceProvider).currentUser;
      if (firebaseUser != null) {
        await CallService.initZegoFromFirebaseUser(firebaseUser);
        await PresenceService(FirebaseDatabase.instance)
            .startTracking(firebaseUser);
      }
    }
  }
}

final loginProvider = AsyncNotifierProvider<LoginNotifier, void>(
  LoginNotifier.new,
);

// ── Register Notifier ──────────────────────────────────────────────────────

class RegisterNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Attempts to register a new user and create a Firestore profile.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).register(
            name: name,
            email: email,
            password: password,
          ),
    );
    // Init ZEGOCLOUD + mark online as soon as register succeeds.
    if (state is! AsyncError) {
      final firebaseUser = ref.read(authServiceProvider).currentUser;
      if (firebaseUser != null) {
        await CallService.initZegoFromFirebaseUser(firebaseUser);
        await PresenceService(FirebaseDatabase.instance)
            .startTracking(firebaseUser);
      }
    }
  }
}

final registerProvider = AsyncNotifierProvider<RegisterNotifier, void>(
  RegisterNotifier.new,
);

// ── Logout ─────────────────────────────────────────────────────────────────

/// Helper to sign out from anywhere in the app.
/// After calling, [authStateProvider] emits null and the router redirects.
Future<void> signOut(WidgetRef ref) async {
  try {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    // Deinit ZEGOCLOUD first so we stop receiving calls for this user.
    await CallService.deinitZego();
    // Mark offline before signing out so the presence node updates correctly.
    // Do not await this, as Firebase RTDB update() hangs indefinitely if offline.
    if (uid != null) {
      PresenceService(FirebaseDatabase.instance).goOffline(uid).timeout(
            const Duration(seconds: 2),
            onTimeout: () => debugPrint('Presence offline update timed out'),
          );
    }
    await ref.read(authServiceProvider).signOut();
  } on AppException {
    rethrow;
  }
}

// ZEGOCLOUD is now initialized directly in main() (from the Firebase Auth
// user) and on login (in LoginNotifier). The old zegoInitializationProvider
// that waited for a Firestore fetch has been removed to eliminate the race
// condition that caused black screens on offline cold-start calls.
