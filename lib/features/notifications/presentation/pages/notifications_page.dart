import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/push/push_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/notifications/data/notifications_remote_data_source.dart';
import 'package:home_service_app/features/notifications/domain/notifications_repository.dart';
import 'package:intl/intl.dart';

enum _NotifFilter { all, unread, read }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NotifFilter _filter = _NotifFilter.all;
  late Future<dynamic> _future;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String get _statusParam => switch (_filter) {
        _NotifFilter.unread => 'unread',
        _NotifFilter.read => 'read',
        _NotifFilter.all => 'all',
      };

  void _reload() {
    _future = getIt<NotificationsRepository>().list(status: _statusParam);
  }

  Future<void> _setFilter(_NotifFilter next) async {
    if (_filter == next) return;
    setState(() {
      _filter = next;
      _reload();
    });
  }

  Future<void> _open(AppNotificationModel item) async {
    if (!item.isRead) {
      await getIt<NotificationsRepository>().markRead(item.id);
    }
    if (!mounted) return;

    final data = <String, String>{
      'type': item.type,
      ...item.payload,
    };
    if (data['type'] == 'chat_message' ||
        data['type'] == 'chat_connect' ||
        data['type'] == 'new_job' ||
        data['type'] == 'urgent_job' ||
        data['type'] == 'admin') {
      PushRouter.open(data);
      return;
    }
    setState(_reload);
  }

  Future<void> _markAll() async {
    setState(() => _markingAll = true);
    final result = await getIt<NotificationsRepository>().markAllRead();
    if (!mounted) return;
    setState(() {
      _markingAll = false;
      _reload();
    });
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('notifications.marked_all'))),
      ),
    );
  }

  String _formatWhen(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('d MMM, HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(t('notifications.title')),
        actions: [
          TextButton(
            onPressed: _markingAll ? null : _markAll,
            child: Text(
              t('notifications.mark_all'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: t('notifications.filter.all'),
                  selected: _filter == _NotifFilter.all,
                  onTap: () => _setFilter(_NotifFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: t('notifications.filter.unread'),
                  selected: _filter == _NotifFilter.unread,
                  onTap: () => _setFilter(_NotifFilter.unread),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: t('notifications.filter.read'),
                  selected: _filter == _NotifFilter.read,
                  onTap: () => _setFilter(_NotifFilter.read),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(child: Text(t('notifications.load_error')));
                }
                return snapshot.data!.fold(
                  (f) => Center(child: Text(f.message)),
                  (data) {
                    final items = data.items;
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            t('notifications.empty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(_reload);
                        await _future;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _NotificationTile(
                            item: item,
                            when: _formatWhen(item.createdAt),
                            onTap: () => _open(item),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.when,
    required this.onTap,
  });

  final AppNotificationModel item;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return Material(
      color: unread ? AppColors.peachRow : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unread ? AppColors.secondary : AppColors.divider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isNotEmpty
                                ? item.title
                                : t('notifications.fallback_title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (when.isNotEmpty)
                          Text(
                            when,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread ? AppColors.ink : AppColors.muted,
                        height: 1.35,
                        fontSize: 13.5,
                        fontWeight:
                            unread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unread
                          ? t('notifications.status.unread')
                          : t('notifications.status.read'),
                      style: TextStyle(
                        color: unread ? AppColors.primary : AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
