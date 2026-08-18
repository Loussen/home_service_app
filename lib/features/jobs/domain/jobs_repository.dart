import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';

abstract class JobsRepository {
  Future<Either<Failure, List<IncomingJobModel>>> list();
}
