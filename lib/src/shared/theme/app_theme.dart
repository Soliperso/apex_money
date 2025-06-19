import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryVariant = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);
  
  // Success/Error colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
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

  // Light Theme
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      primaryContainer: const Color(0xFFE3F2FD),
      secondary: secondaryColor,
      secondaryContainer: const Color(0xFFE0F2F1),
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFF8F9FA),
      surfaceContainerHigh: const Color(0xFFF1F3F4),
      surfaceContainer: const Color(0xFFF8F9FA),
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onSurface: Colors.black87,
      onSurfaceVariant: const Color(0xFF49454F),
      outline: const Color(0xFF79747E),
      outlineVariant: const Color(0xFFCAC4D0),
      shadow: Colors.black.withValues(alpha: 0.1),
      scrim: Colors.black54,
      inverseSurface: const Color(0xFF313033),
      onInverseSurface: const Color(0xFFF4EFF4),
      inversePrimary: const Color(0xFFB0C4FF),
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
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
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
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  // Dark Theme
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF64B5F6),
      primaryContainer: const Color(0xFF0D47A1),
      secondary: const Color(0xFF4DD0E1),
      secondaryContainer: const Color(0xFF006064),
      surface: const Color(0xFF121212),
      surfaceContainerHighest: const Color(0xFF2D2D2D),
      surfaceContainerHigh: const Color(0xFF242424),
      surfaceContainer: const Color(0xFF1E1E1E),
      onPrimary: Colors.black87,
      onSecondary: Colors.black87,
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFCAC4CF),
      outline: const Color(0xFF938F94),
      outlineVariant: const Color(0xFF49454E),
      shadow: Colors.black.withValues(alpha: 0.3),
      scrim: Colors.black87,
      inverseSurface: const Color(0xFFE6E1E5),
      onInverseSurface: const Color(0xFF313033),
      inversePrimary: primaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      
      // Typography (same as light theme but with dark colors)
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
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
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
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
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

// Extension to add custom semantic colors
extension AppColors on ColorScheme {
  Color get success => const Color(0xFF4CAF50);
  Color get warning => const Color(0xFFFF9800);
  Color get info => AppTheme.infoColor;
  
  Color get successContainer => brightness == Brightness.light 
    ? const Color(0xFFE8F5E8) 
    : const Color(0xFF1B5E20);
    
  Color get warningContainer => brightness == Brightness.light 
    ? const Color(0xFFFFF3E0) 
    : const Color(0xFFE65100);
    
  Color get infoContainer => brightness == Brightness.light 
    ? const Color(0xFFE3F2FD) 
    : const Color(0xFF0D47A1);
    
  Color get onSuccess => brightness == Brightness.light 
    ? Colors.white 
    : Colors.black87;
    
  Color get onWarning => brightness == Brightness.light 
    ? Colors.white 
    : Colors.black87;
    
  Color get onInfo => brightness == Brightness.light 
    ? Colors.white 
    : Colors.black87;
}