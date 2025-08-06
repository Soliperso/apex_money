import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Export design system utilities
export 'design_system.dart';
export '../widgets/financial_amount_widget.dart';

class AppTheme {
  // Enhanced financial color palette
  static const Color primaryColor = Color(0xFF1976D2); // Trust-building blue
  static const Color primaryVariant = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF0097A7); // Financial teal
  static const Color secondaryVariant = Color(0xFF006064);

  // Financial semantic colors with better contrast
  static const Color successColor = Color(
    0xFF2E7D32,
  ); // Income/positive (darker green for better contrast)
  static const Color warningColor = Color(0xFFED6C02); // Alert/caution (amber)
  static const Color errorColor = Color(
    0xFFD32F2F,
  ); // Expense/negative (darker red)
  static const Color infoColor = Color(0xFF0288D1); // Information (blue)

  // Additional financial colors
  static const Color neutralColor = Color(0xFF6B7280); // Neutral transactions
  static const Color savingsColor = Color(0xFF7C3AED); // Savings/goals (purple)
  static const Color investmentColor = Color(
    0xFF059669,
  ); // Investment (emerald)

  // Premium gradients for financial trust
  static const List<Color> premiumGradient = [
    Color(0xFF1976D2),
    Color(0xFF1565C0),
    Color(0xFF0D47A1),
  ];

  static const List<Color> incomeGradient = [
    Color(0xFF2E7D32),
    Color(0xFF388E3C),
    Color(0xFF4CAF50),
  ];

  static const List<Color> expenseGradient = [
    Color(0xFFD32F2F),
    Color(0xFFE53935),
    Color(0xFFEF5350),
  ];

  // Gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF1976D2),
    Color(0xFF2196F3),
    Color(0xFF64B5F6),
  ];

  static const List<Color> surfaceGradient = [
    Color(0xFFF8F9FA),
    Color(0xFFFFFFFF),
  ];

  static const List<Color> darkSurfaceGradient = [
    Color(0xFF1E1E1E),
    Color(0xFF2D2D2D),
  ];

  // Light Theme - Optimized for financial trust and accessibility
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      // Enhanced primary colors for financial trust
      primary: primaryColor,
      primaryContainer: const Color(0xFFE1F5FE), // Light blue container
      onPrimaryContainer: const Color(0xFF01579B),

      // Financial-friendly secondary colors
      secondary: secondaryColor,
      secondaryContainer: const Color(0xFFB2EBF2), // Light teal
      onSecondaryContainer: const Color(0xFF004D5B),

      // Enhanced surface colors for premium feel
      surface: const Color(0xFFFFFBFE), // Warm white for financial comfort
      surfaceContainerHighest: const Color(0xFFF7F2FA),
      surfaceContainerHigh: const Color(0xFFF3EDF7),
      surfaceContainer: const Color(0xFFF0EBF4),
      surfaceContainerLow: const Color(0xFFFBF8FD),
      surfaceContainerLowest: Colors.white,

      // Improved text colors for financial data readability
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1D1B20), // High contrast for financial data
      onSurfaceVariant: const Color(0xFF49454F),

      // Enhanced outline colors for better visual hierarchy
      outline: const Color(0xFF79747E),
      outlineVariant: const Color(0xFFCAC4D0),

      // Financial semantic additions
      error: errorColor,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),

      // Shadow and scrim for depth perception
      shadow: Colors.black.withValues(alpha: 0.08),
      scrim: Colors.black.withValues(alpha: 0.6),

      // Inverse colors for dark elements
      inverseSurface: const Color(0xFF1D1B20),
      onInverseSurface: const Color(0xFFF4EFF4),
      inversePrimary: const Color(0xFFB3E5FC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,

      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: const CircleBorder(),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.all(16),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // Dark Theme - Premium financial dark mode
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      // Premium financial dark colors
      primary: const Color(0xFF90CAF9), // Lighter blue for dark backgrounds
      primaryContainer: const Color(0xFF0D47A1),
      onPrimary: const Color(0xFF1D1B20),
      onPrimaryContainer: const Color(0xFFE1F5FE),

      // Financial-friendly secondary dark colors
      secondary: const Color(0xFF4DD0E1),
      secondaryContainer: const Color(0xFF00363A),
      onSecondary: const Color(0xFF1D1B20),
      onSecondaryContainer: const Color(0xFFB2EBF2),

      // Enhanced dark surfaces for financial comfort
      surface: const Color(0xFF141218), // Warm dark for financial apps
      surfaceContainerHighest: const Color(0xFF2B2930),
      surfaceContainerHigh: const Color(0xFF24232A),
      surfaceContainer: const Color(0xFF1F1E25),
      surfaceContainerLow: const Color(0xFF1D1B20),
      surfaceContainerLowest: const Color(0xFF0F0D13),

      // High contrast text for financial data readability
      onSurface: const Color(0xFFE6E0E9),
      onSurfaceVariant: const Color(0xFFCAC4CF),

      // Enhanced outlines for dark mode hierarchy
      outline: const Color(0xFF948F99),
      outlineVariant: const Color(0xFF49454E),

      // Financial semantic dark colors
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),

      // Enhanced shadow and scrim for depth
      shadow: Colors.black.withValues(alpha: 0.4),
      scrim: Colors.black.withValues(alpha: 0.8),

      // Inverse colors for light elements
      inverseSurface: const Color(0xFFE6E0E9),
      onInverseSurface: const Color(0xFF1D1B20),
      inversePrimary: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,

      // Typography (same as light theme but with dark colors)
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        color: colorScheme.surfaceContainer,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: const CircleBorder(),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.all(16),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// Enhanced financial semantic colors extension
extension AppColors on ColorScheme {
  // Financial semantic colors with improved accessibility
  Color get incomeColor =>
      brightness == Brightness.light
          ? AppTheme.successColor
          : const Color(0xFF81C784);

