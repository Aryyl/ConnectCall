import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the per-user welcome/onboarding dialog has been shown.
///
/// State key: `has_seen_welcome_<uid>` — scoped to the authenticated user UID
/// so each user on the same device gets their own independent first-login
/// experience.
class WelcomeService {
  static const String _keyPrefix = 'has_seen_welcome_';

  /// Returns true if the welcome dialog should be shown for [uid].
  ///
  /// Returns false (skip) when:
  ///  - [uid] is empty / null.
  ///  - The flag has been previously persisted for this [uid].
  static Future<bool> shouldShowWelcome(String uid) async {
    if (uid.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('$_keyPrefix$uid') ?? false;
      return !seen;
    } catch (e) {
      debugPrint('WelcomeService: shouldShowWelcome error: $e');
      return false; // Fail safe — don't spam the user if prefs are broken
    }
  }

  /// Persists that the welcome dialog has been shown for [uid].
  /// After calling this, [shouldShowWelcome] will return false for this user.
  static Future<void> markWelcomeSeen(String uid) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_keyPrefix$uid', true);
    } catch (e) {
      debugPrint('WelcomeService: markWelcomeSeen error: $e');
    }
  }
}
