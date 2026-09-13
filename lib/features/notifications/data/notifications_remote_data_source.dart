import 'package:home_service_app/core/network/api_client.dart';

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.payload = const {},
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, String> payload;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  AppNotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      payload: payload,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final payloadRaw = json['payload'];
    final payload = <String, String>{};
    if (payloadRaw is Map) {
      payloadRaw.forEach((key, value) {
        payload['$key'] = '$value';
      });
    }
    return AppNotificationModel(
      id: '${json['id']}',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'admin',
      payload: payload,
      isRead: json['is_read'] == true,
      readAt: json['read_at'] != null
          ? DateTime.tryParse('${json['read_at']}')
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse('${json['created_at']}')
          : null,
    );
  }
}

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<({List<AppNotificationModel> items, int unreadCount})> list({
    String status = 'all',
  }) async {
    final res = await _client.dio.get(
      '/notifications',
      queryParameters: {'status': status},
    );
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    final raw = data['items'] as List<dynamic>? ?? [];
    return (
      items: raw
          .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> unreadCount() async {
    final res = await _client.dio.get('/notifications/unread-count');
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<AppNotificationModel> markRead(String id) async {
    final res = await _client.dio.post('/notifications/$id/read');
    return AppNotificationModel.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> markAllRead() async {
    await _client.dio.post('/notifications/read-all');
  }
}
