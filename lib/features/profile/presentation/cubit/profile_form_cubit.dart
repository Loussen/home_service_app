import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_service_app/features/profile/data/location_matcher.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/location_models.dart';
import 'package:home_service_app/features/profile/data/places_client.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_state.dart';

class ProfileFormCubit extends Cubit<ProfileFormState> {
  ProfileFormCubit(this._repo, {int? profileId})
      : super(ProfileFormState(
          profileId: profileId,
          schedules: ProfileFormState.emptyMatrix(),
        ));

  final ProfileRepository _repo;
  final _places = PlacesClient();

  Future<void> init() async {
    emit(state.copyWith(loading: true, clearMessage: true));

    final catsResult = await _repo.categories();
    final locResult = await _repo.cities();
    final List<CategoryModel> categories = catsResult.fold(
      (_) => <CategoryModel>[],
      (c) => c,
    );
    final List<CityModel> locations = locResult.fold(
      (_) => <CityModel>[],
      (c) => c,
    );

    LocationMatch matchLocation({
      int? cityId,
      int? districtId,
      String? cityName,
      String? districtName,
      List<String> hints = const [],
    }) {
      return LocationMatcher.match(
        locations,
        cityId: cityId,
        districtId: districtId,
        cityName: cityName,
        districtName: districtName,
        hints: hints,
      );
    }

    if (state.profileId != null) {
      final res = await _repo.getProfile(state.profileId!);
      res.fold(
        (f) => emit(state.copyWith(loading: false, message: f.message)),
        (p) {
          final loc = matchLocation(
            cityId: p.cityId,
            districtId: p.districtId,
            cityName: p.city,
            districtName: p.district,
          );
          emit(state.copyWith(
            loading: false,
            categories: categories,
            locations: locations,
            categoryIds: p.categoryIds,
            title: p.title ?? '',
            bio: p.bio ?? '',
            cityId: loc.cityId,
            districtId: loc.districtId,
            city: loc.city,
            district: loc.district,
            latitude: p.latitude,
            longitude: p.longitude,
            schedules: ProfileFormState.fromSlots(p.schedules),
            audioIntroUrl: p.audioIntroUrl,
            fullThisWeek: p.isFull,
            quietHoursStart: p.quietHoursStart,
            quietHoursEnd: p.quietHoursEnd,
          ));
        },
      );
      return;
    }

    final loc = matchLocation(cityName: 'Bakı');
    emit(state.copyWith(
      loading: false,
      categories: categories,
      locations: locations,
      cityId: loc.cityId,
      districtId: loc.districtId,
      city: loc.city,
      district: loc.district,
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
      try {
        final place = await _places.reverseGeocode(pos.latitude, pos.longitude);
        if (place != null) applyPlace(place);
      } catch (_) {}
    } catch (_) {
      // keep default Baku coords
    }
  }

  void setCoordinates(double lat, double lng) {
    emit(state.copyWith(latitude: lat, longitude: lng));
  }

  void applyPlace(ResolvedPlace place) {
    final loc = LocationMatcher.match(state.locations, hints: place.hints);
    emit(state.copyWith(
      latitude: place.latitude,
      longitude: place.longitude,
      cityId: loc.cityId,
      districtId: loc.districtId,
      city: loc.city,
      district: loc.district,
      clearDistrict: true,
    ));
  }

  void setCategoryIds(List<int> ids) => emit(state.copyWith(categoryIds: ids));

  void setTitle(String v) => emit(state.copyWith(title: v));

  void setBio(String v) => emit(state.copyWith(bio: v));

  void setCityId(int id) {
    CityModel? city;
    for (final c in state.locations) {
      if (c.id == id) city = c;
    }
    final only = city != null && city.districts.length == 1
        ? city.districts.first
        : null;
    emit(state.copyWith(
      cityId: id,
      city: city?.name ?? state.city,
      districtId: only?.id,
      district: only?.name ?? '',
      clearDistrict: true,
    ));
  }

  void setDistrictId(int id) {
    DistrictModel? district;
    for (final c in state.locations) {
      if (c.id != state.cityId) continue;
      for (final d in c.districts) {
        if (d.id == id) district = d;
      }
    }
    emit(state.copyWith(
      districtId: id,
      district: district?.name ?? state.district,
    ));
  }

  void toggleSlot(int day, String slot) {
    final key = '${day}_$slot';
    final next = Map<String, bool>.from(state.schedules);
    next[key] = !(next[key] ?? false);
    emit(state.copyWith(schedules: next));
  }

  void setLocalAudio(String? path) {
    emit(state.copyWith(localAudioPath: path));
  }

  void setFullThisWeek(bool value) => emit(state.copyWith(fullThisWeek: value));

  void setQuietHours(String? start, String? end) => emit(state.copyWith(
        quietHoursStart: start,
        quietHoursEnd: end,
        clearQuietHours: true,
      ));

  Future<bool> save() async {
    if (state.categoryIds.isEmpty) {
      emit(state.copyWith(
        message: t('category.min_one',
            params: {'max': '${AppRemoteConfig.instance.config.maxCategoryTags}'}),
      ));
      return false;
    }

    emit(state.copyWith(saving: true, clearMessage: true, clearSaved: true));

    final result = await _repo.saveProfile(
      id: state.profileId,
      categoryIds: state.categoryIds,
      latitude: state.latitude,
      longitude: state.longitude,
      title: state.title.trim().isEmpty ? null : state.title.trim(),
      bio: state.bio.trim().isEmpty ? null : state.bio.trim(),
      city: state.city.trim().isEmpty ? null : state.city.trim(),
      district: state.district.trim().isEmpty ? null : state.district.trim(),
      cityId: state.cityId,
      districtId: state.districtId,
      schedules: state.toSlots(),
      fullThisWeek: state.fullThisWeek,
      quietHoursStart: state.quietHoursStart,
      quietHoursEnd: state.quietHoursEnd,
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
