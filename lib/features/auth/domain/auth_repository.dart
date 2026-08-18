import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, Unit>> sendOtp(String phone);
  Future<Either<Failure, ({UserModel user, bool isNew})>> verifyOtp(
    String phone,
    String code,
  );
  Future<Either<Failure, UserModel>> bootstrap();
  Future<Either<Failure, UserModel>> setRole(String role);
  Future<Either<Failure, UserModel>> updateProfile({String? name});
  Future<Either<Failure, Unit>> logout();
}
