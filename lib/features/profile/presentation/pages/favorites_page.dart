import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/app/widgets/app_confirm_dialog.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = getIt<ProfileRepository>().listFavorites();
  }

  String _displayName(ProviderProfileModel p) {
    final name = p.userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (p.title?.isNotEmpty == true) return p.title!;
    if (p.categoryLabels.isNotEmpty) return p.categoryLabels.first;
    return t('match.provider_fallback');
  }

  Future<void> _remove(ProviderProfileModel profile) async {
    final name = _displayName(profile);
    final ok = await showAppConfirm(
      context,
      title: t('favorites.title'),
      message: t('favorites.remove_confirm', params: {'name': name}),
      confirmLabel: t('favorites.remove_action'),
      cancelLabel: t('common.cancel'),
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final result = await getIt<ProfileRepository>().removeFavorite(profile.id);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('favorites.removed'))),
        );
        setState(_reload);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('favorites.title'))),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text(t('favorites.load_error')));
          }
          return snapshot.data!.fold(
            (f) => Center(child: Text(f.message)),
            (List<ProviderProfileModel> profiles) {
              if (profiles.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      t('favorites.empty'),
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
                itemCount: profiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return _FavoriteTile(
                    profile: profile,
                    title: _displayName(profile),
                    onOpen: () => context.push('/providers/${profile.id}'),
                    onRemove: () => _remove(profile),
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

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.profile,
    required this.title,
    required this.onOpen,
    required this.onRemove,
  });

  final ProviderProfileModel profile;
  final String title;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (profile.title?.isNotEmpty == true && profile.title != title)
        profile.title!,
      ...profile.categoryLabels.take(2),
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
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
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                onPressed: onRemove,
                child: Text(
                  t('favorites.remove_action'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC44536),
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
