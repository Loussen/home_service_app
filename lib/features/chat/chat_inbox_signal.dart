import 'dart:async';

/// Lightweight signal so chat list can refresh when a chat push arrives
/// while the app is open (or after returning from background).
class ChatInboxSignal {
  ChatInboxSignal._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void ping() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
