class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({required this.success, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value)? parseData,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true || json['code'] == 200,
      message: json['message']?.toString(),
      data: parseData == null ? json['data'] as T? : parseData(json['data']),
    );
  }
}
