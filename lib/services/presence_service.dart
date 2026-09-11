import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firebase_constants.dart';

/// Manages online / offline presence using Firebase Realtime Database.
///
/// Presence model per user at `presence/{uid}`:
/// ```json
/// { "online": true, "lastSeen": <timestamp ms> }
/// ```
///
/// On connection, this service writes `online: true` and registers an
/// `onDisconnect` handler that sets `online: false` automatically when the
/// device loses its connection to Firebase.
class PresenceService {
  PresenceService(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _ref(String uid) =>
      _database.ref('${FirebaseConstants.presenceNode}/$uid');

  // ── Own Presence ───────────────────────────────────────────────────────────

  /// Marks the current user online and registers automatic offline-on-disconnect.
  Future<void> goOnline(String uid) async {
    final ref = _ref(uid);
    try {
      // Register disconnect handler FIRST so it fires even if app crashes.
      await ref.onDisconnect().update({
        FirebaseConstants.fieldOnline: false,
        FirebaseConstants.fieldLastSeen: ServerValue.timestamp,
      });
      // Then mark online.
      await ref.update({
        FirebaseConstants.fieldOnline: true,
        FirebaseConstants.fieldLastSeen: ServerValue.timestamp,
      });
      debugPrint('PresenceService: $uid is now online');
    } catch (e) {
      debugPrint('PresenceService: goOnline failed: $e');
    }
  }

  /// Explicitly marks the current user offline (called on logout).
  Future<void> goOffline(String uid) async {
    final ref = _ref(uid);
    try {
      await ref.update({
        FirebaseConstants.fieldOnline: false,
        FirebaseConstants.fieldLastSeen: ServerValue.timestamp,
      });
      debugPrint('PresenceService: $uid is now offline');
    } catch (e) {
      debugPrint('PresenceService: goOffline failed: $e');
    }
  }

  // ── Observe Others ─────────────────────────────────────────────────────────

  /// Returns a stream of `online` status for a single [uid].
  Stream<bool> streamOnlineStatus(String uid) {
    return _ref(uid)
        .child(FirebaseConstants.fieldOnline)
        .onValue
        .map((event) => (event.snapshot.value as bool?) ?? false);
  }

  /// Returns a snapshot stream of the entire presence node.
  /// Used by the provider to build a map of uid → online status.
  Stream<Map<String, bool>> streamAllPresence() {
    return _database
        .ref(FirebaseConstants.presenceNode)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return {};
      final map = Map<String, dynamic>.from(data as Map);
      return map.map((uid, value) {
        final info = Map<String, dynamic>.from(value as Map);
        return MapEntry(uid, (info[FirebaseConstants.fieldOnline] as bool?) ?? false);
      });
    });
  }

  // ── Auth-aware convenience ─────────────────────────────────────────────────

  /// Starts presence tracking for [firebaseUser].
  /// Call this after ZEGOCLOUD init so the presence node is live.
  Future<void> startTracking(User firebaseUser) async {
    await goOnline(firebaseUser.uid);
  }
}
