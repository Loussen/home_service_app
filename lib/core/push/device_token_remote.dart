import 'package:dio/dio.dart';
import 'package:home_service_app/core/network/api_client.dart';

class DeviceTokenRemote {
  DeviceTokenRemote(this._client);

  final ApiClient _client;

  Future<void> register({required String token, required String platform}) async {
    await _client.dio.post(
      '/device-tokens',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregister(String token) async {
    try {
      await _client.dio.delete(
        '/device-tokens',
        data: {'token': token},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (_) {}
  }
}
