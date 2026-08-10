import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_state.dart';

class ProfileFormCubit extends Cubit<ProfileFormState> {
  ProfileFormCubit(this._repo, {int? profileId})
      : super(ProfileFormState(
          profileId: profileId,
          schedules: ProfileFormState.emptyMatrix(),
        ));

  final ProfileRepository _repo;

  Future<void> init() async {
    emit(state.copyWith(loading: true, clearMessage: true));

    final catsResult = await _repo.categories();
    final List<CategoryModel> categories = catsResult.fold(
      (_) => <CategoryModel>[],
      (c) => c,
    );

    if (state.profileId != null) {
      final res = await _repo.getProfile(state.profileId!);
      res.fold(
        (f) => emit(state.copyWith(loading: false, message: f.message)),
        (p) => emit(state.copyWith(
          loading: false,
          categories: categories,
          categoryId: p.categoryId,
          title: p.title ?? '',
          bio: p.bio ?? '',
          city: p.city ?? 'Bakı',
          district: p.district ?? '',
          latitude: p.latitude,
          longitude: p.longitude,
          schedules: ProfileFormState.fromSlots(p.schedules),
          audioIntroUrl: p.audioIntroUrl,
        )),
      );
      return;
    }

    emit(state.copyWith(
      loading: false,
      categories: categories,
      categoryId: categories.isNotEmpty ? categories.first.id : null,
    ));

    await useCurrentLocation();
  }

  Future<void> useCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      emit(state.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
      ));
    } catch (_) {
      // keep default Baku coords
    }
  }

  void setCategory(int id) => emit(state.copyWith(categoryId: id));

  void setTitle(String v) => emit(state.copyWith(title: v));

  void setBio(String v) => emit(state.copyWith(bio: v));

  void setCity(String v) => emit(state.copyWith(city: v));

  void setDistrict(String v) => emit(state.copyWith(district: v));

  void toggleSlot(int day, String slot) {
    final key = '${day}_$slot';
    final next = Map<String, bool>.from(state.schedules);
    next[key] = !(next[key] ?? false);
    emit(state.copyWith(schedules: next));
  }

  void setLocalAudio(String? path) {
    emit(state.copyWith(localAudioPath: path));
  }

  Future<bool> save() async {
    final categoryId = state.categoryId;
    if (categoryId == null) {
      emit(state.copyWith(message: 'Kateqoriya seçin'));
      return false;
    }

    emit(state.copyWith(saving: true, clearMessage: true, clearSaved: true));

    final result = await _repo.saveProfile(
      id: state.profileId,
      categoryId: categoryId,
      latitude: state.latitude,
      longitude: state.longitude,
      title: state.title.trim().isEmpty ? null : state.title.trim(),
      bio: state.bio.trim().isEmpty ? null : state.bio.trim(),
      city: state.city.trim().isEmpty ? null : state.city.trim(),
      district: state.district.trim().isEmpty ? null : state.district.trim(),
      schedules: state.toSlots(),
    );

    return await result.fold<Future<bool>>(
      (f) async {
        emit(state.copyWith(saving: false, message: f.message));
        return false;
      },
      (profile) async {
        var saved = profile;
        final audioPath = state.localAudioPath;
        if (audioPath != null) {
          final audioRes = await _repo.uploadAudio(profile.id, audioPath);
          audioRes.fold(
            (f) => emit(state.copyWith(message: f.message)),
            (p) => saved = p,
          );
        }
        emit(state.copyWith(
          saving: false,
          profileId: saved.id,
          savedProfile: saved,
          audioIntroUrl: saved.audioIntroUrl,
          localAudioPath: null,
        ));
        return true;
      },
    );
  }
}
