import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/app/config/app_theme.dart';
import 'package:home_service_app/app/config/router.dart';
import 'package:home_service_app/core/push/push_service.dart';
import 'package:home_service_app/core/remote/app_locale_notifier.dart';
import 'package:home_service_app/core/remote/app_locale_service.dart';
import 'package:home_service_app/core/remote/locale_rebuild.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/app/observers/app_bloc_observer.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      create: (_) => getIt<AuthCubit>()..bootstrap(),
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
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
