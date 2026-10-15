import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkStudioTheme {
    final colorScheme = ColorScheme.dark(
      primary: const Color(0xFF2EE672), // Emerald Mint
      onPrimary: const Color(0xFF0B110E),
      secondary: const Color(0xFF4ADE80),
      onSecondary: const Color(0xFF0B110E),
      tertiary: const Color(0xFF2EE672),
      onTertiary: const Color(0xFF0B110E),
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.surfaceBorder,
      error: AppColors.crimsonAlert,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.surfaceBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.amberEq,
        inactiveTrackColor: AppColors.surfaceContainerHighest,
        thumbColor: AppColors.amberEq,
        overlayColor: AppColors.amberEq.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
      ),
    );
  }
}
