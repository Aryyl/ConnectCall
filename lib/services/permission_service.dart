import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';

/// Handles platform-level permission checks and settings navigation.
///
/// Responsibilities:
///  - Checking whether the app can use full-screen intents on Android 14+.
///  - Opening the correct Android settings screen for the user to grant
///    the "Display over other apps" (overlay) permission.
///  - Requesting core permissions sequentially on first launch.
///
/// Note: On Android 14+, USE_FULL_SCREEN_INTENT permission is separate from
/// SYSTEM_ALERT_WINDOW. The two are NOT equivalent. This service distinguishes
/// between them using the platform channel approach rather than guessing.
class PermissionService {
  static const _channel = MethodChannel('com.connectcall.permission');

  // ── First Launch Core Permissions ─────────────────────────────────────────

  /// Requests the core permissions required for the app sequentially.
  /// This prevents the Zego SDK from attempting to request them all at once
  /// lazily when a call starts, which often leads to dropped calls or timeouts.
  static Future<void> requestInitialPermissions() async {
    // List of permissions to request in order
    final permissions = [
      Permission.notification,
      Permission.camera,
      Permission.microphone,
      Permission.systemAlertWindow, // Display over other apps
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        // If it's the system alert window, requesting it usually opens the settings screen.
        if (permission == Permission.systemAlertWindow && !status.isGranted) {
          // Wait briefly to ensure smooth UX before jumping to settings.
          await Future.delayed(const Duration(milliseconds: 300));
        }
        await permission.request();
      }
    }
  }

  // ── Full-Screen Intent (Android 14+) ───────────────────────────────────────

  /// Returns true if the app has full-screen intent capability on Android 14+.
  ///
  /// On older Android versions, full-screen intents are always granted, so
  /// this returns true without a native call.
  ///
  /// Uses NotificationManager.canUseFullScreenIntent() on Android 14+.
  static Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } on MissingPluginException {
      // Native side not wired yet — assume granted (fail open).
      return true;
    } catch (e) {
      debugPrint('PermissionService: canUseFullScreenIntent error: $e');
      return true;
    }
  }

  // ── Overlay / Display Over Other Apps ─────────────────────────────────────

  /// Opens the Android "Display over other apps" settings screen for this app.
  ///
  /// On devices where the intent is not available, fails silently — never crashes.
  static Future<void> openOverlaySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openOverlaySettings');
    } on MissingPluginException {
      // Native side not wired — open generic app settings as fallback.
      await _openAppSettings();
    } catch (e) {
      debugPrint('PermissionService: openOverlaySettings error: $e');
      await _openAppSettings();
    }
  }

  /// Opens the Android "Use Full Screen Intents" settings screen on Android 14+.
  ///
  /// On older Android versions, fails silently — the permission is always granted there.
  static Future<void> openFullScreenIntentSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openFullScreenIntentSettings');
    } on MissingPluginException {
      await _openAppSettings();
    } catch (e) {
      debugPrint(
          'PermissionService: openFullScreenIntentSettings error: $e');
      await _openAppSettings();
    }
  }

  static Future<void> _openAppSettings() async {
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } catch (_) {
      // Truly nothing we can do — fail silently.
    }
  }
}
