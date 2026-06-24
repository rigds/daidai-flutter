import 'package:flutter/material.dart';

Color logBackgroundColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF0B0F14)
      : const Color(0xFFF8FAFC);
}
