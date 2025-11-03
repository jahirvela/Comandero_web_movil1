import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Constantes de tema global basadas en las imágenes PNG de referencia
/// Asegura consistencia en colores, tipografías, espaciados y radios en toda la app
class AppTheme {
  // ============================================================================
  // ESPACIADOS (spacing) - Valores estándar basados en React
  // ============================================================================
  static const double spacingXS = 4.0; // 0.25rem
  static const double spacingSM = 8.0; // 0.5rem
  static const double spacingMD = 12.0; // 0.75rem
  static const double spacingLG = 16.0; // 1rem
  static const double spacingXL = 24.0; // 1.5rem
  static const double spacing2XL = 32.0; // 2rem
  static const double spacing3XL = 40.0; // 2.5rem
  static const double spacing4XL = 48.0; // 3rem

  // ============================================================================
  // RADIOS DE BORDE (border radius) - Basados en React: --radius: 0.5rem (8px)
  // ============================================================================
  static const double radiusXS = 4.0; // Para chips pequeños
  static const double radiusSM = 6.0; // Para badges
  static const double radiusMD = 8.0; // Estándar (--radius)
  static const double radiusLG = 12.0; // Para cards
  static const double radiusXL = 16.0; // Para modales grandes
  static const double radiusFull = 999.0; // Círculo completo

  // ============================================================================
  // ELEVACIONES (shadows) - Consistencia visual
  // ============================================================================
  static const double elevationNone = 0.0;
  static const double elevationSM = 1.0; // Sombras sutiles
  static const double elevationMD = 2.0; // Estándar (cards, buttons)
  static const double elevationLG = 4.0; // Modales, dialogs
  static const double elevationXL = 8.0; // Overlays grandes

  // ============================================================================
  // TIPOGRAFÍAS - Tamaños basados en React
  // ============================================================================
  static const double fontSizeXS = 12.0; // text-xs: 0.75rem
  static const double fontSizeSM = 14.0; // text-sm: 0.875rem
  static const double fontSizeBase = 16.0; // text-base: 1rem (--font-size)
  static const double fontSizeLG = 18.0; // text-lg: 1.125rem
  static const double fontSizeXL = 20.0; // text-xl: 1.25rem
  static const double fontSize2XL = 24.0; // text-2xl: 1.5rem
  static const double fontSize3XL = 30.0; // text-3xl: 1.875rem
  static const double fontSize4XL = 36.0; // text-4xl: 2.25rem

  // Font weights
  static const FontWeight fontWeightNormal = FontWeight.w400; // 400
  static const FontWeight fontWeightMedium = FontWeight.w500; // 500
  static const FontWeight fontWeightSemibold = FontWeight.w600; // 600
  static const FontWeight fontWeightBold = FontWeight.w700; // 700

  // Letter spacing
  static const double letterSpacingTight = -0.025;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.1;

  // ============================================================================
  // BREAKPOINTS RESPONSIVE
  // ============================================================================
  static const double breakpointMobile = 600.0; // Tablet
  static const double breakpointTablet = 900.0; // Desktop pequeño
  static const double breakpointDesktop = 1200.0; // Desktop grande

  // ============================================================================
  // DURACIONES DE ANIMACIÓN
  // ============================================================================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // CURVAS DE ANIMACIÓN
  // ============================================================================
  static const Curve curveDefault = Curves.easeInOut; // cubic-bezier(.4, 0, .2, 1)
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveBounce = Curves.bounceOut;

  // ============================================================================
  // TEMA PRINCIPAL - MaterialApp theme
  // ============================================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false, // Mantener Material 2 por compatibilidad
      
      // Colores base
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // ColorScheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      
      // Tipografía
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        displayLarge: TextStyle(
          fontSize: fontSize4XL,
          fontWeight: fontWeightBold,
          color: AppColors.textPrimary,
          letterSpacing: letterSpacingTight,
        ),
        displayMedium: TextStyle(
          fontSize: fontSize3XL,
          fontWeight: fontWeightBold,
          color: AppColors.textPrimary,
          letterSpacing: letterSpacingTight,
        ),
        displaySmall: TextStyle(
          fontSize: fontSize2XL,
          fontWeight: fontWeightBold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemibold,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLG,
          fontWeight: fontWeightSemibold,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeBase,
          fontWeight: fontWeightSemibold,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBase,
          fontWeight: fontWeightNormal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeSM,
          fontWeight: fontWeightNormal,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeXS,
          fontWeight: fontWeightNormal,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeSM,
          fontWeight: fontWeightMedium,
          color: AppColors.textPrimary,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: elevationMD,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLG,
          fontWeight: fontWeightSemibold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24.0,
        ),
      ),
      
      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: elevationMD,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingLG,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: TextStyle(
            fontSize: fontSizeBase,
            fontWeight: fontWeightSemibold,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXL,
            vertical: spacingLG,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: TextStyle(
            fontSize: fontSizeBase,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLG,
            vertical: spacingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
          textStyle: TextStyle(
            fontSize: fontSizeBase,
            fontWeight: fontWeightMedium,
          ),
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: elevationMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        color: AppColors.surface,
        margin: const EdgeInsets.symmetric(
          horizontal: spacingLG,
          vertical: spacingSM,
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLG,
          vertical: spacingLG,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: AppColors.border,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: AppColors.borderFocus,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: fontSizeBase,
          color: AppColors.textSecondary,
          fontWeight: fontWeightNormal,
        ),
        hintStyle: TextStyle(
          fontSize: fontSizeBase,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          fontWeight: fontWeightNormal,
        ),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.inputBackground,
        labelStyle: TextStyle(
          fontSize: fontSizeSM,
          color: AppColors.textPrimary,
          fontWeight: fontWeightMedium,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1.0,
        space: 1.0,
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: elevationMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(
          fontSize: fontSizeSM,
          color: Colors.white,
          fontWeight: fontWeightNormal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: elevationLG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        titleTextStyle: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: fontWeightSemibold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: fontSizeBase,
          fontWeight: fontWeightNormal,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

