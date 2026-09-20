import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef LocalPushTap = void Function(Map<String, String> data);

/// Android heads-up: Sancho silhouette smallIcon + color largeIcon when available.
class LocalPush {
  LocalPush._();

  static const channelId = 'mysancho_high';
  static const channelName = 'My Sancho bildirişlər';
  static const _brandNavy = Color(0xFF08215B);
  static const _logoAsset = 'assets/brand/notification_logo.png';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;
  static Uint8List? _logoBytes;
  static LocalPushTap? _onTap;
  static Map<String, String>? _pendingLaunchData;

  static Future<void> ensureInitialized({LocalPushTap? onTap}) async {
    if (kIsWeb) return;
    if (onTap != null) {
      _onTap = onTap;
    }

    if (!Platform.isAndroid) {
      _ready = true;
      return;
    }

    if (_ready) {
      // Re-bind tap if caller provided one after background isolate init.
      return;
    }

    const androidInit =
        AndroidInitializationSettings('@drawable/ic_stat_mysancho');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Yeni iş və mesaj bildirişləri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    try {
      _logoBytes ??=
          (await rootBundle.load(_logoAsset)).buffer.asUint8List();
    } catch (_) {}

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _pendingLaunchData = _decodePayload(launch?.notificationResponse?.payload);
    }

    _ready = true;
  }

  static Map<String, String>? takePendingLaunchData() {
    final data = _pendingLaunchData;
    _pendingLaunchData = null;
    return data;
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  static Future<void> showFromRemote(RemoteMessage message) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await ensureInitialized();

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'My Sancho';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';
    if (title.isEmpty && body.isEmpty) return;

    final id = message.messageId?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    var logo = _logoBytes;
    if (logo == null) {
      try {
        logo = (await rootBundle.load(_logoAsset)).buffer.asUint8List();
        _logoBytes = logo;
      } catch (_) {}
    }

    final data = <String, String>{
      for (final e in message.data.entries) e.key: '${e.value}',
    };

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Yeni iş və mesaj bildirişləri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_stat_mysancho',
          largeIcon: logo != null ? ByteArrayAndroidBitmap(logo) : null,
          color: _brandNavy,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final data = _decodePayload(response.payload);
    if (data == null || data.isEmpty) return;
    final tap = _onTap;
    if (tap != null) {
      tap(data);
    } else {
      _pendingLaunchData = data;
    }
  }

  static Map<String, String>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      return {
        for (final e in decoded.entries) '${e.key}': '${e.value}',
      };
    } catch (_) {
      return null;
    }
  }
}
