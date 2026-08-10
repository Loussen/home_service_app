import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/wallet/data/wallet_remote_data_source.dart';
import 'package:home_service_app/features/wallet/domain/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remote);
  final WalletRemoteDataSource _remote;

  @override
  Future<Either<Failure, Map<String, dynamic>>> balance() async {
    try {
      return Right(await _remote.balance());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> transactions() async {
    try {
      return Right(await _remote.transactions());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error'));
    }
  }
}
