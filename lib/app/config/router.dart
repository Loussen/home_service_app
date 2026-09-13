import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/app/config/auth_router_refresh.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/welcome/welcome_intro_storage.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:home_service_app/features/auth/presentation/pages/auth_boot_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/login_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/otp_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/provider_onboarding_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/provider_pending_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/role_page.dart';
import 'package:home_service_app/features/welcome/presentation/pages/welcome_intro_page.dart';
import 'package:home_service_app/features/chat/presentation/pages/blocked_users_page.dart';
import 'package:home_service_app/features/profile/presentation/pages/favorites_page.dart';
import 'package:home_service_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:home_service_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:home_service_app/features/chat/presentation/pages/chat_thread_page.dart';
import 'package:home_service_app/features/home/presentation/pages/account_page.dart';
import 'package:home_service_app/features/home/presentation/pages/main_tab_shell.dart';
import 'package:home_service_app/features/home/presentation/pages/role_tabs.dart';
import 'package:home_service_app/features/home/presentation/pages/static_page_screen.dart';
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
  initialLocation: '/boot',
  refreshListenable: authRouterRefresh,
  redirect: (context, state) {
    final auth = context.read<AuthCubit>().state;
    final loc = state.matchedLocation;
    final welcomeSeen = getIt.isRegistered<WelcomeIntroStorage>()
        ? getIt<WelcomeIntroStorage>().seen
        : true;
    final isPublic =
        loc == '/login' || loc == '/otp' || loc == '/welcome' || loc == '/boot';

    // Session restore in progress — never flash login for returning users.
    if (auth.status == AuthStatus.unknown) {
      return loc == '/boot' ? null : '/boot';
    }

    if (auth.status != AuthStatus.authenticated) {
      if (loc == '/boot') {
        return welcomeSeen ? '/login' : '/welcome';
      }
      if (loc == '/otp' && (auth.pendingPhone == null || auth.pendingPhone!.isEmpty)) {
        return '/login';
      }
      if (!welcomeSeen && loc != '/welcome' && loc != '/otp') {
        return '/welcome';
      }
      if (welcomeSeen && loc == '/welcome') return '/login';
      return isPublic ? null : '/login';
    }

    // Logged in — leave boot / login / otp; allow replay of product intro.
    if (loc == '/boot' || loc == '/login' || loc == '/otp') {
      if (AppConfig.forceOnboarding) return '/onboarding';
      if (auth.user?.needsRole == true || auth.isNewUser) return '/role';
      if (auth.user?.needsProviderOnboarding == true) return '/onboarding';
      if (_providerAwaitingApproval(auth)) return '/provider-pending';
      return '/search';
    }
    if (loc == '/welcome') {
      final replay = state.uri.queryParameters['replay'] == '1';
      if (replay) return null;
      if (AppConfig.forceOnboarding) return '/onboarding';
      if (auth.user?.needsRole == true || auth.isNewUser) return '/role';
      if (auth.user?.needsProviderOnboarding == true) return '/onboarding';
      if (_providerAwaitingApproval(auth)) return '/provider-pending';
      return '/search';
    }

    final needsRole = auth.user?.needsRole == true || auth.isNewUser;
    if (needsRole) {
      return loc == '/role' ? null : '/role';
    }

    // Session restore / stale login UI: never stay on login or otp when already in.
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
        loc == '/welcome' ||
        loc.startsWith('/profiles') ||
        loc.startsWith('/page/') ||
        loc == '/wallet' ||
        loc == '/verification' ||
        loc == '/blocked' ||
        loc == '/favorites' ||
        loc == '/notifications' ||
        loc == '/reviews';

    if (awaiting && !allowedWhilePending) {
      return '/provider-pending';
    }

    if (loc.startsWith('/profiles/') && auth.user?.isProvider != true) {
      return '/search';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/boot',
      builder: (_, __) => const AuthBootPage(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (_, state) => WelcomeIntroPage(
        replay: state.uri.queryParameters['replay'] == '1',
      ),
    ),
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
      path: '/blocked',
      pageBuilder: (_, state) => _adaptivePage(state, const BlockedUsersPage()),
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (_, state) => _adaptivePage(state, const FavoritesPage()),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (_, state) =>
          _adaptivePage(state, const NotificationsPage()),
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
      path: '/page/:slug',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final title = state.extra is String ? state.extra as String : null;
        return _adaptivePage(
          state,
          StaticPageScreen(slug: slug, initialTitle: title),
          pageKey: ValueKey('static-page-$slug'),
        );
      },
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
