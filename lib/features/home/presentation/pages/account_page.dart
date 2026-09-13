import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_locale_service.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/remote/change_app_locale.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/home/presentation/widgets/profile_completeness_banner.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:home_service_app/features/auth/presentation/widgets/logout_confirm.dart';
import 'package:image_picker/image_picker.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _showRejectionSheet(BuildContext context, UserModel user) async {
    final note = (user.providerRejectionNote?.trim().isNotEmpty == true)
        ? user.providerRejectionNote!
        : t('provider.approval.rejected');

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('provider.approval.rejected_title'),
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('provider.approval.reject_reason_label'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(note, style: const TextStyle(height: 1.4)),
                ),
                const SizedBox(height: 12),
                Text(
                  t('provider.approval.resubmit_hint'),
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/profiles/new');
                    },
                    child: Text(t('provider.approval.complete_profile')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await context
                          .read<AuthCubit>()
                          .resubmitProviderReview();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? t('provider.approval.resubmit_done')
                                : (context.read<AuthCubit>().state.message ??
                                    t('error.generic')),
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(t('provider.approval.resubmit')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final service = getIt<AppLocaleService>();
    final codes = AppRemoteConfig.instance.supportedLocales.isNotEmpty
        ? AppRemoteConfig.instance.supportedLocales
        : service.supportedLocales;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t('account.menu.language'),
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
              ),
              for (final code in codes)
                ListTile(
                  title: Text(
                    AppRemoteConfig.instance.localeLabels[code] ??
                        service.labelFor(code),
                  ),
                  trailing: service.locale == code
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (service.locale != code) {
                      await changeAppLocale(code);
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;

    final ok = await context.read<AuthCubit>().uploadAvatar(file.path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? t('account.photo_updated')
              : (context.read<AuthCubit>().state.message ??
                  t('error.generic')),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final name = (user?.name?.isNotEmpty == true)
            ? user!.name!
            : t('account.user_fallback');
        final role = user?.activeRole == 'provider'
            ? t('account.role.provider')
            : t('account.role.client');
        final initials = name.isNotEmpty
            ? name.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
            : 'U';
        final pending = user?.isProviderPending == true;
        final rejected = user?.isProviderRejected == true;
        final approved = user?.isProvider == true &&
            user?.providerApprovalStatus == 'approved';
        final showApproval = pending || rejected || approved;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'My Sancho',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  if (showApproval) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: rejected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : approved
                                ? AppColors.sageSoft
                                : AppColors.mist,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        user?.providerApprovalMessage ??
                            (rejected
                                ? t('provider.approval.rejected')
                                : approved
                                    ? t('provider.approval.approved')
                                    : t('provider.approval.pending')),
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.peach,
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl != null
                              ? null
                              : Text(
                                  initials,
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
                              Text(name,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text(role,
                                  style: const TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _uploadAvatar(context),
                                child: Text(
                                  t('account.upload_photo'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _uploadAvatar(context),
                          borderRadius: BorderRadius.circular(20),
                          child: _RoundIcon(
                            icon: Icons.photo_camera_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            await context.push('/notifications');
                            if (context.mounted) {
                              await context.read<AuthCubit>().bootstrap();
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: _RoundIcon(
                            icon: Icons.notifications_outlined,
                            color: AppColors.gold,
                            badgeCount: user?.unreadNotificationsCount ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ProfileCompletenessBanner(
                    padding: EdgeInsets.only(top: 4, bottom: 12),
                  ),
                  SizedBox(
                    height: 128,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (user?.isProvider == true) ...[
                          _PastelCard(
                            color: AppColors.skySoft,
                            icon: Icons.mic_none,
                            title: t('account.card.audio_intro'),
                            onTap: () => context.go('/profiles'),
                          ),
                          _PastelCard(
                            color: AppColors.lavender,
                            icon: Icons.account_balance_wallet_outlined,
                            title: t('account.card.wallet_bump'),
                            onTap: () => context.push('/wallet'),
                          ),
                          _PastelCard(
                            color: AppColors.sageSoft,
                            icon: Icons.verified_outlined,
                            title: t('account.card.verify'),
                            onTap: () => context.push('/verification'),
                          ),
                        ] else ...[
                          _PastelCard(
                            color: AppColors.skySoft,
                            icon: Icons.mic_none,
                            title: t('account.card.voice_search'),
                            onTap: () => context.go('/search'),
                          ),
                          _PastelCard(
                            color: AppColors.cream,
                            icon: Icons.assignment_outlined,
                            title: t('account.card.requests'),
                            onTap: () => context.go('/search'),
                          ),
                          _PastelCard(
                            color: AppColors.lavender,
                            icon: Icons.chat_bubble_outline,
                            title: t('account.card.chats'),
                            onTap: () => context.go('/chat'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        if (user?.isProvider == true)
                          _MenuTile(
                            icon: Icons.shield_outlined,
                            label: t('account.menu.profile_status'),
                            trailing: Text(
                              user!.displayProfileStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: user.isBlocked ||
                                        user.profileStatus == 'blocked' ||
                                        user.isProviderRejected
                                    ? AppColors.primary
                                    : user.providerApprovalStatus == 'approved'
                                        ? AppColors.published
                                        : AppColors.secondary,
                              ),
                            ),
                            onTap: user.isProviderRejected
                                ? () => _showRejectionSheet(context, user)
                                : () {},
                          ),
                        _MenuTile(
                          icon: Icons.calendar_month_outlined,
                          label: t('account.menu.bookings'),
                          onTap: () => context.push('/bookings'),
                        ),
                        _MenuTile(
                          icon: Icons.account_balance_wallet_outlined,
                          label: t('account.menu.wallet', params: {
                            'balance':
                                user?.balance.toStringAsFixed(2) ?? '0',
                          }),
                          onTap: () => context.push('/wallet'),
                        ),
                        if (user?.isProvider == true)
                          _MenuTile(
                            icon: Icons.verified_outlined,
                            label: t('account.menu.verify'),
                            onTap: () => context.push('/verification'),
                          ),
                        _MenuTile(
                          icon: Icons.star_outline,
                          label: t('account.menu.reviews'),
                          onTap: () => context.push('/reviews'),
                        ),
                        _MenuTile(
                          icon: Icons.block,
                          label: t('account.menu.blocked'),
                          onTap: () => context.push('/blocked'),
                        ),
                        if (user?.isClient == true)
                          _MenuTile(
                            icon: Icons.bookmark_border,
                            label: t('account.menu.favorites'),
                            onTap: () => context.push('/favorites'),
                          ),
                        _MenuTile(
                          icon: Icons.language,
                          label: t('account.menu.language'),
                          trailing: Text(
                            getIt<AppLocaleService>().labelFor(
                              getIt<AppLocaleService>().locale,
                            ),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          onTap: () => _pickLanguage(context),
                        ),
                        _MenuTile(
                          icon: Icons.menu_book_outlined,
                          label: t('account.menu.how_it_works'),
                          onTap: () => context.push('/welcome?replay=1'),
                        ),
                        if (AppRemoteConfig
                            .instance.staticPages.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t('account.menu.info'),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          ...AppRemoteConfig.instance.staticPages.map(
                            (page) => _MenuTile(
                              icon: Icons.article_outlined,
                              label: page.title,
                              onTap: () => context.push(
                                '/page/${page.slug}',
                                extra: page.title,
                              ),
                            ),
                          ),
                        ],
                        _MenuTile(
                          icon: Icons.logout,
                          label: t('account.menu.logout'),
                          onTap: () async {
                            if (!await confirmLogout(context)) return;
                            if (!context.mounted) return;
                            await context.read<AuthCubit>().logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.color,
    this.badgeCount = 0,
  });
  final IconData icon;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PastelCard extends StatelessWidget {
  const _PastelCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.ink),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(label),
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppColors.muted),
      onTap: onTap,
    );
  }
}
