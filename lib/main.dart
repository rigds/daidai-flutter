import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'app.dart';
import 'core/auth/auth_interceptor.dart';
import 'core/auth/auth_provider.dart';
import 'core/network/app_user_agent.dart';
import 'core/network/dio_client.dart';
import 'core/services/local_notification_service.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppUserAgent.initialize();

  await LiquidGlassWidgets.initialize();

  try {
    await LocalNotificationService().initialize();
  } catch (_) {}

  // 恢复服务器地址
  final serverUrl = await SecureStorage.getServerUrl();
  if (serverUrl != null && serverUrl.isNotEmpty) {
    DioClient.instance.setBaseUrl(serverUrl);
  }

  final container = ProviderContainer();

  // 注入认证拦截器
  DioClient.instance.dio.interceptors.insert(
    0,
    AuthInterceptor(
      onAuthFailed: () {
        container.read(authProvider.notifier).setUnauthenticated();
      },
    ),
  );

  // 启动时先恢复本地可信登录态，7 天内避免重复触发登录接口和登录日志。
  await container.read(authProvider.notifier).restoreTrustedLocalSession();

  runApp(
    LiquidGlassWidgets.wrap(
      child: UncontrolledProviderScope(
        container: container,
        child: const DaidaiApp(),
      ),
    ),
  );
}
