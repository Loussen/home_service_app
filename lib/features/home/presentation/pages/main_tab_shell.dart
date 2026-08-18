import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainTabShell extends StatelessWidget {
  const MainTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isProvider =
        context.watch<AuthCubit>().state.user?.activeRole == 'provider';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: navigationShell.goBranch,
          items: [
            BottomNavigationBarItem(
              icon: Icon(isProvider ? Icons.work_outline : Icons.search),
              label: isProvider ? t('tabs.provider.jobs') : t('tabs.client.search'),
            ),
            BottomNavigationBarItem(
              icon: Icon(isProvider ? Icons.layers_outlined : Icons.assignment_outlined),
              label: isProvider ? t('tabs.provider.profiles') : t('tabs.client.requests'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              label: t('tabs.chat'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              label: t('tabs.profile'),
            ),
          ],
        ),
      ),
    );
  }
}
