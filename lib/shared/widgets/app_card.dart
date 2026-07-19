import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class AppCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStyleProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    Widget card;

    if (settings.glassMode) {
      card = GlassCard(
        useOwnLayer: true,
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
    } else {
      card = Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? AppColors.glassCard : AppColors.slate900,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isLight ? AppColors.glassCardBorder : AppColors.slate800,
            width: 0.5,
          ),
        ),
        child: child,
      );
    }

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    if (margin != null) {
      return Padding(padding: margin!, child: card);
    }
    return card;
  }
}

class AppListTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const AppListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStyleProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (settings.glassMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(icon, size: 20),
            title: Text(title),
            trailing: trailing ??
                Icon(Icons.chevron_right,
                    size: 18,
                    color: isLight ? AppColors.slate400 : AppColors.slate600),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isLight ? AppColors.glassCard : AppColors.slate900,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLight ? AppColors.glassCardBorder : AppColors.slate800,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isLight ? AppColors.slate500 : AppColors.slate400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            Icon(Icons.chevron_right,
                size: 18,
                color: isLight ? AppColors.slate400 : AppColors.slate600),
          ],
        ),
      ),
    );
  }
}

/// 液态玻璃感知的容器装饰
/// glassMode=true 时返回透明装饰（配合 GlassCard 使用）
/// glassMode=false 时返回实体装饰
BoxDecoration glassAwareDecoration({
  required bool glassMode,
  required bool isLight,
  Color? lightColor,
  Color? darkColor,
  double borderRadius = 16,
  Color? borderColor,
  double borderWidth = 0.5,
}) {
  if (glassMode) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
  return BoxDecoration(
    color: (lightColor ?? AppColors.glassCard),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ??
          (isLight ? AppColors.glassCardBorder : AppColors.slate800),
      width: borderWidth,
    ),
  );
}

/// 液态玻璃感知的容器组件
/// glassMode=true 时使用 GlassCard
/// glassMode=false 时使用普通 Container
class GlassAwareContainer extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? lightColor;
  final Color? darkColor;

  const GlassAwareContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.lightColor,
    this.darkColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStyleProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (settings.glassMode) {
      return GlassCard(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight
            ? (lightColor ?? AppColors.glassCard)
            : (darkColor ?? AppColors.slate900),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isLight ? AppColors.glassCardBorder : AppColors.slate800,
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

/// 获取玻璃感知的卡片背景色
/// glassMode=true 时返回半透明色，glassMode=false 时返回实体色
Color glassCardColor({
  required bool glassMode,
  required bool isLight,
  Color? lightColor,
  Color? darkColor,
}) {
  if (glassMode) {
    return isLight
        ? (lightColor ?? Colors.white.withAlpha(160))
        : (darkColor ?? AppColors.slate800.withAlpha(140));
  }
  return isLight
      ? (lightColor ?? AppColors.glassCard)
      : (darkColor ?? AppColors.slate900);
}

/// 获取玻璃感知的输入框填充色
Color glassFillColor({
  required bool glassMode,
  required bool isLight,
}) {
  if (glassMode) {
    return isLight
        ? Colors.white.withAlpha(120)
        : AppColors.slate800.withAlpha(100);
  }
  return isLight ? Colors.white : AppColors.slate900;
}
