import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/widgets/ms_widgets.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const MsBrandTitle(fontSize: 22),
        actions: [
          IconButton(
            onPressed: () => context.push('/wallet'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          IconButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.user;
          final isProvider = user?.activeRole == 'provider';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                user?.name?.isNotEmpty == true
                    ? 'Salam, ${user!.name}'
                    : 'Salam',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Rol: ${user?.activeRole ?? '-'} · Balans: ${user?.balance.toStringAsFixed(2) ?? '0'} AZN',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              if (isProvider)
                MsCard(
                  onTap: () => context.push('/profiles'),
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.work_outline, color: AppColors.primary),
                    title: Text('Xidmət profilləri'),
                    subtitle: Text('Cədvəl, audio intro, multi-profil'),
                    trailing: Icon(Icons.chevron_right, color: AppColors.muted),
                  ),
                )
              else
                MsCard(
                  onTap: () => context.push('/search'),
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.mic, color: AppColors.primary),
                    title: Text('AI səsli sorğu'),
                    subtitle: Text('Danışın — match + xəritə'),
                    trailing: Icon(Icons.chevron_right, color: AppColors.muted),
                  ),
                ),
              const SizedBox(height: 12),
              MsCard(
                onTap: () => context.push('/search'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.map_outlined, color: AppColors.secondary),
                  title: Text('Xəritədə axtar'),
                  subtitle: Text('Eyni AI match axını'),
                  trailing: Icon(Icons.chevron_right, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 12),
              MsCard(
                onTap: () => context.push('/role'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline, color: AppColors.secondary),
                  title: Text('Rol dəyiş'),
                  trailing: Icon(Icons.chevron_right, color: AppColors.muted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
