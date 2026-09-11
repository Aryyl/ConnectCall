import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../app/router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

/// Splash screen — shown on startup while Firebase auth state is determined.
///
/// Navigation is handled entirely by the GoRouter redirect in [createRouter].
/// This screen simply displays the brand animation and waits — it will be
/// replaced automatically once [authStateProvider] emits a value.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the UI animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // 2. Artificial delay to satisfy assignment requirements (show splash)
    // before moving to the correct screen based on synchronous auth state.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      
      // CRITICAL: If ZEGOCLOUD woke the app from a background call and pushed
      // the call screen, do NOT navigate away! Navigating to contacts would
      // obliterate the calling UI and leave the user stuck on the home screen.
      final isCallActive = ZegoUIKitPrebuiltCallInvitationService().isInCalling;
      if (isCallActive) return;

      final isAuthenticated =
          ref.read(authStateProvider).valueOrNull != null;
      if (isAuthenticated) {
        context.go(AppRoutes.contacts);
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.primary, 
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo container
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 32),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: isDark ? colorScheme.onSurface : Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7) 
                        : Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  color: isDark ? colorScheme.primary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
