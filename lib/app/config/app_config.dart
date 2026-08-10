/// App env / compile-time flags.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Physical device: use Mac LAN IP + `php artisan serve --host=0.0.0.0`
    // Simulator / Mac: Valet `https://home-service.test/api/v1` also works.
    defaultValue: 'https://home-service.test/api/v1',
  );

  /// Google Maps API key (Maps SDK for iOS / Android).
  /// Without this, match screen shows a list-only placeholder (no crash).
  /// ```bash
  /// flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIza...
  /// ```
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  static const String appName = 'Ev və Ailə Xidmətləri';

  static String get apiHostHint => apiBaseUrl;
}
