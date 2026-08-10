import 'package:home_service_app/core/utils/json_numbers.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';

class MatchModel {
  const MatchModel({
    required this.matchScore,
    required this.distanceKm,
    this.id,
    this.scoreBreakdown,
    this.provider,
  });

  final int? id;
  final double matchScore;
  final double distanceKm;
  final Map<String, dynamic>? scoreBreakdown;
  final ProviderProfileModel? provider;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final providerJson = json['provider'] as Map<String, dynamic>?;
    return MatchModel(
      id: json['id'] as int?,
      matchScore: parseDouble(json['match_score']),
      distanceKm: parseDouble(json['distance_km']),
      scoreBreakdown: json['score_breakdown'] as Map<String, dynamic>?,
      provider: providerJson != null
          ? ProviderProfileModel.fromJson(providerJson)
          : null,
    );
  }
}

class ServiceRequestModel {
  const ServiceRequestModel({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.categoryId,
    this.category,
    this.transcribedText,
    this.parsedCriteria,
    this.isUrgent = false,
    this.address,
    this.matches = const [],
    this.createdAt,
  });

  final int id;
  final int? categoryId;
  final CategoryModel? category;
  final String? transcribedText;
  final Map<String, dynamic>? parsedCriteria;
  final bool isUrgent;
  final double latitude;
  final double longitude;
  final String? address;
  final String status;
  final List<MatchModel> matches;
  final String? createdAt;

  bool get isProcessing => status == 'processing';
  bool get isReady => status == 'active' || status == 'matched';

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'] as Map<String, dynamic>?;
    final matchesJson = json['matches'] as List<dynamic>? ?? [];

    return ServiceRequestModel(
      id: json['id'] as int,
      categoryId: json['category_id'] as int?,
      category:
          categoryJson != null ? CategoryModel.fromJson(categoryJson) : null,
      transcribedText: json['transcribed_text'] as String?,
      parsedCriteria: json['parsed_criteria'] as Map<String, dynamic>?,
      isUrgent: json['is_urgent'] == true,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'active',
      matches: matchesJson
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }
}
