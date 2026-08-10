import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
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
