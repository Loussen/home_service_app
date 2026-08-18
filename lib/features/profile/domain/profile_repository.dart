import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/location_models.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/data/models/schedule_slot.dart';

abstract class ProfileRepository {
  Future<Either<Failure, List<CategoryModel>>> categories();

  Future<Either<Failure, List<CityModel>>> cities();

  Future<Either<Failure, List<ProviderProfileModel>>> listProfiles();

  Future<Either<Failure, ProviderProfileModel>> getProfile(int id);

  Future<Either<Failure, ProviderProfileModel>> saveProfile({
    int? id,
    required List<int> categoryIds,
    required double latitude,
    required double longitude,
    String? title,
    String? bio,
    String? city,
    String? district,
    int? cityId,
    int? districtId,
    bool? isActive,
    bool? fullThisWeek,
    String? quietHoursStart,
    String? quietHoursEnd,
    List<ScheduleSlot> schedules,
  });

  Future<Either<Failure, ProviderProfileModel>> uploadAudio(int id, String path);

  Future<Either<Failure, Unit>> deleteProfile(int id);

  Future<Either<Failure, ({ProviderProfileModel profile, double balance})>>
      bump(int id);
}
