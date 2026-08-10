import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rol seçin')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ListTile(
              title: const Text('Ailə / Müştəri'),
              subtitle: const Text('Xidmət axtar, səsli sorğu göndər'),
              onTap: () async {
                await context.read<AuthCubit>().setRole('client');
                if (context.mounted) context.go('/home');
              },
            ),
            ListTile(
              title: const Text('Xidmət göstərən'),
              subtitle: const Text('Profil yarat, sifariş al (welcome bonus)'),
              onTap: () async {
                await context.read<AuthCubit>().setRole('provider');
                if (context.mounted) context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}
