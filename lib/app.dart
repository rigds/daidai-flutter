import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 🌟 新增：导入本地化包
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/app_lock/widgets/app_lock_gate.dart';

class DaidaiApp extends ConsumerWidget {
  const DaidaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final styleSettings = ref.watch(appStyleProvider);

    return MaterialApp.router(
      title: '呆呆面板',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: styleSettings.themeMode,
      routerConfig: router,
      
      // 🌟 新增：配置本地化代理，这三行负责将系统控件（如复制/粘贴菜单）翻译成中文
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 🌟 新增：声明 App 支持的语言列表
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      
      locale: const Locale('zh', 'CN'),
      // 🌟 修改：在 builder 中注入 MediaQuery 实现全局字体缩放，同时保留原有的 AppLockGate
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(styleSettings.textScale),
          ),
          child: AppLockGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
