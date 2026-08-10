class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final T? data;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? map,
  ) {
    return ApiResponse(
      success: json['success'] == true,
      message: (json['message'] as String?) ?? '',
      data: map != null ? map(json['data']) : json['data'] as T?,
    );
  }
}
