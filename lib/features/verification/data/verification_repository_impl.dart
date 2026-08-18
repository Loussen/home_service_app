import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/verification/data/models/verification_document_model.dart';
import 'package:home_service_app/features/verification/data/verification_remote_data_source.dart';
import 'package:home_service_app/features/verification/domain/verification_repository.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl(this._remote);

  final VerificationRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<VerificationDocumentModel>>> list() async {
    try {
      return Right(await _remote.list());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, VerificationDocumentModel>> upload({
    required String filePath,
    String documentType = 'id_card',
    int? providerProfileId,
  }) async {
    try {
      return Right(await _remote.upload(
        filePath: filePath,
        documentType: documentType,
        providerProfileId: providerProfileId,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? 'Request failed';
  }
}
