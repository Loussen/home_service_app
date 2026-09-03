import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';

/// Provider registered but waiting for admin approval.
class ProviderPendingPage extends StatelessWidget {
  const ProviderPendingPage({super.key});

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
                'MySancho',
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
                Text(
                  user!.providerRejectionNote!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const Spacer(),
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
          ),
        ),
      ),
    );
  }
}
