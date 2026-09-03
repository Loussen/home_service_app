/// App env / compile-time flags.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Production (mysancho.com). Local override:
    // flutter run --dart-define=API_BASE_URL=https://home-service.test/api/v1
    //   or --dart-define-from-file=dart_defines.json
    defaultValue: 'https://mysancho.com/api/v1',
  );

  /// Google Maps API key (Maps SDK for iOS / Android).
  /// Without this, match screen shows a list-only placeholder (no crash).
  /// Local: copy `dart_defines.example.json` → `dart_defines.json` (gitignored).
  /// ```bash
  /// flutter run --dart-define-from-file=dart_defines.json
  /// ```
  /// Hot reload is not enough — Maps SDK reads the key at native launch.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  /// Debug only: always open provider onboarding after login / hot reload.
  /// ```bash
  /// flutter run --dart-define=FORCE_ONBOARDING=true --dart-define-from-file=dart_defines.json
  /// ```
  static const bool forceOnboarding = bool.fromEnvironment(
    'FORCE_ONBOARDING',
    defaultValue: false,
  );

  static const String appName = 'MySancho';

  static String get apiHostHint => apiBaseUrl;
}
