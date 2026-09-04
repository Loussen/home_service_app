import 'package:home_service_app/core/remote/app_remote_config.dart';

abstract class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure([String? message]) : super(message ?? t('error.network'));
}

class CacheFailure extends Failure {
  CacheFailure([String? message]) : super(message ?? t('error.cache'));
}

class AccountBlockedFailure extends Failure {
  AccountBlockedFailure([String? message])
      : super(message ?? t('web.auth.blocked_body'));
}
