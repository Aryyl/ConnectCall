import 'package:flutter/material.dart';

/// ConnectCall design system.
///
/// Color palette: Forest green primary, clean neutral backgrounds.
class AppTheme {
  AppTheme._();

  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF059669); // Forest Green / Emerald-600
  static const Color _primaryDark = Color(0xFF047857);
  static const Color _primaryLight = Color(0xFFD1FAE5);
  static const Color _accent = Color(0xFF10B981);

  // ── Status Colors ──────────────────────────────────────────────────────────
  static const Color _success = Color(0xFF10B981);
  static const Color _error = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);

  // ── Presence Colors ────────────────────────────────────────────────────────
  static const Color onlineColor = Color(0xFF10B981);
  static const Color offlineColor = Color(0xFF9CA3AF);

  // ── Call Action Colors ─────────────────────────────────────────────────────
  static const Color callGreen = Color(0xFF22C55E);
  static const Color callRed = Color(0xFFEF4444);

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: _primaryLight,
      onPrimaryContainer: _primaryDark,
      secondary: _accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFECFDF5),
      onSecondaryContainer: Color(0xFF065F46),
      error: _error,
      onError: Colors.white,
      surface: Color(0xFFFAFAFC),
      onSurface: Color(0xFF111827),
      outline: Color(0xFFE5E7EB),
      outlineVariant: Color(0xFFF3F4F6),
      surfaceContainerLow: Color(0xFFFFFFFF),
      surfaceContainer: Color(0xFFF9FAFB),
      surfaceContainerHigh: Color(0xFFF3F4F6),
    );

    return _buildTheme(colorScheme);
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: _primaryDark,
      onPrimaryContainer: _primaryLight,
      secondary: _accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF064E3B),
      onSecondaryContainer: Color(0xFFD1FAE5),
      error: _error,
      onError: Colors.white,
      surface: Colors.black,
      onSurface: Color(0xFFF9FAFB),
      outline: Color(0xFF374151),
      outlineVariant: Color(0xFF1F2937),
      surfaceContainerLow: Color(0xFF121212),
      surfaceContainer: Colors.black,
      surfaceContainerHigh: Color(0xFF1E1E1E),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? colorScheme.surface : Colors.white,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error, width: 2),
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(
          color: _error,
          fontSize: 12,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedItemColor: _primary,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Text styles
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        displaySmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),

      // Extension colors
      extensions: [
        AppColors(
          success: _success,
          warning: _warning,
          online: onlineColor,
          offline: offlineColor,
          callGreen: callGreen,
          callRed: callRed,
          primaryLight: _primaryLight,
        ),
      ],
    );
  }
}

/// Custom theme extension for semantic colors not in Material's ColorScheme.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.online,
    required this.offline,
    required this.callGreen,
    required this.callRed,
    required this.primaryLight,
  });

  final Color success;
  final Color warning;
  final Color online;
  final Color offline;
  final Color callGreen;
  final Color callRed;
  final Color primaryLight;

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? online,
    Color? offline,
    Color? callGreen,
    Color? callRed,
    Color? primaryLight,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      online: online ?? this.online,
      offline: offline ?? this.offline,
      callGreen: callGreen ?? this.callGreen,
      callRed: callRed ?? this.callRed,
      primaryLight: primaryLight ?? this.primaryLight,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      callGreen: Color.lerp(callGreen, other.callGreen, t)!,
      callRed: Color.lerp(callRed, other.callRed, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
    );
  }
}
