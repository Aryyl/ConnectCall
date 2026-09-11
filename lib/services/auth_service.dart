import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/app_user.dart';

/// Handles all Firebase Authentication operations and Firestore user document
/// management.
///
/// All Firebase exceptions are caught and re-thrown as typed [AppException]
/// subclasses so the UI layer never has to import firebase_auth directly.
class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ── Auth State ─────────────────────────────────────────────────────────────

  /// Stream of Firebase auth state changes.
  /// Emits null when signed out, non-null when signed in.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user (nullable).
  User? get currentUser => _auth.currentUser;

  // ── Register ───────────────────────────────────────────────────────────────

  /// Creates a new Firebase Auth account and a corresponding Firestore user
  /// document at `users/{uid}`.
  ///
  /// Also sets the Firebase Auth display name for the user.
  ///
  /// Throws [EmailAlreadyInUseException], [WeakPasswordException], or
  /// [UnknownException] on failure.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth account.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // 2. Set display name in Firebase Auth.
      await user.updateDisplayName(name.trim());

      // 3. Create the Firestore user document immediately.
      final appUser = AppUser(
        id: user.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .set(appUser.toMap());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Signs in an existing user with email and password.
  ///
  /// Throws [InvalidCredentialsException] or [UnknownException] on failure.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Signs the current user out of Firebase Auth.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ── Firestore Profile ──────────────────────────────────────────────────────

  /// Fetches the [AppUser] profile from Firestore for the given [uid].
  /// Returns null if the document does not exist.
  Future<AppUser?> fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // ── Exception Mapping ──────────────────────────────────────────────────────

  AppException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'weak-password':
        return const WeakPasswordException();
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return const InvalidCredentialsException();
      case 'too-many-requests':
        return const AuthException(
          'Too many attempts. Please wait a moment and try again.',
        );
      case 'network-request-failed':
        return const NetworkException();
      default:
        return UnknownException(e.message ?? 'Authentication failed.');
    }
  }
}

