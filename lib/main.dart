import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'firebase_options.dart';
import 'services/call_service.dart';
import 'services/presence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Register the ZEGOCLOUD offline push (FCM) background message handler.
  /// MUST be called before runApp() so the Dart VM registers the callback
  /// handle during engine setup. When a call arrives and the app is terminated,
  /// ZPNs wakes a background Dart isolate and invokes this handler.
  ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
    [ZegoUIKitSignalingPlugin()],
  );

  /// Register the navigator key BEFORE runApp so that when the app is
  /// cold-started from an offline push notification, ZEGOCLOUD can
  /// immediately push its in-call overlay without waiting for the
  /// Riverpod router provider to be lazily constructed.
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Resolve the initial auth state from the local Firebase cache.
  // This is instantaneous — no network request needed for the token.
  final User? initialUser =
      await FirebaseAuth.instance.authStateChanges().first;

  /// Initialize ZEGOCLOUD HERE, before runApp(), using only the locally
  /// cached Firebase Auth user (no Firestore fetch needed).
  ///
  /// This is the critical fix: when the device wakes from sleep for an
  /// offline call, the user hits "Accept" immediately. With Riverpod
  /// lazy-loading, ZEGOCLOUD wouldn't be ready in time. By initializing
  /// here, we guarantee it's ready before the first frame is painted.
  if (initialUser != null) {
    await CallService.initZegoFromFirebaseUser(initialUser);
    // Mark user online immediately after SDK init.
    // PresenceService registers an onDisconnect handler, so offline is
    // We don't await this so we don't block runApp if the network is slow.
    PresenceService(FirebaseDatabase.instance).startTracking(initialUser);
  }

  runApp(
    ProviderScope(
      child: ConnectCallApp(initialUser: initialUser),
    ),
  );
}
