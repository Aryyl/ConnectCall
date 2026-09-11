/// Base exception class for ConnectCall application errors.
///
/// Use specific subclasses to represent domain-specific failures.
/// The UI layer catches [AppException] and displays user-friendly messages.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ── Auth Exceptions ────────────────────────────────────────────────────────

class AuthException extends AppException {
  const AuthException(super.message);
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Invalid email or password. Please try again.');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super('An account with this email already exists.');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super('Password is too weak. Use at least 6 characters.');
}

// ── Network Exceptions ─────────────────────────────────────────────────────

class NetworkException extends AppException {
  const NetworkException()
      : super('No internet connection. Please check your network settings.');
}

// ── Permission Exceptions ──────────────────────────────────────────────────

class MicrophonePermissionException extends AppException {
  const MicrophonePermissionException()
      : super(
          'Microphone permission is required for audio calls. '
          'Please grant it in your device settings.',
        );
}

class CameraPermissionException extends AppException {
  const CameraPermissionException()
      : super(
          'Camera permission is required for video calls. '
          'Please grant it in your device settings.',
        );
}

// ── Calling Exceptions ─────────────────────────────────────────────────────

class CallFailedException extends AppException {
  const CallFailedException([String? reason])
      : super(reason ?? 'The call could not be established. Please try again.');
}

class UserOfflineException extends AppException {
  const UserOfflineException()
      : super('This user is currently offline and cannot receive calls.');
}

// ── User / Data Exceptions ─────────────────────────────────────────────────

class UserNotFoundException extends AppException {
  const UserNotFoundException() : super('User not found.');
}

class UnknownException extends AppException {
  const UnknownException([String? message])
      : super(message ?? 'An unexpected error occurred. Please try again.');
}
