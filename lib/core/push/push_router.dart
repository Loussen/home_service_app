import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_service_app/app/config/router.dart';
import 'package:home_service_app/core/push/local_push.dart';
import 'package:home_service_app/features/chat/chat_inbox_signal.dart';
import 'package:home_service_app/features/jobs/jobs_inbox_signal.dart';

/// Central deep-link routing for FCM + local notification taps.
class PushRouter {
  PushRouter._();

  static DateTime? _lastOpenAt;
  static const _channel = MethodChannel('mysancho/badge');

  static Future<void> clearBadge() async {
    if (kIsWeb) return;
    try {
      await LocalPush.cancelAll();
    } catch (_) {}
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod<void>('clear');
      } catch (_) {}
    }
  }

  /// Opens the right screen from push / inbox payload.
  ///
  /// Chat uses `go(/chat)` then `push(/chat/:id)` so the thread has a back stack.
  static void open(Map<String, String> data) {
    final now = DateTime.now();
    if (_lastOpenAt != null &&
        now.difference(_lastOpenAt!) < const Duration(milliseconds: 700)) {
      return;
    }
    _lastOpenAt = now;

    unawaited(clearBadge());

    final type = (data['type'] ?? '').trim();
    final conversationId = (data['conversation_id'] ?? '').trim();

    if (type == 'chat_message' || type == 'chat_connect') {
      ChatInboxSignal.ping();
      _openChat(conversationId);
      return;
    }
    if (type == 'new_job' || type == 'urgent_job') {
      final matchId = int.tryParse((data['match_id'] ?? '').trim());
      final requestId = int.tryParse((data['request_id'] ?? '').trim());
      JobsInboxSignal.ping(matchId: matchId, requestId: requestId);
      appRouter.go('/search');
      return;
    }
    if (type == 'admin') {
      appRouter.go('/account');
      return;
    }
    // Unknown / generic → inbox
    appRouter.go('/account');
    _afterShell(() => appRouter.push('/notifications'));
  }

  static void openFromDynamic(Map<String, dynamic> raw) {
    open({
      for (final e in raw.entries) e.key.toString(): e.value.toString(),
    });
  }

  static void _openChat(String conversationId) {
    appRouter.go('/chat');
    if (conversationId.isEmpty) return;
    _afterShell(() => appRouter.push('/chat/$conversationId'));
  }

  static void _afterShell(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 80), action);
    });
  }
}
