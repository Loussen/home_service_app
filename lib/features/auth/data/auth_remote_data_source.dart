import 'package:dio/dio.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  Future<void> sendOtp(String phone) async {
    await _client.dio.post('/auth/otp/send', data: {'phone': phone});
  }

  Future<({String token, UserModel user, bool isNew})> verifyOtp(
    String phone,
    String code,
  ) async {
    final res = await _client.dio.post(
      '/auth/otp/verify',
      data: {'phone': phone, 'code': code},
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      isNew: data['is_new_user'] == true,
    );
  }

  Future<UserModel> me() async {
    final res = await _client.dio.get('/auth/me');
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> setRole(String role) async {
    final res = await _client.dio.post('/auth/role', data: {'role': role});
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile({String? name}) async {
    final res = await _client.dio.patch(
      '/auth/profile',
      data: {
        if (name != null) 'name': name,
      },
    );
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final res = await _client.dio.post('/auth/avatar', data: form);
    return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.dio.post(
      '/auth/logout',
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
