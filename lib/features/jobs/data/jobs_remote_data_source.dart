import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';

class JobsRemoteDataSource {
  JobsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<IncomingJobModel>> list() async {
    final res = await _client.dio.get('/jobs');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => IncomingJobModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
