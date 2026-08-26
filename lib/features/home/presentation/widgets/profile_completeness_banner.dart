import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCompletenessBanner extends StatefulWidget {
  const ProfileCompletenessBanner({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 4),
  });

  final EdgeInsetsGeometry padding;

  @override
  State<ProfileCompletenessBanner> createState() =>
      _ProfileCompletenessBannerState();
}

class _ProfileCompletenessBannerState extends State<ProfileCompletenessBanner> {
  bool _hidden = false;
  int? _loadedFor;

  String _dismissKey(int userId, int percent) =>
      'completeness_banner_v1_${userId}_$percent';

  Future<void> _loadDismissed(UserModel user) async {
    final token = Object.hash(user.id, user.effectiveCompleteness.percent);
    if (_loadedFor == token) return;
    _loadedFor = token;
    if (_hidden) {
      _hidden = false;
    }
    final prefs = await SharedPreferences.getInstance();
    final hidden =
        prefs.getBool(_dismissKey(user.id, user.effectiveCompleteness.percent)) ??
            false;
    if (mounted && hidden != _hidden) {
      setState(() => _hidden = hidden);
    }
  }

  Future<void> _dismiss(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _dismissKey(user.id, user.effectiveCompleteness.percent),
      true,
    );
    if (mounted) setState(() => _hidden = true);
  }

  void _open(BuildContext context, ProfileCompleteness completeness) {
    if (completeness.profileId != null) {
      context.push('/profiles/${completeness.profileId}');
      return;
    }
    context.push('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (user == null || !user.showCompletenessBanner) {
      return const SizedBox.shrink();
    }
    _loadDismissed(user);
    if (_hidden) return const SizedBox.shrink();

    final c = user.effectiveCompleteness;
    final missingLabels =
        c.missing.map((k) => t('onboarding.missing.$k')).toList();

    return Padding(
      padding: widget.padding,
      child: Material(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(context, c),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.assignment_late_outlined,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('onboarding.banner.title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('onboarding.banner.subtitle', params: {
                          'percent': '${c.percent}',
                        }),
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                      if (missingLabels.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final label in missingLabels)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        c.profileId == null
                            ? t('onboarding.banner.cta_create')
                            : t('onboarding.banner.cta'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: t('onboarding.banner.dismiss'),
                  onPressed: () => _dismiss(user),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
