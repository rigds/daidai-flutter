import 'package:flutter/material.dart';

class AnsiText extends StatelessWidget {
  const AnsiText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(_stripAnsi(text), style: style);
  }

  static String _stripAnsi(String value) {
    return value.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
  }
}
