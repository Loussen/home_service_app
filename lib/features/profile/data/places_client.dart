import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/core/network/api_response.dart';
import 'package:home_service_app/core/remote/app_locale_service.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description;
}

class ResolvedPlace {
  const ResolvedPlace({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.hints = const [],
  });

  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final List<String> hints;
}

class PlacesClient {
  PlacesClient(this._api, this._locale);

  final ApiClient _api;
  final AppLocaleService _locale;

  bool _configured = true;

  /// Autocomplete/geocode backend proxy (API key server-side).
  bool get isConfigured => _configured;

  Future<List<PlaceSuggestion>> autocomplete(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/places/autocomplete',
        queryParameters: {
          'q': query.trim(),
          'language': _locale.locale,
        },
      );
      final body = res.data ?? {};
      final parsed = ApiResponse.fromJson(body, (raw) => raw);
      if (!parsed.success) {
        if ((parsed.message).toLowerCase().contains('not configured')) {
          _configured = false;
        }
        return const [];
      }
      final list = parsed.data as List<dynamic>? ?? [];
      return list
          .whereType<Map>()
          .map(
            (m) => PlaceSuggestion(
              placeId: '${m['place_id']}',
              description: (m['description'] as String?) ?? '',
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<ResolvedPlace?> details(String placeId) async {
    if (placeId.isEmpty) return null;
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/places/${Uri.encodeComponent(placeId)}',
        queryParameters: {'language': _locale.locale},
      );
      final body = res.data ?? {};
      final parsed = ApiResponse.fromJson(
        body,
        (raw) => Map<String, dynamic>.from(raw as Map),
      );
      if (!parsed.success || parsed.data == null) return null;
      return _fromApi(parsed.data!);
    } catch (_) {
      return null;
    }
  }

  Future<ResolvedPlace?> reverseGeocode(double lat, double lng) async {
    try {
      final res = await _api.dio.get<Map<String, dynamic>>(
        '/places/reverse',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'language': _locale.locale,
        },
      );
      final body = res.data ?? {};
      final parsed = ApiResponse.fromJson(
        body,
        (raw) => Map<String, dynamic>.from(raw as Map),
      );
      if (!parsed.success || parsed.data == null) {
        return ResolvedPlace(latitude: lat, longitude: lng);
      }
      return _fromApi(parsed.data!, fallbackLat: lat, fallbackLng: lng);
    } catch (_) {
      return ResolvedPlace(latitude: lat, longitude: lng);
    }
  }

  ResolvedPlace? _fromApi(
    Map<String, dynamic> data, {
    double? fallbackLat,
    double? fallbackLng,
  }) {
    final lat = (data['latitude'] as num?)?.toDouble() ?? fallbackLat;
    final lng = (data['longitude'] as num?)?.toDouble() ?? fallbackLng;
    if (lat == null || lng == null) return null;

    final hintsRaw = data['hints'];
    final hints = hintsRaw is List
        ? hintsRaw.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : <String>[];

    return ResolvedPlace(
      latitude: lat,
      longitude: lng,
      formattedAddress: data['formatted_address'] as String?,
      hints: hints,
    );
  }
}
