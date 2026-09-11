import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../core/constants/firebase_constants.dart';
import '../core/constants/zego_config.dart';
import 'package:zego_zpns/zego_zpns.dart';

import '../core/enums/call_direction.dart';
import '../core/enums/call_status.dart';
import '../core/enums/call_type.dart';
import '../models/call_record.dart';
import 'call_history_service.dart';

/// Isolates all ZEGOCLOUD SDK calls. Never call ZEGOCLOUD directly from the UI.
///
/// Lifecycle:
///  1. [initZegoFromFirebaseUser] — called in main() before runApp() and in
///     [LoginNotifier] after login. Uses the Firebase Auth token (no Firestore
///     roundtrip) so ZEGOCLOUD is ready for the "Accept" tap from sleep.
///  2. [deinitZego] — called on logout via [signOut].
///
/// Call history is persisted to Firestore automatically via event handlers
/// wired inside [_initZego].
class CallService {
  static bool _isInitialized = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Initializes ZEGOCLOUD using the locally-cached Firebase [User].
  /// No Firestore round-trip — safe to call in main() before runApp().
  static Future<void> initZegoFromFirebaseUser(User firebaseUser) async {
    final userName = firebaseUser.displayName?.isNotEmpty == true
        ? firebaseUser.displayName!
        : firebaseUser.email ?? 'User';
    return _initZego(
      userId: firebaseUser.uid,
      userName: userName,
    );
  }

  static Future<void> _initZego({
    required String userId,
    required String userName,
  }) async {
    if (_isInitialized) {
      debugPrint('CallService: already initialized.');
      return;
    }
    debugPrint('CallService: initializing for $userId ($userName)');

    // Note: Permissions should NOT be requested here before runApp() is called.
    // They are requested in the UI layer (e.g. ContactsScreen) instead to avoid blocking the splash screen.

    // ── History helper ───────────────────────────────────────────────────────
    final historyService = CallHistoryService(FirebaseFirestore.instance);

    // Tracks calls that are currently active so we can finalize them.
    // Key: callID (from ZEGOCLOUD invitation data), Value: CallRecord draft.
    final Map<String, _ActiveCall> activeCalls = {};

    // Temporary storage for incoming calls so we know who called if we decline/timeout
    final Map<String, _ActiveCall> pendingIncoming = {};

    try {
      ZPNsEventHandler.onRegistered = (ZPNsRegisterMessage message) {
        debugPrint('ZPNs registered: errorCode=${message.errorCode}');
      };

      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: ZegoConfig.appId,
        appSign: ZegoConfig.appSign,
        userID: userId,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],

        // ── Call events (when call starts/ends) ─────────────────────────────
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (
            ZegoCallEndEvent event,
            VoidCallback defaultAction,
          ) {
            // Find any active or pending call for this user
            final active = activeCalls.values.firstWhere(
              (c) => true,
              orElse: () => _ActiveCall(
                callID: 'unknown',
                callerId: userId,
                calleeId: userId,
                callerName: userName,
                calleeName: userName,
                startedAt: DateTime.now(),
              ),
            );

            if (active.callID != 'unknown') {
              final endedAt = DateTime.now();
              final duration = endedAt
                  .difference(active.connectedAt ?? active.startedAt)
                  .inSeconds;
              historyService.logCall(
                active.record.copyWith(
                  status: event.kickerUserID?.isNotEmpty == true
                      ? CallStatus.disconnected
                      : CallStatus.ended,
                  endedAt: endedAt,
                  duration: duration,
                  connectedAt: active.connectedAt,
                ),
              );
              activeCalls.remove(active.callID);
            }
            defaultAction();
          },
        ),

        // ── Call config ────────────────────────────────────────────────────
        requireConfig: (ZegoCallInvitationData data) {
          final isVideo = ZegoCallInvitationType.videoCall == data.type;
          final isGroup = data.invitees.length > 1;

          final config = isGroup
              ? isVideo
                  ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
              : isVideo
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

          // Use gallery layout for video calls so screen sharing content
          // is visible to the other party. The gallery layout is the only
          // layout in the Zego SDK that renders shared screens correctly.
          if (isVideo) {
            config.layout = ZegoLayout.gallery(
              addBorderRadiusAndSpacingBetweenView: false,
            );
            // Auto-expand shared screen to full screen for a better experience
            config.screenSharing = ZegoCallScreenSharingConfig(
              defaultFullScreen: true,
            );
          }

          // Replace the entire bottomMenuBar config with a fresh object
          // to avoid issues with const-list mutation in the SDK's defaults.
          config.bottomMenuBar = ZegoCallBottomMenuBarConfig(
            maxCount: 6,
            buttons: isVideo
                ? [
                    ZegoCallMenuBarButtonName.toggleCameraButton,
                    ZegoCallMenuBarButtonName.switchCameraButton,
                    ZegoCallMenuBarButtonName.hangUpButton,
                    ZegoCallMenuBarButtonName.toggleMicrophoneButton,
                    ZegoCallMenuBarButtonName.switchAudioOutputButton,
                    ZegoCallMenuBarButtonName.toggleScreenSharingButton,
                  ]
                : [
                    ZegoCallMenuBarButtonName.hangUpButton,
                    ZegoCallMenuBarButtonName.toggleMicrophoneButton,
                    ZegoCallMenuBarButtonName.switchAudioOutputButton,
                    ZegoCallMenuBarButtonName.toggleScreenSharingButton,
                  ],
          );

          // Move pending incoming call to active
          if (pendingIncoming.containsKey(data.callID)) {
            final pending = pendingIncoming.remove(data.callID)!;
            activeCalls[data.callID] = _ActiveCall(
              callID: data.callID,
              callerId: pending.callerId,
              calleeId: pending.calleeId,
              callerName: pending.callerName,
              calleeName: pending.calleeName,
              startedAt: pending.startedAt,
              connectedAt: DateTime.now(),
            );
          }

          return config;
        },

