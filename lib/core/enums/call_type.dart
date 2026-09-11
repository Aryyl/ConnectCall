/// Represents the type of a call — audio-only or audio+video.
enum CallType {
  audio,
  video;

  String get displayName {
    switch (this) {
      case CallType.audio:
        return 'Audio Call';
      case CallType.video:
        return 'Video Call';
    }
  }

  /// Converts the enum to a string value stored in Firestore.
  String get value => name;

  static CallType fromString(String value) {
    return CallType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallType.audio,
    );
  }
}
