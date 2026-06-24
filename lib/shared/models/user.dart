class User {
  final int? id;
  final String username;
  final String? role;

  const User({this.id, required this.username, this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    username: json['username']?.toString() ?? '',
    role: json['role']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role,
  };
}
