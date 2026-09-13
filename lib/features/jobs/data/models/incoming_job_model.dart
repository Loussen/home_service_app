import 'package:home_service_app/core/utils/media_url.dart';
import 'package:home_service_app/core/utils/request_when.dart';
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
    this.latitude,
    this.longitude,
    this.audioUrl,
    this.categoryName,
    this.createdAt,
    this.expiresAt,
    this.clientName,
    this.parsedCriteria,
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
  final double? latitude;
  final double? longitude;
  final String? audioUrl;
  final String? categoryName;
  final String? createdAt;
  final String? expiresAt;
  final String? clientName;
  final Map<String, dynamic>? parsedCriteria;
  final List<MatchReason> reasons;

  String? get serviceWhenLabel => formatRequestServiceWhen(parsedCriteria);

  bool get hasAudio => audioUrl != null && audioUrl!.trim().isNotEmpty;

  factory IncomingJobModel.fromJson(Map<String, dynamic> json) {
    final request = json['request'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    final category = request?['category'] as Map<String, dynamic>?;
    final criteriaRaw = request?['parsed_criteria'];
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
      latitude: (request?['latitude'] as num?)?.toDouble(),
      longitude: (request?['longitude'] as num?)?.toDouble(),
      audioUrl: resolveMediaUrl(
        request?['audio_url'] as String? ??
            request?['raw_audio_url'] as String?,
      ),
      categoryName: category?['name'] as String? ??
          category?['name_az'] as String?,
      createdAt: request?['created_at'] as String?,
      expiresAt: request?['expires_at'] as String?,
      clientName: client?['name'] as String?,
      parsedCriteria: criteriaRaw is Map
          ? Map<String, dynamic>.from(criteriaRaw)
          : null,
      reasons: reasons,
    );
  }
}
