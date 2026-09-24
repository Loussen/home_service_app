import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/chat/chat_unread_badge.dart';

class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell>
    with WidgetsBindingObserver {
  late final ChatUnreadBadge _unreadBadge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unreadBadge = getIt<ChatUnreadBadge>();
    _unreadBadge.startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadBadge.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_unreadBadge.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider =
        context.watch<AuthCubit>().state.user?.activeRole == 'provider';
    final index = widget.navigationShell.currentIndex;

    final items = [
      _NavSpec(
        icon: isProvider ? Icons.work_outline : Icons.search,
        activeIcon: isProvider ? Icons.work : Icons.search,
        label: isProvider ? t('tabs.provider.jobs') : t('tabs.client.search'),
      ),
      _NavSpec(
        icon: isProvider ? Icons.badge_outlined : Icons.assignment_outlined,
        activeIcon: isProvider ? Icons.badge : Icons.assignment,
        label: isProvider
            ? t('tabs.provider.profiles')
            : t('tabs.client.requests'),
      ),
      _NavSpec(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: t('tabs.chat'),
        showUnreadBadge: true,
      ),
      _NavSpec(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: isProvider ? t('tabs.account') : t('tabs.profile'),
      ),
    ];

    return ListenableBuilder(
      listenable: _unreadBadge,
      builder: (context, _) {
        final unread = _unreadBadge.count;
        return Scaffold(
          body: widget.navigationShell,
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
                        onTap: () => widget.navigationShell.goBranch(i),
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
                              _NavIcon(
                                icon: selected ? item.activeIcon : item.icon,
                                selected: selected,
                                badgeCount: item.showUnreadBadge ? unread : 0,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
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
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.badgeCount,
  });

  final IconData icon;
  final bool selected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 22,
      color: selected ? AppColors.primary : AppColors.muted,
    );
    if (badgeCount <= 0) return iconWidget;

    final label = badgeCount > 99 ? '99+' : '$badgeCount';
    return Badge(
      backgroundColor: AppColors.badge,
      textColor: Colors.white,
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      child: iconWidget,
    );
  }
}

class _NavSpec {
  const _NavSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showUnreadBadge = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showUnreadBadge;
}
