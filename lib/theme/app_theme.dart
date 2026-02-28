import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/motion/premium_page_transition.dart';

class AppColors {
  // Backgrounds
  static const Color primaryBackground = Color(
    0xFFFAF8F5,
  ); // Soft Warm Off-White
  static const Color surface = Colors.white;
  static const Color secondarySurface = Color(0xFFFFF3EC); // Very Light Peach

  // Borders
  static const Color border = Color(0xFFEEEAE6);

  // Text
  static const Color textPrimary = Color(0xFF1F2A44); // Deep Navy
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);
  static const Color textDisabled = Color(0xFFA0AEC0);

  // Accents / Actions
  static const Color primaryBrand = Color(0xFFFF6A2B); // Soft Vibrant Orange
  static const Color primaryNavy = Color(0xFF1F2A44); // Deep Navy
  static const Color success = Color(0xFF2ECC71); // Success Green
  static const Color warning = Color(0xFFE85D5D); // Gentle Error Red

  // Scenario Colors
  static const Color scenarioRizz = Color(0xFFFF8A80);
  static const Color scenarioFamily = Color(0xFFFFD54F);
  static const Color scenarioBusiness = Color(0xFF4DD0E1);
  static const Color scenarioConflict = Color(0xFF9575CD);
  static const Color scenarioNegotiation = Color(0xFF81C784);
  static const Color parotYellow = Color(0xFFFFD700);

  static Color getScenarioColor(String type) {
    switch (type.toLowerCase()) {
      case 'rizz':
        return scenarioRizz;
      case 'family':
        return scenarioFamily;
      case 'business':
        return scenarioBusiness;
      case 'conflict':
        return scenarioConflict;
      case 'negotiation':
        return scenarioNegotiation;
      default:
        return primaryBrand;
    }
  }

  // Aliases for compatibility
  static const Color energyAccent = primaryNavy;
  static const Color primaryCTA = primaryNavy;
  static const Color secondaryAccent = primaryBrand;
  static const Color focusHighlight = primaryBrand;
  static const Color growthGreen = success;
  static const Color confidenceIconBg = Color(0xFF4DD0E1);
  static const Color heroCardTextSecondary = Color(0xFFCBD5E1);
}

class AppTextStyles {
  // Headings: Poppins - Rounded, bold, generous spacing
  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Body: Inter - Readable, neutral
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // Buttons: Manrope or Poppins
  static TextStyle get buttonTextLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static TextStyle get buttonTextMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get buttonText => buttonTextMedium;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBrand,
        primary: AppColors.primaryNavy,
        secondary: AppColors.primaryBrand,
        surface: AppColors.surface,
        error: AppColors.warning,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryNavy,
        brightness: Brightness.light,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h1.copyWith(fontSize: 28),
        displaySmall: AppTextStyles.h2,
        headlineLarge: AppTextStyles.h2,
        headlineMedium: AppTextStyles.h3,
        headlineSmall: AppTextStyles.h3.copyWith(fontSize: 18),
        titleLarge: AppTextStyles.h3,
        titleMedium: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleSmall: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonTextLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.primaryNavy, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonTextLarge,
        ),
      ),
      // Custom theme for Secondary Button (Orange)
      // We can use a custom extension or just define it in button themes
      // But for now, let's use filledButtonTheme for the secondary brand color if needed
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBrand,
          foregroundColor: AppColors.primaryNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonTextLarge.copyWith(
            color: AppColors.primaryNavy,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0, // Minimal shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBrand, width: 2),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PremiumPageTransitionBuilder(),
          TargetPlatform.iOS: PremiumPageTransitionBuilder(),
          TargetPlatform.windows: PremiumPageTransitionBuilder(),
          TargetPlatform.macOS: PremiumPageTransitionBuilder(),
        },
      ),
    );
  }
}
