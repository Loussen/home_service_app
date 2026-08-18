import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/bookings/data/bookings_remote_data_source.dart';
import 'package:home_service_app/features/bookings/data/models/booking_model.dart';
import 'package:home_service_app/features/bookings/domain/bookings_repository.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  BookingsRepositoryImpl(this._remote);

  final BookingsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<BookingModel>>> list() async {
    try {
      return Right(await _remote.list());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, BookingModel>> cancel(int id) async {
    try {
      return Right(await _remote.cancel(id));
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
