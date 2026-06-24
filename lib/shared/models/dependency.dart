class Dependency {
  final int? id;
  final String name;
  final String type;
  final String? status;

  const Dependency({this.id, required this.name, this.type = '', this.status});

  factory Dependency.fromJson(Map<String, dynamic> json) => Dependency(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    status: json['status']?.toString(),
  );
}
