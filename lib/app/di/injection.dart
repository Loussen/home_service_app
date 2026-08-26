import 'package:get_it/get_it.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/core/network/token_storage.dart';
import 'package:home_service_app/core/push/device_token_remote.dart';
import 'package:home_service_app/core/push/push_service.dart';
import 'package:home_service_app/core/remote/app_locale_notifier.dart';
import 'package:home_service_app/core/remote/app_locale_service.dart';
import 'package:home_service_app/features/profile/data/places_client.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/remote/bootstrap_remote_data_source.dart';
import 'package:home_service_app/features/auth/data/auth_remote_data_source.dart';
import 'package:home_service_app/features/auth/data/auth_repository_impl.dart';
import 'package:home_service_app/features/auth/domain/auth_repository.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/chat/data/chat_remote_data_source.dart';
import 'package:home_service_app/features/chat/data/chat_repository_impl.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';
import 'package:home_service_app/features/chat/presentation/cubit/chat_list_cubit.dart';
import 'package:home_service_app/features/chat/presentation/cubit/chat_thread_cubit.dart';
import 'package:home_service_app/features/jobs/data/jobs_remote_data_source.dart';
import 'package:home_service_app/features/jobs/data/jobs_repository_impl.dart';
import 'package:home_service_app/features/jobs/domain/jobs_repository.dart';
import 'package:home_service_app/features/jobs/presentation/cubit/jobs_cubit.dart';
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
import 'package:home_service_app/features/verification/data/verification_remote_data_source.dart';
import 'package:home_service_app/features/verification/data/verification_repository_impl.dart';
import 'package:home_service_app/features/verification/domain/verification_repository.dart';
import 'package:home_service_app/features/verification/presentation/cubit/verification_cubit.dart';
import 'package:home_service_app/features/bookings/data/bookings_remote_data_source.dart';
import 'package:home_service_app/features/bookings/data/bookings_repository_impl.dart';
import 'package:home_service_app/features/bookings/domain/bookings_repository.dart';
import 'package:home_service_app/features/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage();

  getIt
    ..registerSingleton(prefs)
    ..registerSingleton(tokenStorage)
    ..registerSingleton(ApiClient(tokenStorage))
    ..registerLazySingleton(() => DeviceTokenRemote(getIt<ApiClient>()))
    ..registerLazySingleton(() => PushService(getIt<DeviceTokenRemote>()))
    ..registerLazySingleton<BootstrapRemoteDataSource>(
      () => BootstrapRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory(() => AuthCubit(getIt(), getIt<PushService>()))
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(getIt()),
    )
    ..registerFactory(() => ChatListCubit(getIt()))
    ..registerFactoryParam<ChatThreadCubit, int, void>(
      (id, _) => ChatThreadCubit(getIt(), conversationId: id),
    )
    ..registerLazySingleton<JobsRemoteDataSource>(
      () => JobsRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<JobsRepository>(
      () => JobsRepositoryImpl(getIt()),
    )
    ..registerFactory(() => JobsCubit(getIt(), getIt()))
    ..registerLazySingleton<WalletRemoteDataSource>(
      () => WalletRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(getIt()),
    )
    ..registerFactory(() => WalletCubit(getIt()))
    ..registerLazySingleton<VerificationRemoteDataSource>(
      () => VerificationRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<VerificationRepository>(
      () => VerificationRepositoryImpl(getIt()),
    )
    ..registerFactory(() => VerificationCubit(getIt()))
    ..registerLazySingleton<BookingsRemoteDataSource>(
      () => BookingsRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<BookingsRepository>(
      () => BookingsRepositoryImpl(getIt()),
    )
    ..registerFactory(() => BookingsCubit(getIt()))
    ..registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt()),
    )
    ..registerFactory(() => ProfileListCubit(getIt()))
    ..registerFactoryParam<ProfileFormCubit, int?, void>(
      (id, _) => ProfileFormCubit(
        getIt(),
        getIt<PlacesClient>(),
        profileId: id,
      ),
    )
    ..registerLazySingleton<SearchRemoteDataSource>(
      () => SearchRemoteDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(getIt()),
    )
    ..registerFactory(() => SearchAiCubit(getIt(), getIt<ProfileRepository>()));

  final localeService = AppLocaleService(prefs);
  await localeService.init();
  getIt.registerSingleton(localeService);

  getIt.registerLazySingleton<PlacesClient>(
    () => PlacesClient(getIt<ApiClient>(), getIt<AppLocaleService>()),
  );

  await AppRemoteConfig.instance.load(
    getIt<BootstrapRemoteDataSource>(),
    locale: localeService.locale,
  );
  localeService.applyRemoteMeta(
    supported: AppRemoteConfig.instance.supportedLocales,
    labels: AppRemoteConfig.instance.localeLabels,
    defaultLocale: AppRemoteConfig.instance.payload.defaultLocale,
  );
  appLocaleNotifier.value = localeService.locale;
}
