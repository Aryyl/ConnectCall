/// Application-wide constants for ConnectCall.
///
/// ZEGOCLOUD credentials are loaded from this file.
/// Do NOT hardcode real AppSign here if committing to a public repository.
/// Instead, set the values in a local zego_config.dart (which is .gitignored).
library;

class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName = 'ConnectCall';
  static const String appTagline = 'Connect with anyone, anywhere.';
  static const String appVersion = '1.0.0';

  // ── ZEGOCLOUD ─────────────────────────────────────────────────────────────
  // Replace these with your real values from https://console.zegocloud.com/
  // For production / public repos, move these to a local .gitignored file.
  static const int zegoAppId = 0; // TODO: Replace with your ZEGOCLOUD App ID
  static const String zegoAppSign = ''; // TODO: Replace with your App Sign

  // ── Firestore Collections ─────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String callsCollection = 'calls';

  // ── Firebase Realtime Database ────────────────────────────────────────────
  static const String presenceNode = 'presence';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration callTimeout = Duration(seconds: 60);

  // ── UI Spacing ────────────────────────────────────────────────────────────
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // ── Avatar ────────────────────────────────────────────────────────────────
  static const double avatarSizeSM = 36.0;
  static const double avatarSizeMD = 48.0;
  static const double avatarSizeLG = 72.0;
  static const double avatarSizeXL = 96.0;
}
