import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:home_service_app/features/auth/presentation/pages/login_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/otp_page.dart';
import 'package:home_service_app/features/auth/presentation/pages/role_page.dart';
import 'package:home_service_app/features/home/presentation/pages/home_shell.dart';
import 'package:home_service_app/features/profile/presentation/pages/profile_form_page.dart';
import 'package:home_service_app/features/profile/presentation/pages/profile_list_page.dart';
import 'package:home_service_app/features/search_ai/presentation/pages/search_ai_page.dart';
import 'package:home_service_app/features/wallet/presentation/pages/wallet_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthCubit>().state;
    final loc = state.matchedLocation;
    final isAuthRoute =
        loc == '/login' || loc == '/otp' || loc == '/role';

    if (auth.status == AuthStatus.unknown) return null;

    if (auth.status != AuthStatus.authenticated) {
      return isAuthRoute ? null : '/login';
    }

    if (loc == '/login' || loc == '/otp') {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/otp', builder: (_, __) => const OtpPage()),
    GoRoute(path: '/role', builder: (_, __) => const RolePage()),
    GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
    GoRoute(path: '/wallet', builder: (_, __) => const WalletPage()),
    GoRoute(path: '/search', builder: (_, __) => const SearchAiPage()),
    GoRoute(path: '/profiles', builder: (_, __) => const ProfileListPage()),
    GoRoute(
      path: '/profiles/new',
      builder: (_, __) => const ProfileFormPage(),
    ),
    GoRoute(
      path: '/profiles/:id',
      builder: (_, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return ProfileFormPage(profileId: id);
      },
    ),
  ],
);
