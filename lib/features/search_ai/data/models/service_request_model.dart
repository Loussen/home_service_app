import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/utils/json_numbers.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';

class MatchReason {
  const MatchReason({required this.key, this.params = const {}});

  final String key;
  final Map<String, String> params;

  factory MatchReason.fromJson(Map<String, dynamic> json) {
    final paramsRaw = json['params'];
    final params = <String, String>{};
    if (paramsRaw is Map) {
      for (final e in paramsRaw.entries) {
        params['${e.key}'] = '${e.value}';
      }
    }
    return MatchReason(
      key: (json['key'] as String?) ?? '',
      params: params,
    );
  }

  String get label => t(key, params: params.isEmpty ? null : params);
}

class MatchModel {
  const MatchModel({
    required this.matchScore,
    required this.distanceKm,
    this.id,
    this.scoreBreakdown,
    this.reasons = const [],
    this.provider,
    this.mergedProfileCount = 1,
  });

  final int? id;
  final double matchScore;
  final double distanceKm;
  final Map<String, dynamic>? scoreBreakdown;
  final List<MatchReason> reasons;
  final ProviderProfileModel? provider;
  final int mergedProfileCount;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final providerJson = json['provider'] as Map<String, dynamic>?;
    final reasonsRaw = json['reasons'];
    final reasons = reasonsRaw is List
        ? reasonsRaw
            .whereType<Map>()
            .map((e) => MatchReason.fromJson(Map<String, dynamic>.from(e)))
            .where((r) => r.key.isNotEmpty)
            .toList()
        : <MatchReason>[];
    return MatchModel(
      id: json['id'] as int?,
      matchScore: parseDouble(json['match_score']),
      distanceKm: parseDouble(json['distance_km']),
      scoreBreakdown: json['score_breakdown'] as Map<String, dynamic>?,
      reasons: reasons,
      provider: providerJson != null
          ? ProviderProfileModel.fromJson(providerJson)
          : null,
      mergedProfileCount:
          (json['merged_profile_count'] as num?)?.toInt() ?? 1,
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
    this.matchesCount,
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
  /// List endpoint may omit `matches` but still send a count.
  final int? matchesCount;
  final String? createdAt;

  bool get isProcessing => status == 'processing';
  bool get isReady => status == 'active' || status == 'matched';
  bool get transcriptionFailed => parsedCriteria?['transcription_failed'] == true;

  Map<String, dynamic>? get searchMeta {
    final raw = parsedCriteria?['search_meta'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

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
      matchesCount: json['matches_count'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }
}
