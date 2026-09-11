import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firebase_constants.dart';
import '../models/call_record.dart';

/// Handles reading and writing [CallRecord] entries in Firestore.
///
/// Collection path: `calls/{callId}`
///
/// Both caller and receiver share the same document. Queries filter by
/// `callerId` OR `receiverId` to show history for both parties.
class CallHistoryService {
  CallHistoryService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _calls =>
      _firestore.collection(FirebaseConstants.callsCollection);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Saves a new [CallRecord] to Firestore.
  ///
  /// Called by [CallService] when a ZEGOCLOUD call lifecycle event fires
  /// (completed, missed, or rejected). Documents are upserted using
  /// [SetOptions.merge] so partial updates (e.g., setting endedAt later) work.
  Future<void> logCall(CallRecord record) async {
    try {
      await _calls.doc(record.id).set(record.toMap(), SetOptions(merge: true));
      debugPrint(
        'CallHistoryService: logged call ${record.id} (${record.status.name})',
      );
    } catch (e) {
      debugPrint('CallHistoryService: failed to log call: $e');
    }
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns a real-time stream of the [userId]'s call history, newest first.
  ///
  /// Uses Firestore SDK 4.x compound [Filter.or] so a single query covers
  /// both the caller and receiver sides of every call.
  Stream<List<CallRecord>> streamHistory(String userId) {
    return _calls
        .where(
          Filter.or(
            Filter(FirebaseConstants.fieldCallerId, isEqualTo: userId),
            Filter(FirebaseConstants.fieldReceiverId, isEqualTo: userId),
          ),
        )
        .orderBy(FirebaseConstants.fieldStartedAt, descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => CallRecord.fromFirestore(doc)).toList(),
        );
  }
}
