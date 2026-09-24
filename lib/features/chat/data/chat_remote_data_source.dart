import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<ConversationModel>> list() async {
    final res = await _client.dio.get('/conversations');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final res = await _client.dio.get('/conversations/unread-count');
    final data = res.data['data'];
    if (data is Map) {
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<ConversationModel> get(int id) async {
    final res = await _client.dio.get('/conversations/$id');
    return ConversationModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ConversationModel> connect({
    required int providerProfileId,
    int? serviceRequestId,
    String? message,
  }) async {
    final res = await _client.dio.post('/conversations', data: {
      'provider_profile_id': providerProfileId,
      if (serviceRequestId != null) 'service_request_id': serviceRequestId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
    return ConversationModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ConversationModel> replyToJob({
    required int serviceRequestId,
    int? providerProfileId,
    String? message,
  }) async {
    final res = await _client.dio.post('/conversations/reply', data: {
      'service_request_id': serviceRequestId,
      if (providerProfileId != null) 'provider_profile_id': providerProfileId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
    return ConversationModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ChatMessageModel> send(int conversationId, String body) async {
    final res = await _client.dio.post(
      '/conversations/$conversationId/messages',
      data: {'body': body},
    );
    return ChatMessageModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ConversationModel> sendOffer({
    required int conversationId,
    required DateTime scheduledAt,
    required double priceAzn,
    double? durationHours,
    String? note,
  }) async {
    final res = await _client.dio.post(
      '/conversations/$conversationId/offers',
      data: {
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'price_azn': priceAzn,
        if (durationHours != null) 'duration_hours': durationHours,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return ConversationModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ConversationModel> offerAction(int offerId, String action) async {
    final res = await _client.dio.post('/offers/$offerId/$action');
    return ConversationModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> submitReview({
    required int offerId,
    required int rating,
    String? comment,
  }) async {
    await _client.dio.post('/offers/$offerId/reviews', data: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  Future<List<ChatReviewModel>> listReviews() async {
    final res = await _client.dio.get('/reviews');
    final list = res.data['data'] as List<dynamic>;
    return list
        .whereType<Map>()
        .map((e) => ChatReviewModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> blockUser(int userId) async {
    await _client.dio.post('/users/$userId/block');
  }

  Future<void> unblockUser(int userId) async {
    await _client.dio.delete('/users/$userId/block');
  }

  Future<List<BlockedUserModel>> listBlockedUsers() async {
    final res = await _client.dio.get('/blocks');
    final list = res.data['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => BlockedUserModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> reportUser({
    required int reportedUserId,
    required String reason,
    String? details,
    int? conversationId,
  }) async {
    await _client.dio.post('/reports', data: {
      'reported_user_id': reportedUserId,
      'reason': reason,
      if (details != null && details.isNotEmpty) 'details': details,
      if (conversationId != null) 'conversation_id': conversationId,
    });
  }
}
