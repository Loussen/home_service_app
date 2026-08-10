import 'package:home_service_app/core/network/api_client.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> balance() async {
    final res = await _client.dio.get('/wallet');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> transactions() async {
    final res = await _client.dio.get('/wallet/transactions');
    return res.data['data'] as List<dynamic>;
  }
}
