import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/config/app_theme.dart';
import 'package:home_service_app/app/config/router.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/app/observers/app_bloc_observer.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  await configureDependencies();
  runApp(const HomeServiceApp());
}

class HomeServiceApp extends StatelessWidget {
  const HomeServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>()..bootstrap(),
      child: MaterialApp.router(
        title: 'Ev və Ailə Xidmətləri',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
