/// Represents all possible states a call can be in.
///
/// The UI observes this through CallingProvider and reacts accordingly.
/// Avoid scattered boolean flags like isCalling / isConnected — use this enum.
enum CallStatus {
  /// No active or pending call.
  idle,

  /// Outgoing call is being initiated (dialling).
  calling,

  /// Remote user's device is ringing.
  ringing,

  /// Remote user accepted, establishing media streams.
  connected,

  /// Media is flowing — both parties are in the call.
  inCall,

  /// Call ended normally.
  ended,

  /// Remote user explicitly declined the call.
  rejected,

  /// No response received within the timeout window.
  missed,

  /// Remote user is on another call.
  busy,

  /// An error prevented the call from connecting.
  failed,

  /// The call dropped due to network or connection issues.
  disconnected;

  bool get isActive => this == CallStatus.inCall || this == CallStatus.connected;
  bool get isTerminal =>
      this == CallStatus.ended ||
      this == CallStatus.rejected ||
      this == CallStatus.missed ||
      this == CallStatus.failed ||
      this == CallStatus.disconnected;

  String get value => name;

  static CallStatus fromString(String value) {
    return CallStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallStatus.idle,
    );
  }
}
