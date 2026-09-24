import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/utils/media_url.dart';
import 'package:home_service_app/core/utils/request_status.dart';
import 'package:home_service_app/core/utils/request_when.dart';

class ChatUserModel {
  const ChatUserModel({
    required this.id,
    this.name,
    this.phone,
    this.avatarUrl,
  });

  final int id;
  final String? name;
  final String? phone;
  final String? avatarUrl;

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!;
    return t('account.user_fallback');
  }

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: resolveMediaUrl(json['avatar_url'] as String?),
    );
  }
}

class ConversationRequestSummary {
  const ConversationRequestSummary({
    required this.id,
    this.transcribedText,
    this.address,
    this.audioUrl,
    this.status,
    this.isUrgent = false,
    this.categoryName,
    this.createdAt,
    this.expiresAt,
    this.parsedCriteria,
  });

  final int id;
  final String? transcribedText;
  final String? address;
  final String? audioUrl;
  final String? status;
  final bool isUrgent;
  final String? categoryName;
  final String? createdAt;
  final String? expiresAt;
  final Map<String, dynamic>? parsedCriteria;

  bool get hasAudio => audioUrl != null && audioUrl!.trim().isNotEmpty;

  String? get displayPlace =>
      displayRequestPlace(parsedCriteria, address);

  String? get snippet {
    final text = transcribedText?.trim();
    if (text != null && text.isNotEmpty) {
      return text.length > 80 ? '${text.substring(0, 80)}…' : text;
    }
    final place = displayPlace;
    if (place != null && place.isNotEmpty) return place;
    return null;
  }

  String? get whenLabel => formatRequestServiceWhen(parsedCriteria);

  /// Compact line for list/thread: "snippet · when" or either part.
  String? get contextLine {
    final parts = <String>[
      if (snippet != null) snippet!,
      if (whenLabel != null) whenLabel!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  factory ConversationRequestSummary.fromJson(Map<String, dynamic> json) {
    final criteria = json['parsed_criteria'];
    final category = json['category'] as Map<String, dynamic>?;
    return ConversationRequestSummary(
      id: json['id'] as int,
      transcribedText: json['transcribed_text'] as String?,
      address: json['address'] as String?,
      audioUrl: resolveMediaUrl(
        json['audio_url'] as String? ?? json['raw_audio_url'] as String?,
      ),
      status: json['status'] as String?,
      isUrgent: json['is_urgent'] == true,
      categoryName: category?['name'] as String? ??
          category?['name_az'] as String?,
      createdAt: json['created_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      parsedCriteria: criteria is Map<String, dynamic>
          ? criteria
          : (criteria is Map
              ? Map<String, dynamic>.from(criteria)
              : null),
    );
  }
}

class BlockedUserModel {
  const BlockedUserModel({
    required this.id,
    this.name,
    this.avatarUrl,
    this.role,
    this.blockedAt,
  });

  final int id;
  final String? name;
  final String? avatarUrl;
  final String? role;
  final String? blockedAt;

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!;
    return t('account.user_fallback');
  }

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      avatarUrl: resolveMediaUrl(json['avatar_url'] as String?),
      role: json['role'] as String?,
      blockedAt: json['blocked_at'] as String?,
    );
  }
}

class ChatReviewModel {
  const ChatReviewModel({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.offerId,
    this.comment,
    this.reviewerName,
  });

  final int id;
  final int reviewerId;
  final int revieweeId;
  final int rating;
  final int? offerId;
  final String? comment;
  final String? reviewerName;

  factory ChatReviewModel.fromJson(Map<String, dynamic> json) {
    return ChatReviewModel(
      id: json['id'] as int,
      reviewerId: json['reviewer_id'] as int,
      revieweeId: json['reviewee_id'] as int,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      offerId: json['offer_id'] as int?,
      comment: json['comment'] as String?,
      reviewerName: json['reviewer_name'] as String?,
    );
  }
}

class ChatOfferModel {
  const ChatOfferModel({
    required this.id,
    required this.conversationId,
    required this.proposedBy,
    required this.scheduledAt,
    required this.priceAzn,
    required this.status,
    this.durationHours,
    this.note,
    this.reviews = const [],
  });

