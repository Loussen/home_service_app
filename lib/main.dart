import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/app_theme.dart';
import 'package:home_service_app/app/config/router.dart';
import 'package:home_service_app/core/push/push_service.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/remote/app_locale_notifier.dart';
import 'package:home_service_app/core/remote/app_locale_service.dart';
import 'package:home_service_app/core/remote/locale_rebuild.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/app/observers/app_bloc_observer.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[push] Firebase skipped: $e');
  }
  Bloc.observer = AppBlocObserver();
  await configureDependencies();
  runApp(const HomeServiceApp());
}

class HomeServiceApp extends StatefulWidget {
  const HomeServiceApp({super.key});

  @override
  State<HomeServiceApp> createState() => _HomeServiceAppState();
}

class _HomeServiceAppState extends State<HomeServiceApp> {
  /// Hot reload (`r`) yalnız `FORCE_ONBOARDING=true` olanda onboarding-i açır.
  @override
  void reassemble() {
    super.reassemble();
    if (!kDebugMode || !AppConfig.forceOnboarding) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      appRouter.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<AuthCubit>();
        // After first frame so GoRouter is listening before session restore emits.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(cubit.bootstrap());
        });
        return cubit;
      },
      child: ValueListenableBuilder<String>(
        valueListenable: appLocaleNotifier,
        builder: (context, localeCode, _) {
          final supported = getIt<AppLocaleService>().supportedLocales
              .map((code) => Locale(code))
              .toList();
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: appRouter,
            builder: (context, child) {
              return MultiBlocListener(
                listeners: [
                  BlocListener<AuthCubit, AuthState>(
                    listenWhen: (prev, next) =>
                        prev.status == AuthStatus.authenticated &&
                        next.status == AuthStatus.unauthenticated,
                    listener: (context, state) {
                      appRouter.go('/login');
                    },
                  ),
                  BlocListener<AuthCubit, AuthState>(
                    listenWhen: (prev, next) =>
                        next.accountBlocked &&
                        next.message != null &&
                        next.message != prev.message,
                    listener: (context, state) async {
                      final msg = state.message;
                      if (msg == null) return;
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: AppColors.ink.withValues(alpha: 0.45),
                        builder: (ctx) => Dialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                            side: const BorderSide(color: AppColors.divider),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: AppColors.peach,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.block_rounded,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  t('web.auth.blocked_title'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  msg,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      context
                                          .read<AuthCubit>()
                                          .clearAccountBlockedFlag();
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(t('web.alert.ok')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                child: LocaleRebuild(
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
            locale: Locale(localeCode),
            supportedLocales: supported.isNotEmpty
                ? supported
                : const [Locale('az'), Locale('en'), Locale('ru')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
