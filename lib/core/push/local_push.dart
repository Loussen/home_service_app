import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  static Future<void> ensureInitialized() async {
    if (kIsWeb || _ready) return;
    if (!Platform.isAndroid) {
      _ready = true;
      return;
    }

    const androidInit =
        AndroidInitializationSettings('@drawable/ic_stat_mysancho');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
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
    _ready = true;
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
      payload: jsonEncode(message.data),
    );
  }
}
