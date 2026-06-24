import 'package:flutter/material.dart';
import '../../../screens/settings_screen.dart';

class ServerConfigPage extends StatelessWidget {
  const ServerConfigPage({super.key, this.manageMode = false});

  final bool manageMode;

  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
