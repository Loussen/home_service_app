import 'dart:async';

class JobsOpenTarget {
  const JobsOpenTarget({this.matchId, this.requestId});

  final int? matchId;
  final int? requestId;

  bool get hasTarget =>
      (matchId != null && matchId! > 0) ||
      (requestId != null && requestId! > 0);
}

/// Refresh + optional deep-link open for provider Jobs list.
class JobsInboxSignal {
  JobsInboxSignal._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();
  static JobsOpenTarget? _pending;

  static Stream<void> get stream => _controller.stream;

  static void ping({int? matchId, int? requestId}) {
    if ((matchId != null && matchId > 0) ||
        (requestId != null && requestId > 0)) {
      _pending = JobsOpenTarget(matchId: matchId, requestId: requestId);
    }
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  static JobsOpenTarget? peekPending() => _pending;

  static void clearPending() {
    _pending = null;
  }

  static JobsOpenTarget? takePending() {
    final next = _pending;
    _pending = null;
    return next;
  }
}
