import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_service_app/features/chat/chat_inbox_signal.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';

/// Total unread chat messages for bottom-nav badge.
class ChatUnreadBadge extends ChangeNotifier {
  ChatUnreadBadge(this._repo) {
    _sub = ChatInboxSignal.stream.listen((_) {
      unawaited(refresh());
    });
  }

  final ChatRepository _repo;
  StreamSubscription<void>? _sub;
  Timer? _poll;
  int _count = 0;
  bool _busy = false;

  int get count => _count;

  void setCount(int value) {
    final next = value < 0 ? 0 : value;
    if (next == _count) return;
    _count = next;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await _repo.unreadCount();
      result.fold((_) {}, setCount);
    } finally {
      _busy = false;
    }
  }

  void startPolling() {
    _poll?.cancel();
    unawaited(refresh());
    _poll = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(refresh());
    });
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void dispose() {
    stopPolling();
    _sub?.cancel();
    super.dispose();
  }
}
