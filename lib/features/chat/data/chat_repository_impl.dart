import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/chat/data/chat_remote_data_source.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ConversationModel>>> list() async {
    try {
      return Right(await _remote.list());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> get(int id) async {
    try {
      return Right(await _remote.get(id));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> connect({
    required int providerProfileId,
    int? serviceRequestId,
    String? message,
  }) async {
    try {
      return Right(await _remote.connect(
        providerProfileId: providerProfileId,
        serviceRequestId: serviceRequestId,
        message: message,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> replyToJob({
    required int serviceRequestId,
    int? providerProfileId,
    String? message,
  }) async {
    try {
      return Right(await _remote.replyToJob(
        serviceRequestId: serviceRequestId,
        providerProfileId: providerProfileId,
        message: message,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ChatMessageModel>> send(
    int conversationId,
    String body,
  ) async {
    try {
      return Right(await _remote.send(conversationId, body));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> sendOffer({
    required int conversationId,
    required DateTime scheduledAt,
    required double priceAzn,
    double? durationHours,
    String? note,
  }) async {
    try {
      return Right(await _remote.sendOffer(
        conversationId: conversationId,
        scheduledAt: scheduledAt,
        priceAzn: priceAzn,
        durationHours: durationHours,
        note: note,
      ));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> offerAction(
    int offerId,
    String action,
  ) async {
    try {
      return Right(await _remote.offerAction(offerId, action));
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitReview({
    required int offerId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _remote.submitReview(
        offerId: offerId,
        rating: rating,
        comment: comment,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, List<ChatReviewModel>>> listReviews() async {
    try {
      return Right(await _remote.listReviews());
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> blockUser(int userId) async {
    try {
      await _remote.blockUser(userId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> reportUser({
    required int reportedUserId,
    required String reason,
    String? details,
    int? conversationId,
  }) async {
    try {
      await _remote.reportUser(
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
        conversationId: conversationId,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(_msg(e)));
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? 'Request failed';
  }
}
