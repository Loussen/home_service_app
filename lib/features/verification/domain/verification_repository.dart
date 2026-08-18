import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/verification/data/models/verification_document_model.dart';

abstract class VerificationRepository {
  Future<Either<Failure, List<VerificationDocumentModel>>> list();

  Future<Either<Failure, VerificationDocumentModel>> upload({
    required String filePath,
    String documentType,
    int? providerProfileId,
  });
}
