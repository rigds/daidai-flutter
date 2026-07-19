import 'package:flutter/material.dart';

/// 设计系统色板 — 基于 Emerald + Slate
class AppColors {
  // Primary
  static const primary = Color(0xFF10B981); // Emerald-500
  static const primaryLight = Color(0xFFD1FAE5); // Emerald-100
  static const primaryDark = Color(0xFF059669); // Emerald-600

  // Slate 体系
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  // 液态玻璃色板
  static const glassBg = Color(0xFFF2F2F7);
  static const glassCard = Color(0xFFFFFFFF);
  static const glassCardBorder = Color(0xFFE5E5EA);
  static const glassDivider = Color(0xFFE5E5EA);
  static const miuixRed = Color(0xFFE5534B);
  static const miuixGreen = Color(0xFF30A14E);
  static const miuixBlue = Color(0xFF3B82F6);
  static const miuixPurple = Color(0xFF8B5CF6);
  static const miuixYellow = Color(0xFFD4A017);

  // 功能色
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const blue100 = Color(0xFFDBEAFE);
  static const purple500 = Color(0xFF8B5CF6);
  static const purple600 = Color(0xFF7C3AED);
  static const purple100 = Color(0xFFEDE9FE);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red100 = Color(0xFFFEE2E2);
  static const red50 = Color(0xFFFEF2F2);
  static const amber500 = Color(0xFFF59E0B);

  // 日志终端
  static const termBg = Colors.white;
  static const termBgDark = Color(0xFF000000);
  static const termText = Color(0xFF0F172A); // slate-900
  static const termBlue = Color(0xFF60A5FA); // blue-400
  static const termGreen = Color(0xFF34D399); // emerald-400
  static const termRed = Color(0xFFF87171); // red-400
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.blue500,
      surface: Colors.white,
      onSurface: AppColors.slate900,
      // 🌟 修改：全局副文本颜色加深，从 slate500 变更为 slate700
      onSurfaceVariant: AppColors.slate700,
      outline: AppColors.glassCardBorder,
      outlineVariant: AppColors.slate100,
      error: AppColors.red500,
      surfaceContainerHighest: AppColors.slate100,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.blue500,
      surface: AppColors.slate950,
      onSurface: AppColors.slate50,
      // 🌟 修改：暗色模式副文本提亮（加深对比度），从 slate400 变更为 slate300
      onSurfaceVariant: AppColors.slate300,
      outline: AppColors.slate800,
      outlineVariant: AppColors.slate800,
      error: AppColors.red500,
      surfaceContainerHighest: AppColors.slate900,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme cs) {
    final isLight = cs.brightness == Brightness.light;
    final cardColor = isLight ? AppColors.glassCard : AppColors.slate900;
    final borderColor = isLight ? AppColors.glassCardBorder : AppColors.slate800;
    final scaffoldBg = isLight ? AppColors.glassBg : AppColors.slate950;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg.withAlpha(200),
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          // 🌟 修改：输入框提示文字颜色加深
          color: isLight ? AppColors.slate400 : AppColors.slate500,
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600, // 🌟 修改：标签字体加粗
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: borderColor),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : isLight
              ? AppColors.slate300
              : AppColors.slate700;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.transparent
              : isLight
              ? AppColors.slate400
              : AppColors.slate600;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 60,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          // 🌟 修改：底栏未选中图标颜色加深
          return IconThemeData(
              color: isLight ? AppColors.slate700 : AppColors.slate300, 
              size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 11, // 🌟 修改：字体微微放大
              fontWeight: FontWeight.w700, // 🌟 修改：选中字体更粗
            );
          }
          return TextStyle(
            // 🌟 修改：底栏未选中字体颜色显著加深，字体加粗
            color: isLight ? AppColors.slate700 : AppColors.slate300, 
            fontSize: 11, // 🌟 修改：字体微微放大
            fontWeight: FontWeight.w600, // 🌟 修改：未选中也加粗保证清晰度
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 0.5,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      ),
      dialogBackgroundColor: cardColor,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.slate900 : AppColors.slate800,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 状态颜色
  static const Color successColor = AppColors.primary;
  static const Color errorColor = AppColors.red500;
  static const Color warningColor = AppColors.amber500;
  static const Color runningColor = AppColors.primary;
  static const Color disabledColor = AppColors.slate300;
}
