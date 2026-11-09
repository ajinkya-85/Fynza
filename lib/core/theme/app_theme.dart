import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme configuration for Fynza.
/// Features a warm vanilla cream backdrop, soft pastel cards, honey amber primary,
/// and Poppins geometric typography matching the Modern Cute Finance design direction.
class AppTheme {
  AppTheme._();

  // Warm Vanilla Cream Palette
  static const Color primaryAmber = Color(0xFFF6A63C); // Warm Apricot / Honey Amber
  static const Color scaffoldCream = Color(0xFFFDF8F3); // Warm cozy cream scaffold
  static const Color cardWhite = Color(0xFFFFFFFF); // Cloud white cards
  static const Color textCharcoal = Color(0xFF23201D); // Deep warm charcoal text
  static const Color textTaupe = Color(0xFF857E77); // Warm taupe for subtitles
  static const Color borderCream = Color(0xFFF0E7DC); // Soft hairline divider

  // Pastel Feature Accents (Expenses blush & Income mint)
  static const Color expenseCardBg = Color(0xFFFDECE9); // Soft rose blush
  static const Color expenseAccent = Color(0xFFD94136); // Warm coral red
  static const Color incomeCardBg = Color(0xFFE6F5EC); // Matcha mint
  static const Color incomeAccent = Color(0xFF238244); // Forest jade green

  // Pastel Rainbow Chart Palette
  static const List<Color> pastelChartColors = [
    Color(0xFFF49E8C), // Pastel Peach (Food)
    Color(0xFF7DBCE6), // Soft Sky Blue (Transport)
    Color(0xFFC2A5E7), // Pastel Lilac (Shopping)
    Color(0xFFF7CE72), // Warm Sunlight (Entertainment)
    Color(0xFF7FDCB8), // Soft Seafoam (Others)
  ];

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryAmber,
      primary: primaryAmber,
      brightness: Brightness.light,
      surface: scaffoldCream,
    ).copyWith(
      surface: scaffoldCream,
      surfaceContainerLowest: cardWhite,
      surfaceContainerLow: const Color(0xFFFAF4ED),
      surfaceContainer: const Color(0xFFF5EEE5),
      surfaceContainerHigh: const Color(0xFFEFE6DC),
      surfaceContainerHighest: const Color(0xFFE8DED2),
      onSurface: textCharcoal,
      onSurfaceVariant: textTaupe,
      outline: borderCream,
      outlineVariant: const Color(0xFFE5DDD2),
      error: expenseAccent,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldCream,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scaffoldCream,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: borderCream.withValues(alpha: 0.8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryAmber,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 1,
        backgroundColor: scaffoldCream,
        indicatorColor: primaryAmber.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderCream),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderCream),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryAmber, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      textTheme: _buildOpticalTextTheme(ThemeData.light().textTheme, colorScheme),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryAmber,
      primary: primaryAmber,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF191715),
      surfaceContainerLowest: const Color(0xFF1F1D1A),
      surfaceContainerLow: const Color(0xFF25221F),
      surfaceContainer: const Color(0xFF2C2825),
      surfaceContainerHigh: const Color(0xFF332F2B),
      surfaceContainerHighest: const Color(0xFF3B3632),
      onSurface: const Color(0xFFEDE8E3),
      onSurfaceVariant: const Color(0xFFA8A199),
      outline: const Color(0xFF38332E),
      outlineVariant: const Color(0xFF2D2925),
      error: const Color(0xFFFF8A80),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryAmber,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 1,
        backgroundColor: colorScheme.surface,
        indicatorColor: primaryAmber.withValues(alpha: 0.25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryAmber, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      textTheme: _buildOpticalTextTheme(ThemeData.dark().textTheme, colorScheme),
    );
  }

  /// Builds the text theme with Poppins font family and optical typography tracking.
  static TextTheme _buildOpticalTextTheme(
    TextTheme base,
    ColorScheme colorScheme,
  ) {
    final poppins = GoogleFonts.poppinsTextTheme(base);

    return poppins.copyWith(
      displayLarge: poppins.displayLarge?.copyWith(
        letterSpacing: -1.0,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      displayMedium: poppins.displayMedium?.copyWith(
        letterSpacing: -0.8,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      displaySmall: poppins.displaySmall?.copyWith(
        letterSpacing: -0.6,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineLarge: poppins.headlineLarge?.copyWith(
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: poppins.headlineMedium?.copyWith(
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: poppins.headlineSmall?.copyWith(
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: poppins.titleLarge?.copyWith(
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: poppins.titleMedium?.copyWith(
        letterSpacing: -0.1,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: poppins.titleSmall?.copyWith(
        letterSpacing: 0.0,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: poppins.bodyLarge?.copyWith(
        letterSpacing: 0.0,
        height: 1.45,
      ),
      bodyMedium: poppins.bodyMedium?.copyWith(
        letterSpacing: 0.0,
        height: 1.4,
      ),
      labelLarge: poppins.labelLarge?.copyWith(
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: poppins.labelMedium?.copyWith(
        letterSpacing: 0.2,
      ),
      labelSmall: poppins.labelSmall?.copyWith(
        letterSpacing: 0.3,
      ),
    );
  }
}
