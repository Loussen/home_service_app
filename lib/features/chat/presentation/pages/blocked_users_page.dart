import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/app/widgets/app_confirm_dialog.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = getIt<ChatRepository>().listBlockedUsers();
  }

  Future<void> _unblock(BlockedUserModel user) async {
    final ok = await showAppConfirm(
      context,
      title: t('block.unblock_title'),
      message: t('block.unblock_confirm', params: {'name': user.displayName}),
      confirmLabel: t('block.unblock_action'),
      cancelLabel: t('block.cancel'),
    );
    if (ok != true || !mounted) return;

    final result = await getIt<ChatRepository>().unblockUser(user.id);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('block.unblocked'))),
        );
        setState(_reload);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('block.list_title'))),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text(t('block.load_error')));
          }
          return snapshot.data!.fold(
            (f) => Center(child: Text(f.message)),
            (List<BlockedUserModel> users) {
              if (users.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      t('block.empty'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _BlockedTile(
                    user: user,
                    onUnblock: () => _unblock(user),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.user, required this.onUnblock});

  final BlockedUserModel user;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.role == 'provider'
        ? t('account.role.provider')
        : (user.role == 'client' ? t('account.role.client') : null);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onUnblock,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.mist,
                backgroundImage: user.avatarUrl != null &&
                        user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (roleLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: onUnblock,
                child: Text(
                  t('block.unblock_action'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
