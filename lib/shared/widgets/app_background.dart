import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

/// 全局背景组件，为所有页面提供统一的背景图片和模糊效果
class AppBackground extends ConsumerWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStyleProvider);
    final hasBg = settings.backgroundImagePath != null &&
        settings.backgroundImagePath!.isNotEmpty;

    if (!hasBg) return child;

    return Stack(
      children: [
        // 背景图层
        Positioned.fill(
          child: Image.file(
            File(settings.backgroundImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        // 模糊层
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: settings.blurIntensity,
              sigmaY: settings.blurIntensity,
            ),
            child: Container(color: Colors.black.withAlpha(15)),
          ),
        ),
        // 内容层
        Positioned.fill(child: child),
      ],
    );
  }
}
