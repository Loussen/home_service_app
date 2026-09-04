import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when auth state changes so redirects re-run
/// (e.g. session restore must leave `/login` without waiting for a tap).
final ValueNotifier<int> authRouterRefresh = ValueNotifier<int>(0);

void notifyAuthRouter() {
  authRouterRefresh.value++;
}
