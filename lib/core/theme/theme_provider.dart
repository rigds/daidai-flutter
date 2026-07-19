import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStyleSettings {
  final ThemeMode themeMode;
  final bool glassMode;
  final String? backgroundImagePath;
  final double blurIntensity;
  final double textScale; // 🌟 新增：全局字体缩放比例

  const AppStyleSettings({
    this.themeMode = ThemeMode.system,
    this.glassMode = true,
    this.backgroundImagePath,
    this.blurIntensity = 20.0,
    this.textScale = 1.0, // 🌟 新增：默认比例为 1.0
  });

  AppStyleSettings copyWith({
    ThemeMode? themeMode,
    bool? glassMode,
    String? backgroundImagePath,
    double? blurIntensity,
    double? textScale, // 🌟 新增
    bool clearBackground = false,
  }) {
    return AppStyleSettings(
      themeMode: themeMode ?? this.themeMode,
      glassMode: glassMode ?? this.glassMode,
      backgroundImagePath: clearBackground
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
      blurIntensity: blurIntensity ?? this.blurIntensity,
      textScale: textScale ?? this.textScale, // 🌟 新增
    );
  }
}

class AppStyleNotifier extends StateNotifier<AppStyleSettings> {
  AppStyleNotifier() : super(const AppStyleSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final glassMode = prefs.getBool('glass_mode') ?? true;
    final bgPath = prefs.getString('bg_image_path');
    final blur = prefs.getDouble('blur_intensity') ?? 20.0;
    final scale = prefs.getDouble('text_scale') ?? 1.0; // 🌟 新增：读取本地字体大小设置

    state = AppStyleSettings(
      themeMode: ThemeMode.values[themeIndex],
      glassMode: glassMode,
      backgroundImagePath: bgPath,
      blurIntensity: blur,
      textScale: scale, // 🌟 新增
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setGlassMode(bool enabled) async {
    state = state.copyWith(glassMode: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glass_mode', enabled);
  }

  Future<void> setBackgroundImage(String? path) async {
    state = state.copyWith(
      backgroundImagePath: path,
      clearBackground: path == null,
    );
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('bg_image_path');
    } else {
      await prefs.setString('bg_image_path', path);
    }
  }

  Future<void> setBlurIntensity(double value) async {
    state = state.copyWith(blurIntensity: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('blur_intensity', value);
  }

  // 🌟 新增：设置字体缩放比例并保存到本地
  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_scale', scale);
  }

  bool get isDarkMode => state.themeMode == ThemeMode.dark;
}

final appStyleProvider =
    StateNotifierProvider<AppStyleNotifier, AppStyleSettings>((ref) {
  return AppStyleNotifier();
});

// 兼容旧代码
final themeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appStyleProvider).themeMode;
});
