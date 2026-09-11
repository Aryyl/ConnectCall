/// Represents whether a call was initiated by the current user or received.
enum CallDirection {
  incoming,
  outgoing;

  String get displayName {
    switch (this) {
      case CallDirection.incoming:
        return 'Incoming';
      case CallDirection.outgoing:
        return 'Outgoing';
    }
  }

  String get value => name;

  static CallDirection fromString(String value) {
    return CallDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallDirection.outgoing,
    );
  }
}
