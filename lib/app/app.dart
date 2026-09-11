import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import 'router.dart';
import 'theme.dart';

/// Root application widget.
class ConnectCallApp extends ConsumerWidget {
  const ConnectCallApp({super.key, required this.initialUser});

  /// The user resolved synchronously in [main] before [runApp].
  /// Passed directly into the router so there is zero async waiting in the UI.
  final User? initialUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider(initialUser));
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ConnectCall',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
