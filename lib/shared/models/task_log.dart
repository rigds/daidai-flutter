class TaskLog {
  final int? id;
  final int? taskId;
  final String content;
  final DateTime? createdAt;

  const TaskLog({this.id, this.taskId, this.content = '', this.createdAt});

  factory TaskLog.fromJson(Map<String, dynamic> json) => TaskLog(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    taskId: json['task_id'] is int
        ? json['task_id'] as int
        : int.tryParse('${json['task_id']}'),
    content: json['content']?.toString() ?? json['log']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}
