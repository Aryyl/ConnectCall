/// Utilities for handling runtime permissions (microphone, camera).
///
/// All permission logic is centralised here so screens never interact
/// directly with the permission_handler package.
library;

import 'package:permission_handler/permission_handler.dart';

import '../errors/app_exception.dart';

class PermissionUtils {
  PermissionUtils._();

  /// Requests microphone permission for audio calls.
  /// Throws [MicrophonePermissionException] if denied or permanently denied.
  static Future<void> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw const MicrophonePermissionException();
    }
  }

  /// Requests both microphone and camera permissions for video calls.
  /// Throws [MicrophonePermissionException] or [CameraPermissionException]
  /// if either is denied or permanently denied.
  static Future<void> requestVideoCallPermissions() async {
    final statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    final micStatus = statuses[Permission.microphone]!;
    final camStatus = statuses[Permission.camera]!;

    if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
      throw const MicrophonePermissionException();
    }
    if (camStatus.isDenied || camStatus.isPermanentlyDenied) {
      throw const CameraPermissionException();
    }
  }

  /// Checks if microphone permission is currently granted.
  static Future<bool> hasMicrophonePermission() async {
    return Permission.microphone.isGranted;
  }

  /// Checks if camera permission is currently granted.
  static Future<bool> hasCameraPermission() async {
    return Permission.camera.isGranted;
  }

  /// Opens the device app settings so the user can manually grant permissions.
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
