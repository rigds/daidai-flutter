import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
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
    if (didPop) return;
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

  void _onTabSelected(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/logs');
        break;
      case 3:
        context.go('/envs');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  Widget _buildBackground(AppStyleSettings settings, bool isLight) {
    if (settings.backgroundImagePath != null &&
        settings.backgroundImagePath!.isNotEmpty) {
      return Image.file(
        File(settings.backgroundImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildDefaultBackground(isLight),
      );
    }
    return _buildDefaultBackground(isLight);
  }

  Widget _buildDefaultBackground(bool isLight) {
    return Container(
      color: isLight ? AppColors.glassBg : AppColors.slate950,
    );
  }

  Widget _buildGlassBottomBar(int idx) {
    return GlassTabBar.bottom(
      selectedIndex: idx,
      onTabSelected: _onTabSelected,
      iconSize: 22,
      labelFontSize: 10,
      barHeight: 58,
      horizontalPadding: 16,
      verticalPadding: 10,
      tabs: const [
        GlassTab(
          icon: Icon(Icons.space_dashboard_outlined),
          activeIcon: Icon(Icons.space_dashboard),
          label: '主页',
        ),
        GlassTab(
          icon: Icon(Icons.schedule_outlined),
          activeIcon: Icon(Icons.schedule),
          label: '任务',
        ),
        GlassTab(
          icon: Icon(Icons.terminal_outlined),
          activeIcon: Icon(Icons.terminal),
          label: '日志',
        ),
        GlassTab(
          icon: Icon(Icons.key_outlined),
          activeIcon: Icon(Icons.key),
          label: '变量',
        ),
        GlassTab(
          icon: Icon(Icons.menu_outlined),
          activeIcon: Icon(Icons.menu),
          label: '更多',
        ),
      ],
    );
  }

  Widget _buildClassicBottomBar(int idx, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 14, right: 14),
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
                    ? [Colors.white.withAlpha(200), Colors.white.withAlpha(140)]
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    _ClassicNavItem(
                      icon: Icons.space_dashboard_outlined,
                      activeIcon: Icons.space_dashboard,
                      label: '主页',
                      isActive: idx == 0,
                      onTap: () => _onTabSelected(0),
                      isLight: isLight,
                    ),
                    _ClassicNavItem(
                      icon: Icons.schedule_outlined,
                      activeIcon: Icons.schedule,
                      label: '任务',
                      isActive: idx == 1,
                      onTap: () => _onTabSelected(1),
                      isLight: isLight,
                    ),
                    _ClassicNavItem(
                      icon: Icons.terminal_outlined,
                      activeIcon: Icons.terminal,
                      label: '日志',
                      isActive: idx == 2,
                      onTap: () => _onTabSelected(2),
                      isLight: isLight,
                    ),
                    _ClassicNavItem(
                      icon: Icons.key_outlined,
                      activeIcon: Icons.key,
                      label: '变量',
                      isActive: idx == 3,
                      onTap: () => _onTabSelected(3),
                      isLight: isLight,
                    ),
                    _ClassicNavItem(
                      icon: Icons.menu_outlined,
                      activeIcon: Icons.menu,
                      label: '更多',
                      isActive: idx == 4,
                      onTap: () => _onTabSelected(4),
                      isLight: isLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final settings = ref.watch(appStyleProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hasBg = settings.backgroundImagePath != null &&
        settings.backgroundImagePath!.isNotEmpty;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handleBackPress(didPop),
      child: Stack(
        children: [
          // 背景层
          Positioned.fill(child: _buildBackground(settings, isLight)),

          // 模糊层（有背景图时）
          if (hasBg)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: settings.blurIntensity,
                  sigmaY: settings.blurIntensity,
                ),
                child: Container(color: Colors.black.withAlpha(20)),
              ),
            ),

          // 内容层
          if (settings.glassMode)
            GlassScaffold(
              body: widget.child,
              bottomBar: _buildGlassBottomBar(idx),
            )
          else
            Scaffold(
              backgroundColor: Colors.transparent,
              body: widget.child,
              extendBody: true,
              bottomNavigationBar: _buildClassicBottomBar(idx, isLight),
            ),
        ],
      ),
    );
  }
}

class _ClassicNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isLight;

  const _ClassicNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
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
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
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
