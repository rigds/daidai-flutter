class EnvVar {
  final int? id;
  final String key;
  final String value;
  final bool enabled;

  const EnvVar({this.id, required this.key, this.value = '', this.enabled = true});

  factory EnvVar.fromJson(Map<String, dynamic> json) => EnvVar(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    key: json['key']?.toString() ?? json['name']?.toString() ?? '',
    value: json['value']?.toString() ?? '',
    enabled: json['enabled'] != false,
  );
}
