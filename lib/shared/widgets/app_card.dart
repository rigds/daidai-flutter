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

    if (settings.glassMode) {
      final card = GlassCard(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
      if (margin != null) {
        return Padding(padding: margin!, child: card);
      }
      return card;
    }

    final card = Container(
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

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: GestureDetector(onTap: onTap, child: card),
      );
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
