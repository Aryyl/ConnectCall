/// Firestore and Firebase Realtime Database path constants.
library;

class FirebaseConstants {
  FirebaseConstants._();

  // ── Firestore Collections ─────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String callsCollection = 'calls';

  // ── User Document Fields ──────────────────────────────────────────────────
  static const String fieldId = 'id';
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPhotoUrl = 'photoUrl';
  static const String fieldCreatedAt = 'createdAt';

  // ── Call Document Fields ──────────────────────────────────────────────────
  static const String fieldCallerId = 'callerId';
  static const String fieldReceiverId = 'receiverId';
  static const String fieldCallType = 'callType';
  static const String fieldDirection = 'direction';
  static const String fieldStatus = 'status';
  static const String fieldStartedAt = 'startedAt';
  static const String fieldConnectedAt = 'connectedAt';
  static const String fieldEndedAt = 'endedAt';
  static const String fieldDuration = 'duration';

  // ── Realtime Database ─────────────────────────────────────────────────────
  static const String presenceNode = 'presence';
  static const String fieldOnline = 'online';
  static const String fieldLastSeen = 'lastSeen';
}
