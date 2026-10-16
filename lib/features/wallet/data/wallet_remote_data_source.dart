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

  Future<Map<String, dynamic>> confirmIap({
    required String platform,
    required String productId,
    required String verificationData,
    String? purchaseId,
  }) async {
    final res = await _client.dio.post('/wallet/iap/confirm', data: {
      'platform': platform,
      'product_id': productId,
      'verification_data': verificationData,
      if (purchaseId != null && purchaseId.isNotEmpty) 'purchase_id': purchaseId,
    });
    return res.data['data'] as Map<String, dynamic>;
  }
}
