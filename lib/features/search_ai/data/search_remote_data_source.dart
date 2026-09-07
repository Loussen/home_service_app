import 'package:dio/dio.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/core/utils/json_numbers.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

class SearchRemoteDataSource {
  SearchRemoteDataSource(this._client);

  final ApiClient _client;

  Future<ServiceRequestModel> submitAudio({
    required String filePath,
    required double latitude,
    required double longitude,
    String? address,
    bool isUrgent = false,
    int? categoryId,
    DateTime? scheduledAt,
    String? timeSlot,
    int? childAge,
    bool? hasPet,
    double? budgetMax,
    int? durationSeconds,
    int? ttlHours,
  }) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        filePath,
        filename: 'request.m4a',
      ),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (address != null) 'address': address,
      'is_urgent': isUrgent ? '1' : '0',
      if (categoryId != null) 'category_id': categoryId,
      if (scheduledAt != null)
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      if (timeSlot != null) 'time_slot': timeSlot,
      if (childAge != null) 'child_age': childAge,
      if (hasPet != null) 'has_pet': hasPet ? '1' : '0',
      if (budgetMax != null) 'budget_max': budgetMax,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (ttlHours != null) 'ttl_hours': ttlHours,
    });

    final res = await _client.dio.post('/service-requests/audio', data: form);
    return ServiceRequestModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ServiceRequestModel> submitText({
    required String text,
    required double latitude,
    required double longitude,
    int? categoryId,
    String? address,
    bool isUrgent = false,
    DateTime? scheduledAt,
    String? timeSlot,
    int? childAge,
    bool? hasPet,
    double? budgetMax,
    int? ttlHours,
  }) async {
    final res = await _client.dio.post('/service-requests/text', data: {
      'text': text,
      'latitude': latitude,
      'longitude': longitude,
      if (categoryId != null) 'category_id': categoryId,
      if (address != null) 'address': address,
      'is_urgent': isUrgent,
      if (scheduledAt != null)
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      if (timeSlot != null) 'time_slot': timeSlot,
      if (childAge != null) 'child_age': childAge,
      if (hasPet != null) 'has_pet': hasPet,
      if (budgetMax != null) 'budget_max': budgetMax,
      if (ttlHours != null) 'ttl_hours': ttlHours,
    });
    return ServiceRequestModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ServiceRequestModel> getRequest(int id) async {
    final res = await _client.dio.get('/service-requests/$id');
    return ServiceRequestModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<({
    List<ServiceRequestModel> items,
    int currentPage,
    int lastPage,
    int total,
  })> listRequests({
    int page = 1,
    int perPage = 10,
    String filter = 'all',
  }) async {
    final res = await _client.dio.get(
      '/service-requests',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'filter': filter,
      },
    );
    final raw = res.data['data'];
    if (raw is List) {
      final items = raw
          .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        items: items,
        currentPage: 1,
        lastPage: 1,
        total: items.length,
      );
    }
    final map = raw as Map<String, dynamic>;
    final list = (map['items'] as List<dynamic>? ?? const []);
    final meta = map['meta'] as Map<String, dynamic>? ?? const {};
    return (
      items: list
          .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? list.length,
    );
  }

  Future<({ServiceRequestModel request, double balance})> markUrgent(
    int id,
  ) async {
    final res = await _client.dio.post('/service-requests/$id/urgent');
    final data = res.data['data'] as Map<String, dynamic>;
    return (
      request: ServiceRequestModel.fromJson(
        data['request'] as Map<String, dynamic>,
      ),
      balance: parseDouble(data['balance']),
    );
  }
}
