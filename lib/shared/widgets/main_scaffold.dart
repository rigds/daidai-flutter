import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return child ?? const HomeScreen();
  }
}
