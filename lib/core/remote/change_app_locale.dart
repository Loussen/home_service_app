import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_locale_notifier.dart';
import 'package:home_service_app/core/remote/app_locale_service.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/remote/bootstrap_remote_data_source.dart';

Future<void> changeAppLocale(String locale) async {
  final service = getIt<AppLocaleService>();
  await service.setLocale(locale);
  await AppRemoteConfig.instance.reload(getIt<BootstrapRemoteDataSource>(), locale);
  service.applyRemoteMeta(
    supported: AppRemoteConfig.instance.supportedLocales,
    labels: AppRemoteConfig.instance.localeLabels,
    defaultLocale: AppRemoteConfig.instance.payload.defaultLocale,
  );
  appLocaleNotifier.value = locale;
}
