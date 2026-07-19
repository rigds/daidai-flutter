import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  DateTime? _lastExitAttemptAt;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/tasks')) return 1;
    if (location.startsWith('/logs')) return 2;
    if (location.startsWith('/envs')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  Future<void> _handleBackPress(bool didPop) async {
    if (didPop) {
      return;
    }

    final now = DateTime.now();
    if (_lastExitAttemptAt == null ||
        now.difference(_lastExitAttemptAt!) > const Duration(seconds: 5)) {
      _lastExitAttemptAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('5秒内再按一次返回键退出应用'),
            duration: Duration(seconds: 5),
          ),
        );
      return;
    }

    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final idx = _currentIndex(context);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBackPress(didPop),
      child: Scaffold(
        body: widget.child,
        extendBody: true,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(
            bottom: 10,
            left: 14,
            right: 14,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isLight
                        ? [
                            Colors.white.withAlpha(200),
                            Colors.white.withAlpha(140),
                          ]
                        : [
                            AppColors.slate800.withAlpha(180),
                            AppColors.slate900.withAlpha(140),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isLight
                        ? Colors.white.withAlpha(200)
                        : Colors.white.withAlpha(25),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? AppColors.slate900.withAlpha(18)
                          : Colors.black.withAlpha(60),
                      blurRadius: 24,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _NavItem(
                          icon: Icons.space_dashboard_outlined,
                          activeIcon: Icons.space_dashboard,
                          label: '主页',
                          isActive: idx == 0,
                          onTap: () => context.go('/dashboard'),
                        ),
                        _NavItem(
                          icon: Icons.schedule_outlined,
                          activeIcon: Icons.schedule,
                          label: '任务',
                          isActive: idx == 1,
                          onTap: () => context.go('/tasks'),
                        ),
                        _NavItem(
                          icon: Icons.terminal_outlined,
                          activeIcon: Icons.terminal,
                          label: '日志',
                          isActive: idx == 2,
                          onTap: () => context.go('/logs'),
                        ),
                        _NavItem(
                          icon: Icons.key_outlined,
                          activeIcon: Icons.key,
                          label: '变量',
                          isActive: idx == 3,
                          onTap: () => context.go('/envs'),
                        ),
                        _NavItem(
                          icon: Icons.menu_outlined,
                          activeIcon: Icons.menu,
                          label: '更多',
                          isActive: idx == 4,
                          onTap: () => context.go('/more'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = isActive ? AppColors.primary : AppColors.slate400;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? (isLight
                      ? AppColors.primary.withAlpha(18)
                      : AppColors.primary.withAlpha(25))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isActive ? activeIcon : icon, size: 20, color: color),
                const SizedBox(height: 1),
                SizedBox(
                  height: 11,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
