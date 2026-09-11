import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../models/app_user.dart';
import '../models/call_record.dart';
import '../core/enums/call_type.dart';

// ── Calling Actions ────────────────────────────────────────────────────────────

/// Sends an audio call invitation to [user] via ZEGOCLOUD.
///
/// All ZEGOCLOUD SDK code lives here — never import ZegoKit directly in screens.
void startAudioCall(AppUser user) {
  ZegoUIKitPrebuiltCallInvitationService().send(
    isVideoCall: false,
    invitees: [ZegoCallUser(user.id, user.name)],
    resourceID: 'zegouikit_call',
  );
}

/// Sends a video call invitation to [user] via ZEGOCLOUD.
void startVideoCall(AppUser user) {
  ZegoUIKitPrebuiltCallInvitationService().send(
    isVideoCall: true,
    invitees: [ZegoCallUser(user.id, user.name)],
    resourceID: 'zegouikit_call',
  );
}

/// Calls back the other party in a [record].
/// Determines call type from the record and uses the correct target UID.
void callBack(WidgetRef ref, CallRecord record, String currentUserId) {
  final targetId =
      record.callerId == currentUserId ? record.receiverId : record.callerId;
  final targetName = record.callerId == currentUserId
      ? (record.receiverName ?? targetId)
      : (record.callerName ?? targetId);

  if (record.callType == CallType.video) {
    ZegoUIKitPrebuiltCallInvitationService().send(
      isVideoCall: true,
      invitees: [ZegoCallUser(targetId, targetName)],
      resourceID: 'zegouikit_call',
    );
  } else {
    ZegoUIKitPrebuiltCallInvitationService().send(
      isVideoCall: false,
      invitees: [ZegoCallUser(targetId, targetName)],
      resourceID: 'zegouikit_call',
    );
  }
}

/// Stub provider — ZEGOCLOUD manages active call state internally.
/// Expose this if we ever need to show an in-app call status indicator.
final callingProvider = Provider<Object?>((ref) => null);
