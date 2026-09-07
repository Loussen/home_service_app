import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/app/config/auth_router_refresh.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/welcome/welcome_intro_storage.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

/// Shown while [AuthCubit.bootstrap] restores a saved Sanctum session.
class AuthBootPage extends StatefulWidget {
  const AuthBootPage({super.key});

  @override
  State<AuthBootPage> createState() => _AuthBootPageState();
}

class _AuthBootPageState extends State<AuthBootPage> {
  @override
  void initState() {
    super.initState();
    // Cover race where bootstrap finished before GoRouter refreshed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _leaveIfReady());
  }

  void _leaveIfReady() {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth.status == AuthStatus.unknown) return;
    notifyAuthRouter();
    final welcomeSeen = getIt.isRegistered<WelcomeIntroStorage>()
        ? getIt<WelcomeIntroStorage>().seen
        : true;
    if (auth.status == AuthStatus.authenticated) {
      context.go('/search');
    } else {
      context.go(welcomeSeen ? '/login' : '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, next) =>
          prev.status == AuthStatus.unknown &&
          next.status != AuthStatus.unknown,
      listener: (context, state) => _leaveIfReady(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/brand/logo-color.jpg',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
