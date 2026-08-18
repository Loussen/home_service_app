import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/core/network/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    // ignore: avoid_print
    print('[API] baseUrl=${AppConfig.apiBaseUrl}');

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Valet uses a local TLS certificate (not public CA).
    // Accept it for local *.test hosts so physical / simulator debug works.
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          final h = host.toLowerCase();
          return h.endsWith('.test') ||
              h == 'localhost' ||
              h == '127.0.0.1' ||
              h.endsWith('.local');
        };
        return client;
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final path = error.requestOptions.uri.path;
          final isLogout = path.endsWith('/auth/logout');
          if (!(isLogout && error.response?.statusCode == 401)) {
            // ignore: avoid_print
            print(
              '[API] ${error.requestOptions.method} ${error.requestOptions.uri} → '
              '${error.type.name}: ${error.message}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  Dio get dio => _dio;
}
