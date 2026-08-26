import 'package:flutter/material.dart';
import 'package:home_service_app/core/remote/app_locale_notifier.dart';

/// Rebuilds [child] when app language changes so [t] labels refresh.
///
/// GoRouter shell pages otherwise keep the previous frame's strings.
class LocaleRebuild extends StatelessWidget {
  const LocaleRebuild({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, _) {
        return KeyedSubtree(
          key: ValueKey('app_locale_$locale'),
          child: child,
        );
      },
    );
  }
}
