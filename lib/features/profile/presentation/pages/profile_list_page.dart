import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_list_cubit.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_list_state.dart';

class ProfileListPage extends StatelessWidget {
  const ProfileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileListCubit>()..load(),
      child: Builder(
        builder: (context) => Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  t('profiles.title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.sky,
                      ),
                ),
              ),
              Expanded(
                child: BlocConsumer<ProfileListCubit, ProfileListState>(
                  listener: (context, state) {
                    if (state.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message!)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.profiles.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            t('profiles.empty'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<ProfileListCubit>().load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: state.profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _ProfileCard(profile: state.profiles[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await context.push('/profiles/new');
            if (context.mounted) {
              context.read<ProfileListCubit>().load();
            }
          },
          child: const Icon(Icons.add),
        ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final ProviderProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final title = profile.title?.isNotEmpty == true
        ? profile.title!
        : (profile.categoryLabels.isNotEmpty
            ? profile.categoryLabels.first
            : t('profiles.fallback_name'));
    final published = profile.isActive;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.peach,
                child: Text(
                  (profile.categoryLabels.isNotEmpty
                          ? profile.categoryLabels.first
                          : 'P')
                      .substring(0, 1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: published ? AppColors.published : AppColors.statusNew,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  published ? t('profiles.status.published') : t('profiles.status.new'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (profile.categoryLabels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.categoryLabels
                    .map(
                      (n) => Chip(
                        label: Text(n),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primary,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ),
          Row(
            children: [
              _ActionCircle(
                icon: Icons.arrow_upward,
                color: AppColors.statusNew,
                onTap: () async {
                  final cubit = context.read<ProfileListCubit>();
                  final balance = await cubit.bump(profile.id);
                  if (balance != null && context.mounted) {
                    context.read<AuthCubit>().bootstrap();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t('profiles.bump_success', params: {
                            'balance': balance.toStringAsFixed(2),
                          }),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionCircle(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                onTap: () async {
                  await context.push('/profiles/${profile.id}');
                  if (context.mounted) {
                    context.read<ProfileListCubit>().load();
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionCircle(
                icon: Icons.delete_outline,
                color: AppColors.muted,
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(t('profiles.delete_title')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(t('profiles.delete_no')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(t('profiles.delete_yes')),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<ProfileListCubit>().delete(profile.id);
                  }
                },
              ),
              const SizedBox(width: 8),
              _ActionCircle(
                icon: Icons.visibility_outlined,
                color: AppColors.sky,
                onTap: () => context.push('/profiles/${profile.id}'),
              ),
            ],
          ),
          if (profile.isVerified || profile.isVip) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (profile.isVerified) t('profiles.badge.verified'),
                if (profile.isVip) t('profiles.badge.vip'),
                profile.district,
              ].whereType<String>().join(' · '),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: color,
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
