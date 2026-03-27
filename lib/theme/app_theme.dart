import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// Design System Constants
// ──────────────────────────────────────────────

/// Spacing scale based on 8dp grid — tablet-optimised
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Consistent border radii
class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 28;
  static const double xl = 36;

  static BorderRadius get smallBR => BorderRadius.circular(sm);
  static BorderRadius get mediumBR => BorderRadius.circular(md);
  static BorderRadius get largeBR => BorderRadius.circular(lg);
  static BorderRadius get xlBR => BorderRadius.circular(xl);
}

/// Reusable soft shadow presets
class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x05000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> get card => [
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static List<BoxShadow> get elevated => [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
}

/// Typography scale — tablet-optimised for 10" screens
class AppTextStyles {
  // Font sizes — bumped for tablet readability & accessibility
  static const double headingSize = 34;
  static const double titleSize = 25;
  static const double bodySize = 20;
  static const double labelSize = 18;
  static const double captionSize = 16;

  // Weights — only 3
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;
}

/// Standard touch target & button sizes — tablet-optimised
class AppSizes {
  static const double minTouchTarget = 56;
  static const double buttonHeightLg = 62;
  static const double buttonHeightMd = 56;
  static const double buttonHeightSm = 48;
  static const double iconSizeLg = 30;
  static const double iconSizeMd = 26;
  static const double iconSizeSm = 22;
}

// ──────────────────────────────────────────────
// Colors
// ──────────────────────────────────────────────

class AppColors {
  // Primary brand colors — dark teal/sage
  static const navy = Color(0xFF384845);
  static const navyLight = Color(0xFF4A5D5A);
  static const navyDark = Color(0xFF2B3836);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFE2C76E);
  static const goldDark = Color(0xFFB8943A);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF8F8F8);
  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575); // Min for text on white (4.6:1)
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  // Status colors
  static const statusSubmitted = Color(0xFF2196F3); // Blue
  static const statusApproved = Color(0xFF4CAF50);  // Green
  static const statusRejected = Color(0xFFE53935);  // Red
  static const statusCollected = Color(0xFFFF9800);  // Orange
  static const statusInProcessing = Color(0xFFFF9800); // Amber
  static const statusReceived = Color(0xFF26A69A);   // Teal
  static const statusCompleted = Color(0xFF4CAF50);  // Green

  // Functional
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const info = Color(0xFF2196F3);

  // Sync indicator
  static const syncOnline = Color(0xFF4CAF50);
  static const syncSyncing = Color(0xFFFFC107);
  static const syncOffline = Color(0xFFE53935);
}

// ──────────────────────────────────────────────
// Theme
// ──────────────────────────────────────────────

class AppTheme {
  static ThemeData get theme {
    final baseTextTheme = ThemeData().textTheme.apply(fontFamily: 'Inter');

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.navyLight,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        secondaryContainer: AppColors.goldLight,
        surface: AppColors.white,
        onSurface: AppColors.grey900,
        error: AppColors.error,
        onError: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.offWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.navyDark.withValues(alpha: 0.3),
        centerTitle: true,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(fontFamily: 'Inter',
          fontSize: AppTextStyles.titleSize,
          fontWeight: AppTextStyles.medium,
          color: AppColors.white,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColors.navy,
          fontWeight: AppTextStyles.bold,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.navy,
          fontWeight: AppTextStyles.bold,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.navy,
          fontWeight: AppTextStyles.medium,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.navy,
          fontWeight: AppTextStyles.medium,
          fontSize: AppTextStyles.titleSize,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.grey800,
          fontWeight: AppTextStyles.medium,
          fontSize: AppTextStyles.bodySize,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.grey800,
          fontSize: AppTextStyles.bodySize,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.grey700,
          fontSize: AppTextStyles.labelSize,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: AppTextStyles.medium,
          fontSize: AppTextStyles.labelSize,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          minimumSize: const Size(140, AppSizes.buttonHeightMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumBR,
          ),
          textStyle: TextStyle(fontFamily: 'Inter',
            fontSize: AppTextStyles.labelSize,
            fontWeight: AppTextStyles.medium,
          ),
          elevation: 2,
          shadowColor: AppColors.navy.withValues(alpha: 0.25),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          minimumSize: const Size(120, AppSizes.buttonHeightMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumBR,
          ),
          textStyle: TextStyle(fontFamily: 'Inter',
            fontSize: AppTextStyles.labelSize,
            fontWeight: AppTextStyles.medium,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.navy.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumBR,
          side: BorderSide(color: AppColors.grey200, width: 1),
        ),
        color: AppColors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mediumBR,
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBR,
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBR,
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBR,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.base,
        ),
        hintStyle: TextStyle(fontFamily: 'Inter',
          fontSize: AppTextStyles.bodySize,
          color: AppColors.grey400,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey200,
        thickness: 1,
      ),
    );
  }
}
