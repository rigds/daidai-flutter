class Task {
  final int? id;
  final String name;
  final String command;
  final String? cron;
  final bool enabled;

  const Task({
    this.id,
    required this.name,
    this.command = '',
    this.cron,
    this.enabled = true,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    name: json['name']?.toString() ?? json['title']?.toString() ?? '',
    command: json['command']?.toString() ?? '',
    cron: json['cron']?.toString(),
    enabled: json['enabled'] != false,
  );
}
