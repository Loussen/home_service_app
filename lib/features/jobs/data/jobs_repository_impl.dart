import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/jobs/data/jobs_remote_data_source.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';
import 'package:home_service_app/features/jobs/domain/jobs_repository.dart';

class JobsRepositoryImpl implements JobsRepository {
  JobsRepositoryImpl(this._remote);

  final JobsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<IncomingJobModel>>> list() async {
    try {
      return Right(await _remote.list());
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map && data['message'] is String
          ? data['message'] as String
          : (e.message ?? 'Xəta');
      return Left(ServerFailure(msg));
    }
  }
}
