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

  Future<List<ServiceRequestModel>> listRequests() async {
    final res = await _client.dio.get('/service-requests');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
