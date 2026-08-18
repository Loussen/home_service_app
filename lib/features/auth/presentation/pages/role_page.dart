import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/widgets/auth_chrome.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  Future<void> _pick(BuildContext context, String role) async {
    await context.read<AuthCubit>().setRole(role);
    if (!context.mounted) return;
    final user = context.read<AuthCubit>().state.user;
    if (role == 'provider' && (user?.needsProviderOnboarding ?? true)) {
      context.go('/onboarding');
      return;
    }
    context.go('/search');
  }

  @override
  Widget build(BuildContext context) {
    return AuthChrome(
      subtitle: t('role.subtitle'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          Text(
            t('role.title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            t('role.hint'),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          AuthRoleCard(
            icon: Icons.home_outlined,
            color: AppColors.skySoft,
            title: t('role.client.title'),
            subtitle: t('role.client.subtitle'),
            onTap: () => _pick(context, 'client'),
          ),
          const SizedBox(height: 12),
          AuthRoleCard(
            icon: Icons.work_outline,
            color: AppColors.cream,
            title: t('role.provider.title'),
            subtitle: t('role.provider.subtitle'),
            onTap: () => _pick(context, 'provider'),
          ),
        ],
      ),
    );
  }
}