  final int id;
  final int conversationId;
  final int proposedBy;
  final DateTime scheduledAt;
  final double priceAzn;
  final String status;
  final double? durationHours;
  final String? note;
  final List<ChatReviewModel> reviews;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  ChatReviewModel? reviewBy(int userId) {
    for (final r in reviews) {
      if (r.reviewerId == userId) return r;
    }
    return null;
  }

  factory ChatOfferModel.fromJson(Map<String, dynamic> json) {
    final reviewsRaw = json['reviews'];
    final reviews = reviewsRaw is List
        ? reviewsRaw
            .whereType<Map>()
            .map((e) => ChatReviewModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ChatReviewModel>[];
    return ChatOfferModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      proposedBy: json['proposed_by'] as int,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      priceAzn: (json['price_azn'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      note: json['note'] as String?,
      reviews: reviews,
    );
  }
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.type = 'text',
    this.body,
    this.offer,
    this.createdAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String type;
  final String? body;
  final ChatOfferModel? offer;
  final DateTime? createdAt;

  bool get isOffer => type == 'offer' || offer != null;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final offerJson = json['offer'];
    return ChatMessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      type: json['type'] as String? ?? 'text',
      body: json['body'] as String?,
      offer: offerJson is Map<String, dynamic>
          ? ChatOfferModel.fromJson(offerJson)
          : (offerJson is Map
              ? ChatOfferModel.fromJson(Map<String, dynamic>.from(offerJson))
              : null),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.clientId,
    required this.providerId,
    this.providerProfileId,
    this.serviceRequestId,
    this.serviceRequest,
    this.unreadCount = 0,
    this.canSendOffer = false,
    this.isBlocked = false,
    this.blockedByMe = false,
    this.canMessage = true,
    this.otherUser,
    this.profileTitle,
    this.lastMessage,
    this.lastMessageAt,
    this.messages = const [],
  });

  final int id;
  final int clientId;
  final int providerId;
  final int? providerProfileId;
  final int? serviceRequestId;
  final ConversationRequestSummary? serviceRequest;
  final int unreadCount;
  final bool canSendOffer;
  final bool isBlocked;
  final bool blockedByMe;
  final bool canMessage;
  final ChatUserModel? otherUser;
  final String? profileTitle;
  final ChatMessageModel? lastMessage;
  final DateTime? lastMessageAt;
  final List<ChatMessageModel> messages;

  ConversationModel copyWith({
    ChatMessageModel? lastMessage,
    DateTime? lastMessageAt,
    List<ChatMessageModel>? messages,
    ChatUserModel? otherUser,
    bool? canSendOffer,
    bool? isBlocked,
    bool? blockedByMe,
    bool? canMessage,
    ConversationRequestSummary? serviceRequest,
  }) {
    return ConversationModel(
      id: id,
      clientId: clientId,
      providerId: providerId,
      providerProfileId: providerProfileId,
      serviceRequestId: serviceRequestId,
      serviceRequest: serviceRequest ?? this.serviceRequest,
      unreadCount: unreadCount,
      canSendOffer: canSendOffer ?? this.canSendOffer,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedByMe: blockedByMe ?? this.blockedByMe,
      canMessage: canMessage ?? this.canMessage,
      otherUser: otherUser ?? this.otherUser,
      profileTitle: profileTitle,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final other = json['other_user'] as Map<String, dynamic>?;
    final profile = json['provider_profile'] as Map<String, dynamic>?;
    final last = json['last_message'] as Map<String, dynamic>?;
    final msgs = json['messages'] as List<dynamic>? ?? [];
    final isBlocked = json['is_blocked'] == true;
    final srJson = json['service_request'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      providerId: json['provider_id'] as int,
      providerProfileId: json['provider_profile_id'] as int?,
      serviceRequestId: json['service_request_id'] as int?,
      serviceRequest: srJson != null
          ? ConversationRequestSummary.fromJson(srJson)
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      canSendOffer: json['can_send_offer'] as bool? ?? false,
      isBlocked: isBlocked,
      blockedByMe: json['blocked_by_me'] == true,
      canMessage: json['can_message'] as bool? ?? !isBlocked,
      otherUser: other != null ? ChatUserModel.fromJson(other) : null,
      profileTitle: profile?['title'] as String? ??
          (profile?['category'] as Map<String, dynamic>?)?['name'] as String? ??
          (profile?['category'] as Map<String, dynamic>?)?['name_az'] as String?,
      lastMessage: last != null ? ChatMessageModel.fromJson(last) : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      messages: msgs
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