        // ── Invitation events ──────────────────────────────────────────────
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          // ── Outgoing call accepted — start tracking active call ─────────
          onOutgoingCallAccepted: (String callID, ZegoCallUser callee) {
            activeCalls[callID] = _ActiveCall(
              callID: callID,
              callerId: userId,
              calleeId: callee.id,
              callerName: userName,
              calleeName: callee.name,
              startedAt: DateTime.now(),
              connectedAt: DateTime.now(),
            );
          },

          // ── Outgoing call declined by callee ────────────────────────────
          onOutgoingCallDeclined: (String callID, ZegoCallUser callee, String customData) {
            historyService.logCall(
              CallRecord(
                id: callID.isNotEmpty ? callID : const Uuid().v4(),
                callerId: userId,
                receiverId: callee.id,
                callerName: userName,
                receiverName: callee.name,
                callType: CallType.audio,
                direction: CallDirection.outgoing,
                status: CallStatus.rejected,
                startedAt: DateTime.now(),
              ),
            );
          },

          // ── Outgoing call timeout (no answer) ───────────────────────────
          onOutgoingCallTimeout: (String callID, List<ZegoCallUser> callees, bool isVideoCall) {
            for (final callee in callees) {
              historyService.logCall(
                CallRecord(
                  id: callID.isNotEmpty ? callID : const Uuid().v4(),
                  callerId: userId,
                  receiverId: callee.id,
                  callerName: userName,
                  receiverName: callee.name,
                  callType: isVideoCall ? CallType.video : CallType.audio,
                  direction: CallDirection.outgoing,
                  status: CallStatus.missed,
                  startedAt: DateTime.now(),
                ),
              );
            }
          },

          // ── Incoming call received — temp tracking ──────────────────────
          onIncomingCallReceived: (String callID, ZegoCallUser caller, ZegoCallInvitationType callType, List<ZegoCallUser> callees, String customData) async {
            try {
              // Fetch latest user document to check blocked users
              final userDoc = await FirebaseFirestore.instance
                  .collection(FirebaseConstants.usersCollection)
                  .doc(userId)
                  .get(const GetOptions(source: Source.serverAndCache));
              
              final blockedUsers = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);
              
              if (blockedUsers.contains(caller.id)) {
                debugPrint('CallService: Auto-rejecting call from blocked user ${caller.id}');
                ZegoUIKitPrebuiltCallInvitationService().reject(customData: 'User is blocked');
                return;
              }
            } catch (e) {
              debugPrint('CallService: Error checking block list: $e');
            }

            pendingIncoming[callID] = _ActiveCall(
              callID: callID,
              callerId: caller.id,
              calleeId: userId,
              callerName: caller.name,
              calleeName: userName,
              startedAt: DateTime.now(),
            );
          },

          // ── Incoming call not answered (timeout) ────────────────────────
          onIncomingCallTimeout: (String callID, ZegoCallUser caller) {
            historyService.logCall(
              CallRecord(
                id: callID.isNotEmpty ? callID : const Uuid().v4(),
                callerId: caller.id,
                receiverId: userId,
                callerName: caller.name,
                receiverName: userName,
                callType: CallType.audio,
                direction: CallDirection.incoming,
                status: CallStatus.missed,
                startedAt: DateTime.now(),
              ),
            );
            pendingIncoming.remove(callID);
          },
        ),

        // ── Notification config ────────────────────────────────────────────
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoCallAndroidNotificationConfig(
            showOnFullScreen: true,
            showOnLockedScreen: true,
            callChannel: ZegoCallAndroidNotificationChannelConfig(
              channelID: 'ConnectCallChannel',
              channelName: 'Incoming Calls',
            ),
          ),
        ),
      );

      _isInitialized = true;
      debugPrint('CallService: initialization complete.');
    } catch (e) {
      debugPrint('CallService: initialization error: $e');
      _isInitialized = false;
    }
  }

  // ── Deinit ─────────────────────────────────────────────────────────────────

  /// Uninitializes ZEGOCLOUD. Must be called on logout.
  static Future<void> deinitZego() async {
    if (!_isInitialized) return;
    debugPrint('CallService: uninitializing.');
    try {
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      _isInitialized = false;
      debugPrint('CallService: uninitialization complete.');
    } catch (e) {
      debugPrint('CallService: uninitialization error: $e');
    }
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

/// Tracks an in-progress call so we can compute duration when it ends.
class _ActiveCall {
  _ActiveCall({
    required this.callID,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
    required this.calleeName,
    required this.startedAt,
    this.connectedAt,
  });

  final String callID;
  final String callerId;
  final String calleeId;
  final String callerName;
  final String calleeName;
  final DateTime startedAt;
  final DateTime? connectedAt;

  CallRecord get record => CallRecord(
        id: callID,
        callerId: callerId,
        receiverId: calleeId,
        callerName: callerName,
        receiverName: calleeName,
        callType: CallType.audio,
        direction: callerId == calleeId
            ? CallDirection.outgoing
            : CallDirection.outgoing,
        status: CallStatus.inCall,
        startedAt: startedAt,
        connectedAt: connectedAt,
      );
}
