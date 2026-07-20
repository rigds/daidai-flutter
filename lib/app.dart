import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      
      // 本地化代理，负责将系统控件（如复制/粘贴菜单）翻译成中文
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // 🌟 核心修改：加入更全面的中文匹配规则，防止部分手机系统识别不到
      supportedLocales: const [
        Locale('zh', 'CN'), // 简体中文
        Locale('zh', 'HK'), // 繁体中文（香港）
        Locale('zh', 'TW'), // 繁体中文（台湾）
        Locale('zh'),       // 泛中文兜底（非常关键）
        Locale('en', 'US'), // 英文兜底
      ],
      
      // 强制 App 默认使用中文
      locale: const Locale('zh', 'CN'),
      
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
