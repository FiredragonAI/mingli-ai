import 'package:flutter/material.dart';

/// 国风配色:朱砂、藏青、宣纸。
class AppColors {
  static const cinnabar = Color(0xFFB8402E);
  static const ink = Color(0xFF1F2A3A);
  static const paper = Color(0xFFF7F3EA);
  static const paperDark = Color(0xFF15181F);
  static const gold = Color(0xFFC9A55A);
  static const jade = Color(0xFF3E8E5A);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.cinnabar,
    brightness: brightness,
    surface: dark ? AppColors.paperDark : AppColors.paper,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'SourceHanSerif',
    fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei', 'Noto Sans CJK SC', 'sans-serif'],
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

/// 五行色。
const Map<String, Color> elementColor = {
  '木': Color(0xFF3E8E5A),
  '火': Color(0xFFD9534F),
  '土': Color(0xFFB8860B),
  '金': Color(0xFFC0A062),
  '水': Color(0xFF2F6FB3),
};
