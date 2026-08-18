import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

/// App UI language — synced with `GET /bootstrap?locale=`.
class AppLocaleService {
  AppLocaleService(this._prefs);

  final SharedPreferences _prefs;

  static const prefKey = 'app_locale_v1';

  String _locale = 'az';
  List<String> _supported = const ['az', 'en', 'ru'];
  Map<String, String> _labels = const {
    'az': 'Azərbaycan',
    'en': 'English',
    'ru': 'Русский',
  };

  String get locale => _locale;
  List<String> get supportedLocales => _supported;
  Map<String, String> get localeLabels => _labels;

  Future<void> init({List<String>? supportedFromRemote}) async {
    if (supportedFromRemote != null && supportedFromRemote.isNotEmpty) {
      _supported = supportedFromRemote;
    }
    final saved = _prefs.getString(prefKey);
    if (saved != null && _supported.contains(saved)) {
      _locale = saved;
      return;
    }
    _locale = _deviceLocale();
  }

  void applyRemoteMeta({
    required List<String> supported,
    required Map<String, String> labels,
    String? defaultLocale,
  }) {
    if (supported.isNotEmpty) {
      _supported = supported;
    }
    if (labels.isNotEmpty) {
      _labels = labels;
    }
    if (!_supported.contains(_locale)) {
      _locale = defaultLocale ?? _supported.first;
    }
  }

  Future<void> setLocale(String locale) async {
    if (!_supported.contains(locale)) return;
    _locale = locale;
    await _prefs.setString(prefKey, locale);
  }

  String labelFor(String code) => _labels[code] ?? code;

  String _deviceLocale() {
    final code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (_supported.contains(code)) return code;
    return _supported.first;
  }
}
