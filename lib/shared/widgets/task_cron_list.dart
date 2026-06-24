import 'package:flutter/material.dart';

class TaskCronList extends StatelessWidget {
  const TaskCronList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Text(item)).toList(),
    );
  }
}
