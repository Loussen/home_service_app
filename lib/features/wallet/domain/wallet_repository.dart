import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';

abstract class WalletRepository {
  Future<Either<Failure, Map<String, dynamic>>> balance();
  Future<Either<Failure, List<dynamic>>> transactions();
}
