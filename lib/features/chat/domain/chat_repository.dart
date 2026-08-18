import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ConversationModel>>> list();

  Future<Either<Failure, ConversationModel>> get(int id);

  Future<Either<Failure, ConversationModel>> connect({
    required int providerProfileId,
    int? serviceRequestId,
    String? message,
  });

  Future<Either<Failure, ConversationModel>> replyToJob({
    required int serviceRequestId,
    int? providerProfileId,
    String? message,
  });

  Future<Either<Failure, ChatMessageModel>> send(int conversationId, String body);

  Future<Either<Failure, ConversationModel>> sendOffer({
    required int conversationId,
    required DateTime scheduledAt,
    required double priceAzn,
    double? durationHours,
    String? note,
  });

  Future<Either<Failure, ConversationModel>> offerAction(int offerId, String action);

  Future<Either<Failure, Unit>> submitReview({
    required int offerId,
    required int rating,
    String? comment,
  });

  Future<Either<Failure, List<ChatReviewModel>>> listReviews();

  Future<Either<Failure, Unit>> blockUser(int userId);

  Future<Either<Failure, Unit>> reportUser({
    required int reportedUserId,
    required String reason,
    String? details,
    int? conversationId,
  });
}
