import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firebase_constants.dart';
import '../core/enums/call_direction.dart';
import '../core/enums/call_status.dart';
import '../core/enums/call_type.dart';

/// Represents a single call log entry stored in Firestore.
class CallRecord {
  const CallRecord({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.duration = 0,
    this.callerName,
    this.receiverName,
    this.callerPhotoUrl,
    this.receiverPhotoUrl,
  });

  final String id;
  final String callerId;
  final String receiverId;
  final CallType callType;
  final CallDirection direction;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;

  /// Duration in seconds. 0 for missed/rejected calls.
  final int duration;

  // Denormalised for display without extra Firestore reads
  final String? callerName;
  final String? receiverName;
  final String? callerPhotoUrl;
  final String? receiverPhotoUrl;

  // ── Serialisation ──────────────────────────────────────────────────────────

  factory CallRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallRecord(
      id: doc.id,
      callerId: data[FirebaseConstants.fieldCallerId] as String? ?? '',
      receiverId: data[FirebaseConstants.fieldReceiverId] as String? ?? '',
      callType: CallType.fromString(
        data[FirebaseConstants.fieldCallType] as String? ?? 'audio',
      ),
      direction: CallDirection.fromString(
        data[FirebaseConstants.fieldDirection] as String? ?? 'outgoing',
      ),
      status: CallStatus.fromString(
        data[FirebaseConstants.fieldStatus] as String? ?? 'ended',
      ),
      startedAt:
          (data[FirebaseConstants.fieldStartedAt] as Timestamp?)?.toDate() ??
              DateTime.now(),
      connectedAt:
          (data[FirebaseConstants.fieldConnectedAt] as Timestamp?)?.toDate(),
      endedAt:
          (data[FirebaseConstants.fieldEndedAt] as Timestamp?)?.toDate(),
      duration: data[FirebaseConstants.fieldDuration] as int? ?? 0,
      callerName: data['callerName'] as String?,
      receiverName: data['receiverName'] as String?,
      callerPhotoUrl: data['callerPhotoUrl'] as String?,
      receiverPhotoUrl: data['receiverPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.fieldCallerId: callerId,
      FirebaseConstants.fieldReceiverId: receiverId,
      FirebaseConstants.fieldCallType: callType.value,
      FirebaseConstants.fieldDirection: direction.value,
      FirebaseConstants.fieldStatus: status.value,
      FirebaseConstants.fieldStartedAt: Timestamp.fromDate(startedAt),
      FirebaseConstants.fieldConnectedAt:
          connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
      FirebaseConstants.fieldEndedAt:
          endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      FirebaseConstants.fieldDuration: duration,
      'callerName': callerName,
      'receiverName': receiverName,
      'callerPhotoUrl': callerPhotoUrl,
      'receiverPhotoUrl': receiverPhotoUrl,
    };
  }

  // ── Display Helpers ────────────────────────────────────────────────────────

  bool get isMissed =>
      status == CallStatus.missed || status == CallStatus.rejected;

  bool get isIncoming => direction == CallDirection.incoming;
  bool get isOutgoing => direction == CallDirection.outgoing;

  // ── copyWith ───────────────────────────────────────────────────────────────

  CallRecord copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    CallType? callType,
    CallDirection? direction,
    CallStatus? status,
    DateTime? startedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    int? duration,
    String? callerName,
    String? receiverName,
    String? callerPhotoUrl,
    String? receiverPhotoUrl,
  }) {
    return CallRecord(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callType: callType ?? this.callType,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      callerName: callerName ?? this.callerName,
      receiverName: receiverName ?? this.receiverName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CallRecord && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
