import 'package:dio/dio.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/location_models.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/data/models/schedule_slot.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> categories() async {
    final res = await _client.dio.get('/categories');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CityModel>> cities() async {
    final res = await _client.dio.get('/cities');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProviderProfileModel>> listProfiles() async {
    final res = await _client.dio.get('/provider-profiles');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => ProviderProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProviderProfileModel> getProfile(int id) async {
    final res = await _client.dio.get('/provider-profiles/$id');
    return ProviderProfileModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ProviderProfileModel> createProfile({
    required List<int> categoryIds,
    required double latitude,
    required double longitude,
    String? title,
    String? bio,
    String? city,
    String? district,
    int? cityId,
    int? districtId,
    List<ScheduleSlot> schedules = const [],
  }) async {
    final res = await _client.dio.post('/provider-profiles', data: {
      'category_ids': categoryIds,
      'category_id': categoryIds.first,
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'bio': bio,
      'city': city,
      'district': district,
      if (cityId != null) 'city_id': cityId,
      if (districtId != null) 'district_id': districtId,
      'schedules': schedules.map((s) => s.toJson()).toList(),
    });
    return ProviderProfileModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ProviderProfileModel> updateProfile({
    required int id,
    required List<int> categoryIds,
    required double latitude,
    required double longitude,
    String? title,
    String? bio,
    String? city,
    String? district,
    int? cityId,
    int? districtId,
    bool? isActive,
    List<ScheduleSlot> schedules = const [],
  }) async {
    final res = await _client.dio.put('/provider-profiles/$id', data: {
      'category_ids': categoryIds,
      'category_id': categoryIds.first,
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'bio': bio,
      'city': city,
      'district': district,
      if (cityId != null) 'city_id': cityId,
      if (districtId != null) 'district_id': districtId,
      if (isActive != null) 'is_active': isActive,
      'schedules': schedules.map((s) => s.toJson()).toList(),
    });
    return ProviderProfileModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ProviderProfileModel> uploadAudioIntro(int id, String filePath) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        filePath,
        filename: 'intro.m4a',
      ),
    });
    final res = await _client.dio.post(
      '/provider-profiles/$id/audio-intro',
      data: form,
    );
    return ProviderProfileModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteProfile(int id) async {
    await _client.dio.delete('/provider-profiles/$id');
  }

  Future<({ProviderProfileModel profile, double balance})> bump(int id) async {
    final res = await _client.dio.post('/provider-profiles/$id/bump');
    final data = res.data['data'] as Map<String, dynamic>;
    return (
      profile: ProviderProfileModel.fromJson(
        data['profile'] as Map<String, dynamic>,
      ),
      balance: (data['balance'] as num).toDouble(),
    );
  }
}
