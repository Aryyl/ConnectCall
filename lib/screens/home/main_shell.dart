import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/permission_service.dart';
import '../../services/welcome_service.dart';
import '../../widgets/welcome_dialog.dart';

/// Persistent bottom-navigation shell used by [StatefulShellRoute].
///
/// The shell holds three tabs:
///   0 — Contacts  (/contacts)
///   1 — Recents   (/history)
///   2 — Profile   (/profile)
///
/// [StatefulShellRoute] keeps each branch alive, so scroll positions and
/// loaded data survive tab switches.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _welcomeChecked = false;

  @override
  void initState() {
    super.initState();
    // Defer until the first frame so the dialog has a valid context/overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  Future<void> _maybeShowWelcome() async {
    if (_welcomeChecked || !mounted) return;
    _welcomeChecked = true;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final shouldShow = await WelcomeService.shouldShowWelcome(uid);
    
    if (shouldShow && mounted) {
      // Mark as seen before showing so re-entrancy/restarts don't re-show.
      await WelcomeService.markWelcomeSeen(uid);

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const WelcomeDialog(),
        );
      }
    }

    // After the welcome dialog (or immediately if not shown), request core permissions
    if (mounted) {
      // Defer to the next frame to ensure dialog cleanup doesn't interfere
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await PermissionService.requestInitialPermissions();
      });
    }
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      // If user taps the already-active tab, pop to the branch root.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Recents',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
