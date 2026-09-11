import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/call_record.dart';
import '../services/call_history_service.dart';
import '../services/presence_service.dart';
import 'auth_provider.dart';

// ── Call History ──────────────────────────────────────────────────────────────

/// Provides the [CallHistoryService] singleton.
final callHistoryServiceProvider = Provider<CallHistoryService>((ref) {
  return CallHistoryService(FirebaseFirestore.instance);
});

/// Streams the current user's call history from Firestore (newest first).
final callHistoryProvider = StreamProvider<List<CallRecord>>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = authState.valueOrNull;

  if (currentUser == null) return Stream.value([]);

  final service = ref.watch(callHistoryServiceProvider);
  return service.streamHistory(currentUser.uid);
});

// ── Presence ──────────────────────────────────────────────────────────────────

/// Provides the [PresenceService] singleton.
final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService(FirebaseDatabase.instance);
});

/// Streams the full presence map: uid → isOnline.
///
/// The [ContactsScreen] watches this and overlays the green dot on each
/// contact's avatar without fetching any Firestore documents.
final presenceMapProvider = StreamProvider<Map<String, bool>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return Stream.value({});

  final service = ref.watch(presenceServiceProvider);
  return service.streamAllPresence();
});
