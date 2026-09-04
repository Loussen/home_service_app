import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/core/network/token_storage.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

typedef AccountBlockedHandler = void Function(String message);

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
          'X-Client': 'app',
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
          options.headers['Accept-Language'] = AppRemoteConfig.instance.locale;
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

          final data = error.response?.data;
          if (error.response?.statusCode == 403 &&
              data is Map &&
              data['code'] == 'ACCOUNT_BLOCKED') {
            final msg = data['message'] is String
                ? data['message'] as String
                : t('web.auth.blocked_body');
            onAccountBlocked?.call(msg);
          }

          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  /// Wired from [AuthCubit] to alert + logout when admin blocks the account.
  AccountBlockedHandler? onAccountBlocked;

  Dio get dio => _dio;
}
