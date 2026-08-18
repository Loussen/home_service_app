import 'dart:convert';

import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/core/network/api_response.dart';
import 'package:home_service_app/core/remote/bootstrap_model.dart';

class BootstrapRemoteDataSource {
  BootstrapRemoteDataSource(this._api);

  final ApiClient _api;

  Future<BootstrapPayload> fetch({required String locale}) async {
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/bootstrap',
      queryParameters: {'locale': locale},
    );
    final body = res.data ?? {};
    final parsed = ApiResponse.fromJson(
      body,
      (raw) => BootstrapPayload.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ),
    );
    if (!parsed.success || parsed.data == null) {
      throw Exception(parsed.message.isNotEmpty ? parsed.message : 'Bootstrap failed');
    }
    return parsed.data!;
  }

  static Map<String, dynamic>? decodeCached(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
