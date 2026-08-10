import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/data/models/schedule_slot.dart';
import 'package:home_service_app/features/profile/data/profile_remote_data_source.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<CategoryModel>>> categories() async {
    try {
      return Right(await _remote.categories());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, List<ProviderProfileModel>>> listProfiles() async {
    try {
      return Right(await _remote.listProfiles());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ProviderProfileModel>> getProfile(int id) async {
    try {
      return Right(await _remote.getProfile(id));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ProviderProfileModel>> saveProfile({
    int? id,
    required int categoryId,
    required double latitude,
    required double longitude,
    String? title,
    String? bio,
    String? city,
    String? district,
    bool? isActive,
    List<ScheduleSlot> schedules = const [],
  }) async {
    try {
      if (id == null) {
        return Right(await _remote.createProfile(
          categoryId: categoryId,
          latitude: latitude,
          longitude: longitude,
          title: title,
          bio: bio,
          city: city,
          district: district,
          schedules: schedules,
        ));
      }
      return Right(await _remote.updateProfile(
        id: id,
        categoryId: categoryId,
        latitude: latitude,
        longitude: longitude,
        title: title,
        bio: bio,
        city: city,
        district: district,
        isActive: isActive,
        schedules: schedules,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ProviderProfileModel>> uploadAudio(
    int id,
    String path,
  ) async {
    try {
      return Right(await _remote.uploadAudioIntro(id, path));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProfile(int id) async {
    try {
      await _remote.deleteProfile(id);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ({ProviderProfileModel profile, double balance})>>
      bump(int id) async {
    try {
      return Right(await _remote.bump(id));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (data is Map && data['data'] is Map) {
      final errors = data['data'] as Map;
      if (errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    return e.message ?? 'Request failed';
  }
}
