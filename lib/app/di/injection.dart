import 'package:get_it/get_it.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/core/network/token_storage.dart';
import 'package:home_service_app/features/auth/data/auth_remote_data_source.dart';
import 'package:home_service_app/features/auth/data/auth_repository_impl.dart';
import 'package:home_service_app/features/auth/domain/auth_repository.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/profile/data/profile_remote_data_source.dart';
import 'package:home_service_app/features/profile/data/profile_repository_impl.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_cubit.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_list_cubit.dart';
import 'package:home_service_app/features/search_ai/data/search_remote_data_source.dart';
import 'package:home_service_app/features/search_ai/data/search_repository_impl.dart';
import 'package:home_service_app/features/search_ai/domain/search_repository.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_cubit.dart';
import 'package:home_service_app/features/wallet/data/wallet_remote_data_source.dart';
import 'package:home_service_app/features/wallet/data/wallet_repository_impl.dart';
import 'package:home_service_app/features/wallet/domain/wallet_repository.dart';
import 'package:home_service_app/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage();

  getIt
    ..registerSingleton(prefs)
    ..registerSingleton(tokenStorage)
    ..registerSingleton(ApiClient(tokenStorage))
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory(() => AuthCubit(getIt()))
    ..registerLazySingleton<WalletRemoteDataSource>(
      () => WalletRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(getIt()),
    )
    ..registerFactory(() => WalletCubit(getIt()))
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt()),
    )
    ..registerFactory(() => ProfileListCubit(getIt()))
    ..registerFactoryParam<ProfileFormCubit, int?, void>(
      (id, _) => ProfileFormCubit(getIt(), profileId: id),
    )
    ..registerLazySingleton<SearchRemoteDataSource>(
      () => SearchRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(getIt()),
    )
    ..registerFactory(() => SearchAiCubit(getIt()));
}
