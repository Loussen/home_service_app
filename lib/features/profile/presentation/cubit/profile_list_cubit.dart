import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_list_state.dart';

class ProfileListCubit extends Cubit<ProfileListState> {
  ProfileListCubit(this._repo) : super(const ProfileListState());

  final ProfileRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.listProfiles();
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (list) => emit(state.copyWith(loading: false, profiles: list)),
    );
  }

  Future<void> delete(int id) async {
    final result = await _repo.deleteProfile(id);
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (_) => load(),
    );
  }

  Future<void> setFullThisWeek(ProviderProfileModel profile, bool value) async {
    final result = await _repo.saveProfile(
      id: profile.id,
      categoryIds: profile.categoryIds,
      latitude: profile.latitude,
      longitude: profile.longitude,
      title: profile.title,
      bio: profile.bio,
      city: profile.city,
      district: profile.district,
      cityId: profile.cityId,
      districtId: profile.districtId,
      isActive: profile.isActive,
      schedules: profile.schedules,
      fullThisWeek: value,
      quietHoursStart: profile.quietHoursStart,
      quietHoursEnd: profile.quietHoursEnd,
    );
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (_) => load(),
    );
  }

  Future<double?> bump(int id) async {
    final result = await _repo.bump(id);
    return result.fold(
      (f) {
        emit(state.copyWith(message: f.message));
        return null;
      },
      (data) {
        load();
        return data.balance;
      },
    );
  }
}
