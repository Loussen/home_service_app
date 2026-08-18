import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';
import 'package:home_service_app/features/chat/presentation/cubit/chat_thread_state.dart';

class ChatThreadCubit extends Cubit<ChatThreadState> {
  ChatThreadCubit(this._repo, {required this.conversationId})
      : super(const ChatThreadState());

  final ChatRepository _repo;
  final int conversationId;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.get(conversationId);
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (c) => emit(state.copyWith(loading: false, conversation: c)),
    );
  }

  Future<void> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || state.sending) return;
    emit(state.copyWith(sending: true, clearMessage: true));
    final result = await _repo.send(conversationId, text);
    result.fold(
      (f) => emit(state.copyWith(sending: false, message: f.message)),
      (msg) {
        final current = state.conversation;
        if (current == null) {
          emit(state.copyWith(sending: false));
          load();
          return;
        }
        emit(state.copyWith(
          sending: false,
          conversation: current.copyWith(
            lastMessage: msg,
            lastMessageAt: msg.createdAt,
            messages: [...current.messages, msg],
          ),
        ));
      },
    );
  }

  Future<void> sendOffer({
    required DateTime scheduledAt,
    required double priceAzn,
    double? durationHours,
    String? note,
  }) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearMessage: true));
    final result = await _repo.sendOffer(
      conversationId: conversationId,
      scheduledAt: scheduledAt,
      priceAzn: priceAzn,
      durationHours: durationHours,
      note: note,
    );
    result.fold(
      (f) => emit(state.copyWith(sending: false, message: f.message)),
      (c) => emit(state.copyWith(sending: false, conversation: c)),
    );
  }

  Future<void> offerAction(int offerId, String action) async {
    if (state.sending) return;
    emit(state.copyWith(sending: true, clearMessage: true));
    final result = await _repo.offerAction(offerId, action);
    result.fold(
      (f) => emit(state.copyWith(sending: false, message: f.message)),
      (c) => emit(state.copyWith(sending: false, conversation: c)),
    );
  }

  Future<bool> submitReview({
    required int offerId,
    required int rating,
    String? comment,
  }) async {
    if (state.sending) return false;
    emit(state.copyWith(sending: true, clearMessage: true));
    final result = await _repo.submitReview(
      offerId: offerId,
      rating: rating,
      comment: comment,
    );
    return result.fold(
      (f) {
        emit(state.copyWith(sending: false, message: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(sending: false));
        load();
        return true;
      },
    );
  }

  Future<bool> blockUser(int userId) async {
    if (state.sending) return false;
    emit(state.copyWith(sending: true, clearMessage: true));
    final result = await _repo.blockUser(userId);
    return result.fold(
      (f) {
        emit(state.copyWith(sending: false, message: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(sending: false));
        return true;
      },
    );
  }

  Future<bool> reportUser({
    required int reportedUserId,
    required String reason,
    String? details,
    int? conversationId,
  }) async {
    if (state.sending) return false;
    emit(state.copyWith(sending: true, clearMessage: true));
    final result = await _repo.reportUser(
      reportedUserId: reportedUserId,
      reason: reason,
      details: details,
      conversationId: conversationId,
    );
    return result.fold(
      (f) {
        emit(state.copyWith(sending: false, message: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(sending: false));
        return true;
      },
    );
  }
}
