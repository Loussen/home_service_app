import 'package:dio/dio.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/features/verification/data/models/verification_document_model.dart';

class VerificationRemoteDataSource {
  VerificationRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<VerificationDocumentModel>> list() async {
    final res = await _client.dio.get('/verification-documents');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => VerificationDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VerificationDocumentModel> upload({
    required String filePath,
    String documentType = 'id_card',
    int? providerProfileId,
  }) async {
    final form = FormData.fromMap({
      'document': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
      'document_type': documentType,
      if (providerProfileId != null) 'provider_profile_id': providerProfileId,
    });
    final res = await _client.dio.post('/verification-documents', data: form);
    return VerificationDocumentModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }
}
