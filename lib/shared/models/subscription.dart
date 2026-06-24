class Subscription {
  final int? id;
  final String name;
  final String url;
  final bool enabled;

  const Subscription({this.id, required this.name, this.url = '', this.enabled = true});

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
    name: json['name']?.toString() ?? '',
    url: json['url']?.toString() ?? '',
    enabled: json['enabled'] != false,
  );
}
