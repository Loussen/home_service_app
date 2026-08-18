import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';
import 'package:home_service_app/features/search_ai/data/search_remote_data_source.dart';
import 'package:home_service_app/features/search_ai/domain/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<Either<Failure, ServiceRequestModel>> submitAudio({
    required String filePath,
    required double latitude,
    required double longitude,
    String? address,
    bool isUrgent = false,
    int? categoryId,
    DateTime? scheduledAt,
    String? timeSlot,
  }) async {
    try {
      return Right(await _remote.submitAudio(
        filePath: filePath,
        latitude: latitude,
        longitude: longitude,
        address: address,
        isUrgent: isUrgent,
        categoryId: categoryId,
        scheduledAt: scheduledAt,
        timeSlot: timeSlot,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestModel>> submitText({
    required String text,
    required double latitude,
    required double longitude,
    int? categoryId,
    String? address,
    bool isUrgent = false,
    DateTime? scheduledAt,
    String? timeSlot,
  }) async {
    try {
      return Right(await _remote.submitText(
        text: text,
        latitude: latitude,
        longitude: longitude,
        categoryId: categoryId,
        address: address,
        isUrgent: isUrgent,
        scheduledAt: scheduledAt,
        timeSlot: timeSlot,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ServiceRequestModel>> getRequest(int id) async {
    try {
      return Right(await _remote.getRequest(id));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, List<ServiceRequestModel>>> listRequests() async {
    try {
      return Right(await _remote.listRequests());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ({ServiceRequestModel request, double balance})>>
      markUrgent(int id) async {
    try {
      return Right(await _remote.markUrgent(id));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      final msg = data['message'] as String;
      final errors = data['errors'] ?? data['data'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
      return msg;
    }
    return e.message ?? 'Request failed';
  }
}