  Color get expenseColor =>
      brightness == Brightness.light
          ? AppTheme.errorColor
          : const Color(0xFFEF5350);

  Color get neutralColor =>
      brightness == Brightness.light
          ? AppTheme.neutralColor
          : const Color(0xFF9E9E9E);

  Color get savingsColor =>
      brightness == Brightness.light
          ? AppTheme.savingsColor
          : const Color(0xFFB39DDB);

  Color get investmentColor =>
      brightness == Brightness.light
          ? AppTheme.investmentColor
          : const Color(0xFF4DB6AC);

  // Legacy support
  Color get success => incomeColor;
  Color get warning => AppTheme.warningColor;
  Color get info => AppTheme.infoColor;

  // Enhanced container colors for financial states
  Color get incomeContainer =>
      brightness == Brightness.light
          ? const Color(0xFFE8F5E8)
          : const Color(0xFF1B5E20);

  Color get expenseContainer =>
      brightness == Brightness.light
          ? const Color(0xFFFFEBEE)
          : const Color(0xFFB71C1C);

  Color get neutralContainer =>
      brightness == Brightness.light
          ? const Color(0xFFF5F5F5)
          : const Color(0xFF424242);

  Color get savingsContainer =>
      brightness == Brightness.light
          ? const Color(0xFFF3E5F5)
          : const Color(0xFF4A148C);

  Color get investmentContainer =>
      brightness == Brightness.light
          ? const Color(0xFFE0F2F1)
          : const Color(0xFF004D40);

  Color get warningContainer =>
      brightness == Brightness.light
          ? const Color(0xFFFFF3E0)
          : const Color(0xFFE65100);

  Color get infoContainer =>
      brightness == Brightness.light
          ? const Color(0xFFE3F2FD)
          : const Color(0xFF0D47A1);

  // On-color variants for proper contrast
  Color get onIncome =>
      brightness == Brightness.light ? Colors.white : Colors.black87;
  Color get onExpense =>
      brightness == Brightness.light ? Colors.white : Colors.black87;
  Color get onNeutral =>
      brightness == Brightness.light ? Colors.white : Colors.black87;
  Color get onSavings =>
      brightness == Brightness.light ? Colors.white : Colors.black87;
  Color get onInvestment =>
      brightness == Brightness.light ? Colors.white : Colors.black87;

  // Legacy support
  Color get onSuccess => onIncome;
  Color get onWarning =>
      brightness == Brightness.light ? Colors.white : Colors.black87;
  Color get onInfo =>
      brightness == Brightness.light ? Colors.white : Colors.black87;
}
