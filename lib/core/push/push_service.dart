import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:home_service_app/app/config/router.dart';
import 'package:home_service_app/core/push/device_token_remote.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here — opening the app is handled in PushService.
}

class PushService {
  PushService(this._remote);

  final DeviceTokenRemote _remote;

  bool _ready = false;
  bool _listening = false;
  String? _token;

  Future<void> register() async {
    if (kIsWeb) return;
    if (!await _ensureFirebase()) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _listenOnce();

    try {
      _token = await messaging.getToken();
    } catch (e) {
      debugPrint('[push] getToken failed: $e');
      return;
    }

    if (_token == null || _token!.isEmpty) {
      debugPrint('[push] no FCM token yet (add google-services.json / GoogleService-Info.plist)');
      return;
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _remote.register(token: _token!, platform: platform);
      debugPrint('[push] token registered');
    } catch (e) {
      debugPrint('[push] register API failed: $e');
    }
  }

  Future<void> unregister() async {
    final token = _token;
    _token = null;
    if (token == null || token.isEmpty) return;
    await _remote.unregister(token);
  }

  Future<bool> _ensureFirebase() async {
    if (_ready) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _ready = true;
      return true;
    } catch (e) {
      debugPrint('[push] Firebase not configured: $e');
      return false;
    }
  }

  void _listenOnce() {
    if (_listening) return;
    _listening = true;

    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _openFromMessage(msg);
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _token = token;
      final platform = Platform.isIOS ? 'ios' : 'android';
      try {
        await _remote.register(token: token, platform: platform);
      } catch (_) {}
    });
  }

  void _openFromMessage(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'new_job' || type == 'urgent_job') {
      appRouter.go('/search');
    }
  }
}
