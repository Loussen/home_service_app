import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/notifications/data/notifications_remote_data_source.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, ({List<AppNotificationModel> items, int unreadCount})>>
      list({String status = 'all'});

  Future<Either<Failure, int>> unreadCount();

  Future<Either<Failure, AppNotificationModel>> markRead(String id);

  Future<Either<Failure, Unit>> markAllRead();
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<Either<Failure, ({List<AppNotificationModel> items, int unreadCount})>>
      list({String status = 'all'}) async {
    try {
      return Right(await _remote.list(status: status));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, int>> unreadCount() async {
    try {
      return Right(await _remote.unreadCount());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, AppNotificationModel>> markRead(String id) async {
    try {
      return Right(await _remote.markRead(id));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async {
    try {
      await _remote.markAllRead();
      return const Right(unit);
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
