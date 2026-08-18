import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/location_models.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/data/models/schedule_slot.dart';

class ProfileFormState extends Equatable {
  const ProfileFormState({
    this.profileId,
    this.categories = const [],
    this.categoryIds = const [],
    this.title = '',
    this.bio = '',
    this.locations = const [],
    this.cityId,
    this.districtId,
    this.city = 'Bakı',
    this.district = '',
    this.latitude = 40.4093,
    this.longitude = 49.8671,
    this.schedules = const {},
    this.audioIntroUrl,
    this.localAudioPath,
    this.fullThisWeek = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.loading = false,
    this.saving = false,
    this.message,
    this.savedProfile,
  });

  final int? profileId;
  final List<CategoryModel> categories;
  final List<int> categoryIds;
  final List<CityModel> locations;
  final int? cityId;
  final int? districtId;
  final String title;
  final String bio;
  final String city;
  final String district;
  final double latitude;
  final double longitude;

  /// key: "day_slot" e.g. "1_morning"
  final Map<String, bool> schedules;
  final String? audioIntroUrl;
  final String? localAudioPath;
  final bool fullThisWeek;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool loading;
  final bool saving;
  final String? message;
  final ProviderProfileModel? savedProfile;

  static Map<String, bool> emptyMatrix({bool available = false}) {
    final map = <String, bool>{};
    for (var day = 1; day <= 7; day++) {
      for (final slot in TimeSlots.all) {
        map['${day}_$slot'] = available;
      }
    }
    return map;
  }

  static Map<String, bool> fromSlots(List<ScheduleSlot> slots) {
    final map = emptyMatrix();
    for (final s in slots) {
      map['${s.dayOfWeek}_${s.timeSlot}'] = s.isAvailable;
    }
    return map;
  }

  List<ScheduleSlot> toSlots() {
    return schedules.entries
        .where((e) => e.value)
        .map((e) {
          final parts = e.key.split('_');
          return ScheduleSlot(
            dayOfWeek: int.parse(parts[0]),
            timeSlot: parts[1],
            isAvailable: true,
          );
        })
        .toList();
  }

  ProfileFormState copyWith({
    int? profileId,
    List<CategoryModel>? categories,
    List<int>? categoryIds,
    List<CityModel>? locations,
    int? cityId,
    int? districtId,
    String? title,
    String? bio,
    String? city,
    String? district,
    double? latitude,
    double? longitude,
    Map<String, bool>? schedules,
    String? audioIntroUrl,
    String? localAudioPath,
    bool? fullThisWeek,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? loading,
    bool? saving,
    String? message,
    ProviderProfileModel? savedProfile,
    bool clearMessage = false,
    bool clearSaved = false,
    bool clearDistrict = false,
    bool clearQuietHours = false,
  }) {
    return ProfileFormState(
      profileId: profileId ?? this.profileId,
      categories: categories ?? this.categories,
      categoryIds: categoryIds ?? this.categoryIds,
      locations: locations ?? this.locations,
      cityId: cityId ?? this.cityId,
      districtId: clearDistrict ? districtId : (districtId ?? this.districtId),
      title: title ?? this.title,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      schedules: schedules ?? this.schedules,
      audioIntroUrl: audioIntroUrl ?? this.audioIntroUrl,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      fullThisWeek: fullThisWeek ?? this.fullThisWeek,
      quietHoursStart:
          clearQuietHours ? quietHoursStart : (quietHoursStart ?? this.quietHoursStart),
      quietHoursEnd:
          clearQuietHours ? quietHoursEnd : (quietHoursEnd ?? this.quietHoursEnd),
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      message: clearMessage ? null : (message ?? this.message),
      savedProfile: clearSaved ? null : (savedProfile ?? this.savedProfile),
    );
  }

  @override
  List<Object?> get props => [
        profileId,
        categories,
        categoryIds,
        locations,
        cityId,
        districtId,
        title,
        bio,
        city,
        district,
        latitude,
        longitude,
        schedules,
        audioIntroUrl,
        localAudioPath,
        fullThisWeek,
        quietHoursStart,
        quietHoursEnd,
        loading,
        saving,
        message,
        savedProfile,
      ];
}
