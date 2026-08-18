import 'package:home_service_app/core/utils/json_numbers.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/schedule_slot.dart';

class ProviderProfileModel {
  const ProviderProfileModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    this.category,
    this.categories = const [],
    this.title,
    this.bio,
    this.audioIntroUrl,
    this.isVerified = false,
    this.isVip = false,
    this.city,
    this.district,
    this.cityId,
    this.districtId,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isActive = true,
    this.schedules = const [],
  });

  final int id;
  final int userId;
  final int categoryId;
  final CategoryModel? category;
  final List<CategoryModel> categories;
  final String? title;
  final String? bio;
  final String? audioIntroUrl;
  final bool isVerified;
  final bool isVip;
  final double latitude;
  final double longitude;
  final String? city;
  final String? district;
  final int? cityId;
  final int? districtId;
  final double ratingAvg;
  final int ratingCount;
  final bool isActive;
  final List<ScheduleSlot> schedules;

  List<int> get categoryIds {
    if (categories.isNotEmpty) {
      return categories.map((c) => c.id).toList();
    }
    return categoryId > 0 ? [categoryId] : const [];
  }

  List<String> get categoryLabels {
    if (categories.isNotEmpty) {
      return categories.map((c) => c.nameAz).toList();
    }
    if (category != null) return [category!.nameAz];
    return const [];
  }

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'] as Map<String, dynamic>?;
    final categoriesJson = json['categories'] as List<dynamic>? ?? [];
    final schedulesJson = json['schedules'] as List<dynamic>? ?? [];
    final parsedCategories = categoriesJson
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProviderProfileModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: (json['category_id'] as int?) ??
          (categoryJson?['id'] as int?) ??
          (parsedCategories.isNotEmpty ? parsedCategories.first.id : 0),
      category:
          categoryJson != null ? CategoryModel.fromJson(categoryJson) : null,
      categories: parsedCategories,
      title: json['title'] as String?,
      bio: json['bio'] as String?,
      audioIntroUrl: json['audio_intro_url'] as String?,
      isVerified: json['is_verified'] == true,
      isVip: json['is_vip'] == true,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      city: json['city'] as String?,
      district: json['district'] as String?,
      cityId: json['city_id'] as int?,
      districtId: json['district_id'] as int?,
      ratingAvg: parseDouble(json['rating_avg']),
      ratingCount: json['rating_count'] as int? ?? 0,
      isActive: json['is_active'] != false,
      schedules: schedulesJson
          .map((e) => ScheduleSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
