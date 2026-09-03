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
import 'package:home_service_app/features/auth/presentation/pages/provider_pending_page.dart';
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
import 'package:home_service_app/features/search_ai/presentation/pages/request_detail_page.dart';
import 'package:home_service_app/features/profile/presentation/pages/provider_public_profile_page.dart';

/// Root navigator — full-screen routes (chat thread, etc.) sit above the tab shell.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

bool _providerAwaitingApproval(AuthState auth) {
  final user = auth.user;
  if (user == null || !user.isProvider) return false;
  return user.isProviderPending || user.isProviderRejected;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthCubit>().state;
    final loc = state.matchedLocation;
    final isPublic = loc == '/login' || loc == '/otp';

    if (auth.status == AuthStatus.unknown) return null;

    if (auth.status != AuthStatus.authenticated) {
      return isPublic ? null : '/login';
    }

    final needsRole = auth.user?.needsRole == true || auth.isNewUser;
    if (needsRole) {
      return loc == '/role' ? null : '/role';
    }

    if (loc == '/role' || loc == '/login' || loc == '/otp') {
      if (AppConfig.forceOnboarding) return '/onboarding';
      if (auth.user?.needsProviderOnboarding == true) return '/onboarding';
      if (_providerAwaitingApproval(auth)) return '/provider-pending';
      return '/search';
    }

    if (auth.user?.needsProviderOnboarding == true && loc != '/onboarding') {
      return '/onboarding';
    }

    final awaiting = _providerAwaitingApproval(auth);
    final allowedWhilePending = loc == '/provider-pending' ||
        loc == '/account' ||
        loc == '/onboarding' ||
        loc.startsWith('/profiles') ||
        loc == '/wallet' ||
        loc == '/verification';

    if (awaiting && !allowedWhilePending) {
      return '/provider-pending';
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
      path: '/provider-pending',
      pageBuilder: (_, state) =>
          _adaptivePage(state, const ProviderPendingPage()),
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
      path: '/requests/:id',
      pageBuilder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return _adaptivePage(state, RequestDetailPage(requestId: id));
      },
    ),
    GoRoute(
      path: '/providers/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final requestId =
            int.tryParse(state.uri.queryParameters['requestId'] ?? '');
        return _adaptivePage(
          state,
          ProviderPublicProfilePage(
            profileId: id,
            serviceRequestId: requestId,
          ),
          pageKey: ValueKey('provider-public-$id'),
        );
      },
    ),
    // Full-screen chat thread above tabs — avoids duplicate pageKey crash when
    // pushing /chat/:id from /search (another StatefulShell branch).
    GoRoute(
      path: '/chat/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return _adaptivePage(
          state,
          ChatThreadPage(conversationId: id),
          pageKey: ValueKey('chat-thread-$id'),
        );
      },
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

Page<dynamic> _adaptivePage(
  GoRouterState state,
  Widget child, {
  LocalKey? pageKey,
}) {
  final key = pageKey ?? state.pageKey;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: key, child: child);
  }
  return MaterialPage<void>(key: key, child: child);
}
