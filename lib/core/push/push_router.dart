import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_service_app/app/config/router.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/push/local_push.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/chat/chat_inbox_signal.dart';
import 'package:home_service_app/features/jobs/jobs_inbox_signal.dart';

/// Central deep-link routing for FCM + local notification taps.
class PushRouter {
  PushRouter._();

  static DateTime? _lastOpenAt;
  static const _channel = MethodChannel('mysancho/badge');

  static Future<void> clearBadge() async {
    await setBadge(0);
  }

  /// Sync iOS launcher badge to [count] (usually chat unread).
  static Future<void> setBadge(int count) async {
    if (kIsWeb) return;
    final n = count < 0 ? 0 : count;
    if (n == 0) {
      try {
        await LocalPush.cancelAll();
      } catch (_) {}
    }
    if (Platform.isIOS) {
      try {
        if (n == 0) {
          await _channel.invokeMethod<void>('clear');
        } else {
          await _channel.invokeMethod<void>('set', n);
        }
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

    final type = (data['type'] ?? '').trim();
    final conversationId = (data['conversation_id'] ?? '').trim();

    if (type == 'chat_message' || type == 'chat_connect') {
      ChatInboxSignal.ping();
      final audience = (data['audience_role'] ?? '').trim();
      unawaited(_openChatForAudience(conversationId, audience));
      return;
    }
    if (type == 'new_job' ||
        type == 'urgent_job' ||
        type == 'missed_opportunity') {
      final matchId = int.tryParse((data['match_id'] ?? '').trim());
      final requestId = int.tryParse((data['request_id'] ?? '').trim());
      JobsInboxSignal.ping(matchId: matchId, requestId: requestId);
      // Jobs tab (provider) — expired/missed jobs still open for history.
      unawaited(_openAsRole('provider', '/search'));
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

  /// Switch to [role] when the user has it enabled, then go [path].
  static Future<void> _openAsRole(String role, String path) async {
    try {
      final auth = getIt<AuthCubit>();
      final user = auth.state.user;
      final hasRole = role == 'provider'
          ? user?.hasProviderRole == true
          : user?.hasClientRole == true;
      if (user != null && hasRole && user.activeRole != role) {
        await auth.switchOrEnableRole(role);
      }
    } catch (_) {}
    appRouter.go(path);
  }

  static Future<void> _openChatForAudience(
    String conversationId,
    String audience,
  ) async {
    final role = audience == 'provider' || audience == 'client'
        ? audience
        : null;
    if (role != null) {
      await _openAsRole(role, '/chat');
    } else {
      appRouter.go('/chat');
    }
    if (conversationId.isEmpty) return;
    _afterShell(() => appRouter.push('/chat/$conversationId'));
  }

  static void _afterShell(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 80), action);
    });
  }
}
