import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

class IncomingJobModel {
  const IncomingJobModel({
    required this.matchId,
    required this.matchScore,
    required this.distanceKm,
    required this.providerProfileId,
    required this.isUrgent,
    this.profileTitle,
    this.requestId,
    this.requestStatus,
    this.transcribedText,
    this.address,
    this.categoryName,
    this.createdAt,
    this.clientName,
    this.reasons = const [],
  });

  final int matchId;
  final double matchScore;
  final double distanceKm;
  final int providerProfileId;
  final bool isUrgent;
  final String? profileTitle;
  final int? requestId;
  final String? requestStatus;
  final String? transcribedText;
  final String? address;
  final String? categoryName;
  final String? createdAt;
  final String? clientName;
  final List<MatchReason> reasons;

  factory IncomingJobModel.fromJson(Map<String, dynamic> json) {
    final request = json['request'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    final category = request?['category'] as Map<String, dynamic>?;
    final reasonsRaw = json['reasons'];
    final reasons = reasonsRaw is List
        ? reasonsRaw
            .whereType<Map>()
            .map((e) => MatchReason.fromJson(Map<String, dynamic>.from(e)))
            .where((r) => r.key.isNotEmpty)
            .toList()
        : <MatchReason>[];

    return IncomingJobModel(
      matchId: json['match_id'] as int,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      providerProfileId: json['provider_profile_id'] as int,
      isUrgent: json['is_urgent'] == true,
      profileTitle: json['profile_title'] as String?,
      requestId: request?['id'] as int?,
      requestStatus: request?['status'] as String?,
      transcribedText: request?['transcribed_text'] as String?,
      address: request?['address'] as String?,
      categoryName: category?['name'] as String? ??
          category?['name_az'] as String?,
      createdAt: request?['created_at'] as String?,
      clientName: client?['name'] as String?,
      reasons: reasons,
    );
  }
}
