import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:home_service_app/features/auth/presentation/pages/login_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/otp_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/provider_onboarding_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/role_page.dart';
import 'package:home_service_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:home_service_app/features/chat/presentation/pages/chat_thread_page.dart';
import 'package:home_service_app/features/home/presentation/pages/account_page.dart';
import 'package:home_service_app/features/home/presentation/pages/main_tab_shell.dart';
import 'package:home_service_app/features/home/presentation/pages/role_tabs.dart';
import 'package:home_service_app/features/profile/presentation/pages/profile_form_page.dart';
import 'package:home_service_app/features/wallet/presentation/pages/wallet_page.dart';
import 'package:home_service_app/features/chat/presentation/pages/reviews_page.dart';
import 'package:home_service_app/features/verification/presentation/pages/verification_page.dart';
import 'package:home_service_app/features/bookings/presentation/pages/bookings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthCubit>().state;
    final loc = state.matchedLocation;
    final isPublic = loc == '/login' || loc == '/otp';

    if (auth.status == AuthStatus.unknown) return null;

    if (auth.status != AuthStatus.authenticated) {
      return isPublic ? null : '/login';
    }

    if (loc == '/login' || loc == '/otp') {
      if (AppConfig.forceOnboarding) return '/onboarding';
      if (auth.isNewUser) return '/role';
      if (auth.user?.needsProviderOnboarding == true) return '/onboarding';
      return '/search';
    }

    if (loc.startsWith('/profiles/') && auth.user?.isProvider != true) {
      return '/search';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(
      path: '/otp',
      pageBuilder: (_, state) => _adaptivePage(state, const OtpPage()),
    ),
    GoRoute(
      path: '/role',
      pageBuilder: (_, state) => _adaptivePage(state, const RolePage()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, state) =>
          _adaptivePage(state, const ProviderOnboardingPage()),
    ),
    GoRoute(
      path: '/wallet',
      pageBuilder: (_, state) => _adaptivePage(state, const WalletPage()),
    ),
    GoRoute(
      path: '/reviews',
      pageBuilder: (_, state) => _adaptivePage(state, const ReviewsPage()),
    ),
    GoRoute(
      path: '/verification',
      pageBuilder: (_, state) => _adaptivePage(state, const VerificationPage()),
    ),
    GoRoute(
      path: '/bookings',
      pageBuilder: (_, state) => _adaptivePage(state, const BookingsPage()),
    ),
    GoRoute(
      path: '/profiles/new',
      pageBuilder: (_, state) => _adaptivePage(state, const ProfileFormPage()),
    ),
    GoRoute(
      path: '/profiles/:id',
      pageBuilder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return _adaptivePage(state, ProfileFormPage(profileId: id));
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainTabShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, __) => const RoleHomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profiles',
              builder: (_, __) => const RoleSecondPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (_, __) => const ChatListPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (_, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    return _adaptivePage(
                      state,
                      ChatThreadPage(conversationId: id),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/account', builder: (_, __) => const AccountPage()),
          ],
        ),
      ],
    ),
  ],
);

Page<dynamic> _adaptivePage(GoRouterState state, Widget child) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }
  return MaterialPage<void>(key: state.pageKey, child: child);
}
