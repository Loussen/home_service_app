import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ev və Ailə Xidmətləri'),
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
            padding: const EdgeInsets.all(24),
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
              ),
              const SizedBox(height: 24),
              if (isProvider)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.work_outline),
                    title: const Text('Xidmət profilləri'),
                    subtitle: const Text('Cədvəl, audio intro, multi-profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profiles'),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.mic),
                    title: const Text('AI səsli sorğu'),
                    subtitle: const Text('Danışın — match + xəritə'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/search'),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Xəritədə axtar'),
                  subtitle: const Text('Eyni AI match axını'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/search'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Rol dəyiş'),
                  onTap: () => context.push('/role'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
