import 'package:flutter/material.dart';
import 'app.dart';
import 'core/network/app_user_agent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppUserAgent.initialize();
  await initializeAppServices();
  runApp(const DaidaiApp());
}
