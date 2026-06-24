class NotifyChannel {
  final int? id;
  final String name;
  final String type;
  final bool enabled;

  const NotifyChannel({this.id, required this.name, this.type = '', this.enabled = true});

  factory NotifyChannel.fromJson(Map<String, dynamic> json) => NotifyChannel(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    enabled: json['enabled'] != false,
  );
}
