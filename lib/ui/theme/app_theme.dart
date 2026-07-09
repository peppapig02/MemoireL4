import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';

abstract final class AppTheme {
  static const _fontFamily = 'Sora';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
    );

    return _buildTheme(base, Brightness.light);
  }

  static ThemeData get dark {
    const bg = Color(0xFF111111);
    const surf = bg; // surface neumorphique = fond
    const surfEl = Color(0xFF1C1C1C); // overlays (bottom sheet, dropdown…)
    const textPri = Color(0xFFECECEB);
    const textSec = Color(0xFF9A9A9A);
    const div = Color(0xFF272727);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        surface: surf,
        onSurface: textPri,
        error: AppColors.error,
        onError: Colors.white,
      ),
    );

    final sora = base.textTheme.apply(fontFamily: _fontFamily);

    return base.copyWith(
      textTheme: sora.copyWith(
        displayLarge: sora.displayLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPri,
          letterSpacing: -0.5,
        ),
        headlineMedium: sora.headlineMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPri,
          letterSpacing: -0.3,
        ),
        titleMedium: sora.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPri,
        ),
        bodyLarge: sora.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPri,
        ),
        bodyMedium: sora.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSec,
        ),
        bodySmall: sora.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF5E5E5E),
        ),
        labelLarge: sora.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPri,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPri,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusCard,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.borderRadiusButton,
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPri,
          side: const BorderSide(color: div),
          minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.borderRadiusButton,
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        hintStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: Color(0xFF5E5E5E),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      dividerTheme: const DividerThemeData(color: div, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfEl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusBottomSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfEl,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: textPri,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusAiCard),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: const IconThemeData(color: textSec, size: 22),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: textSec,
        dividerColor: div,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : textSec,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.4)
              : div,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusButton,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surfEl),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: AppTokens.borderRadiusCard,
            ),
          ),
        ),
      ),
    );
  }

  static ThemeData _buildTheme(ThemeData base, Brightness brightness) {
    final sora = base.textTheme.apply(fontFamily: _fontFamily);

    return base.copyWith(
      textTheme: sora.copyWith(
        displayLarge: sora.displayLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: sora.headlineMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: sora.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: sora.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: sora.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: sora.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: sora.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusCard,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.borderRadiusButton,
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.divider),
          minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.borderRadiusButton,
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusInput,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.divider, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusBottomSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.surfaceElevated,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusAiCard),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: IconThemeData(color: AppColors.textSecondary, size: 22),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: AppColors.divider,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusButton,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceElevated),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: AppTokens.borderRadiusCard,
            ),
          ),
        ),
      ),
    );
  }
}
