import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';

/// Provider registered but waiting for admin approval.
class ProviderPendingPage extends StatelessWidget {
  const ProviderPendingPage({super.key});

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
                      context.go('/account');
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final rejected = user?.isProviderRejected == true;
    final message = user?.providerApprovalMessage ??
        (rejected
            ? t('provider.approval.rejected')
            : t('provider.approval.pending'));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Sancho',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Fraunces',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 28),
              Icon(
                rejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                size: 48,
                color: rejected ? AppColors.primary : AppColors.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                rejected
                    ? t('provider.approval.rejected_title')
                    : t('provider.approval.pending_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
              ),
              if (user?.providerRejectionNote?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    user!.providerRejectionNote!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              const Spacer(),
              if (rejected) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: user == null
                        ? null
                        : () => _showRejectionSheet(context, user),
                    child: Text(t('provider.approval.view_reason')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/account'),
                    child: Text(t('provider.approval.complete_profile')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
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
                    ),
                    child: Text(t('provider.approval.resubmit')),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/account'),
                    child: Text(t('provider.approval.complete_profile')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await context.read<AuthCubit>().bootstrap();
                      if (!context.mounted) return;
                      final user = context.read<AuthCubit>().state.user;
                      if (user != null &&
                          !user.isProviderPending &&
                          !user.isProviderRejected) {
                        context.go('/search');
                      }
                    },
                    child: Text(t('provider.approval.refresh')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
