import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/chat/chat_unread_badge.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';
import 'package:home_service_app/features/chat/presentation/cubit/chat_list_state.dart';

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit(this._repo, this._unreadBadge) : super(const ChatListState());

  final ChatRepository _repo;
  final ChatUnreadBadge _unreadBadge;
  Timer? _poll;
  bool _refreshing = false;

  static const _pollInterval = Duration(seconds: 8);

  void _syncBadgeFromItems() {
    final total = state.items.fold<int>(0, (sum, c) => sum + c.unreadCount);
    _unreadBadge.setCount(total);
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.list();
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (items) {
        emit(state.copyWith(loading: false, items: items));
        _syncBadgeFromItems();
      },
    );
  }

  /// Silent refresh — keeps existing list on error (used by polling / resume).
  Future<void> refreshQuiet() async {
    if (_refreshing || state.loading || isClosed) return;
    _refreshing = true;
    try {
      final result = await _repo.list();
      if (isClosed) return;
      result.fold(
        (_) {},
        (items) {
          emit(state.copyWith(items: items, clearMessage: true));
          _syncBadgeFromItems();
        },
      );
    } finally {
      _refreshing = false;
    }
  }

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) {
      unawaited(refreshQuiet());
    });
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
