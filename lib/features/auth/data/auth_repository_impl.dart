import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/core/network/token_storage.dart';
import 'package:home_service_app/features/auth/data/auth_remote_data_source.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';
import 'package:home_service_app/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Either<Failure, Unit>> sendOtp(String phone) async {
    try {
      await _remote.sendOtp(phone);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, ({UserModel user, bool isNew})>> verifyOtp(
    String phone,
    String code,
  ) async {
    try {
      final result = await _remote.verifyOtp(phone, code);
      await _tokens.saveToken(result.token);
      return Right((user: result.user, isNew: result.isNew));
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, UserModel>> bootstrap() async {
    try {
      final token = await _tokens.readToken();
      if (token == null) {
        return const Left(CacheFailure('No token'));
      }
      final user = await _remote.me();
      return Right(user);
    } on DioException catch (e) {
      await _tokens.clear();
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, UserModel>> setRole(String role) async {
    try {
      final user = await _remote.setRole(role);
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, UserModel>> updateProfile({String? name}) async {
    try {
      return Right(await _remote.updateProfile(name: name));
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, UserModel>> uploadAvatar(String filePath) async {
    try {
      return Right(await _remote.uploadAvatar(filePath));
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _remote.logout();
    } catch (_) {}
    await _tokens.clear();
    return const Right(unit);
  }

  String _message(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'API-yə qoşulmaq mümkün olmadı. '
          'Mac və telefon eyni Wi‑Fi-də olmalıdır.';
    }
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      final msg = data['message'] as String;
      final errors = data['errors'] ?? data['data'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        if (first is String) return first;
      }
      return msg;
    }
    return e.message ?? 'Request failed';
  }
}
