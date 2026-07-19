import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStyleProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 主题模式
          _buildSectionTitle('主题模式', isLight),
          const SizedBox(height: 8),
          _ThemeModeSelector(
            isLight: isLight,
            currentMode: settings.themeMode,
            onChanged: (mode) =>
                ref.read(appStyleProvider.notifier).setThemeMode(mode),
          ),
          const SizedBox(height: 24),

          // 界面风格
          _buildSectionTitle('界面风格', isLight),
          const SizedBox(height: 8),
          _GlassModeCard(
            isLight: isLight,
            enabled: settings.glassMode,
            onChanged: (v) =>
                ref.read(appStyleProvider.notifier).setGlassMode(v),
          ),
          const SizedBox(height: 24),

          // 背景图片
          _buildSectionTitle('背景图片', isLight),
          const SizedBox(height: 8),
          _BackgroundImageCard(
            isLight: isLight,
            currentPath: settings.backgroundImagePath,
            onPick: () => _pickBackgroundImage(ref),
            onClear: () =>
                ref.read(appStyleProvider.notifier).setBackgroundImage(null),
          ),

          // 背景模糊
          if (settings.backgroundImagePath != null) ...[
            const SizedBox(height: 12),
            _BlurSliderCard(
              isLight: isLight,
              value: settings.blurIntensity,
              onChanged: (v) =>
                  ref.read(appStyleProvider.notifier).setBlurIntensity(v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isLight ? AppColors.slate500 : AppColors.slate400,
        ),
      ),
    );
  }

  Future<void> _pickBackgroundImage(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        await ref
            .read(appStyleProvider.notifier)
            .setBackgroundImage(result.files.single.path!);
      }
    } catch (_) {}
  }
}

class _ThemeModeSelector extends ConsumerWidget {
  final bool isLight;
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.isLight,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(appStyleProvider).glassMode;

    final rowContent = Row(
      children: ThemeMode.values.map((mode) {
        final isSelected = mode == currentMode;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isLight
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.primary.withAlpha(30))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _modeIcon(mode),
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : (isLight
                              ? AppColors.slate400
                              : AppColors.slate500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modeLabel(mode),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : (isLight
                                ? AppColors.slate500
                                : AppColors.slate400),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ;
        }).toList(),
      ),
    ;

    if (glassMode) {
      return GlassCard(
        padding: EdgeInsets.zero,
        child: rowContent,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.glassCard : AppColors.slate900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.glassCardBorder : AppColors.slate800,
          width: 0.5,
        ),
      ),
      child: rowContent,
    );
  }

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  IconData _modeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}

class _GlassModeCard extends ConsumerWidget {
  final bool isLight;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _GlassModeCard({
    required this.isLight,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(appStyleProvider).glassMode;

    final content = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary.withAlpha(20)
                : (isLight ? AppColors.slate100 : AppColors.slate800),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.blur_on,
            size: 22,
            color: enabled
                ? AppColors.primary
                : (isLight ? AppColors.slate400 : AppColors.slate500),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '液态玻璃风格',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'iOS 26 液态玻璃效果',
                style: TextStyle(
                  fontSize: 12,
                  color: isLight ? AppColors.slate400 : AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
        Switch(value: enabled, onChanged: onChanged),
      ],
    );

    if (glassMode) {
      return GlassCard(padding: const EdgeInsets.all(16), child: content);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.glassCard : AppColors.slate900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.glassCardBorder : AppColors.slate800,
          width: 0.5,
        ),
      ),
      child: content,
    );
  }
}

class _BackgroundImageCard extends ConsumerWidget {
  final bool isLight;
  final String? currentPath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _BackgroundImageCard({
    required this.isLight,
    required this.currentPath,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(appStyleProvider).glassMode;

    final content = currentPath != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(currentPath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.slate100 : AppColors.slate800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: isLight
                              ? AppColors.slate400
                              : AppColors.slate500),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('更换图片'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.red500),
                    label: const Text('移除',
                        style: TextStyle(color: AppColors.red500)),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLight ? AppColors.slate100 : AppColors.slate800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.wallpaper_outlined,
                    size: 22,
                    color: isLight ? AppColors.slate400 : AppColors.slate500),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('选择背景图片',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('从相册选择图片作为背景',
                        style: TextStyle(
                            fontSize: 12,
                            color: isLight
                                ? AppColors.slate400
                                : AppColors.slate500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20,
                  color: isLight ? AppColors.slate400 : AppColors.slate600),
            ],
          );

    return GestureDetector(
      onTap: currentPath != null ? null : onPick,
      child: glassMode
          ? GlassCard(padding: const EdgeInsets.all(16), child: content)
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? AppColors.glassCard : AppColors.slate900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isLight ? AppColors.glassCardBorder : AppColors.slate800,
                  width: 0.5,
                ),
              ),
              child: content,
            ),
    );
  }
}

class _BlurSliderCard extends ConsumerWidget {
  final bool isLight;
  final double value;
  final ValueChanged<double> onChanged;

  const _BlurSliderCard({
    required this.isLight,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassMode = ref.watch(appStyleProvider).glassMode;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.blur_on,
                size: 18,
                color: isLight ? AppColors.slate500 : AppColors.slate400),
            const SizedBox(width: 8),
            const Text('背景模糊程度',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor:
                isLight ? AppColors.slate200 : AppColors.slate700,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withAlpha(30),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 50,
            divisions: 50,
            onChanged: onChanged,
          ),
        ),
      ],
    );

    if (glassMode) {
      return GlassCard(padding: const EdgeInsets.all(16), child: content);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? AppColors.glassCard : AppColors.slate900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.glassCardBorder : AppColors.slate800,
          width: 0.5,
        ),
      ),
      child: content,
    );
  }
}
