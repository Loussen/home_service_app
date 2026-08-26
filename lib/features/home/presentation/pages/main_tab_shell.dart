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
    final index = navigationShell.currentIndex;

    final items = [
      _NavSpec(
        icon: isProvider ? Icons.work_outline : Icons.search,
        activeIcon: isProvider ? Icons.work : Icons.search,
        label: isProvider ? t('tabs.provider.jobs') : t('tabs.client.search'),
      ),
      _NavSpec(
        icon: isProvider ? Icons.layers_outlined : Icons.assignment_outlined,
        activeIcon: isProvider ? Icons.layers : Icons.assignment,
        label: isProvider
            ? t('tabs.provider.profiles')
            : t('tabs.client.requests'),
      ),
      _NavSpec(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: t('tabs.chat'),
      ),
      _NavSpec(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: t('tabs.profile'),
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = i == index;
                final item = items[i];
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => navigationShell.goBranch(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.peach.withValues(alpha: 0.9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
