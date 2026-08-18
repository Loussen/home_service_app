import 'package:home_service_app/features/profile/data/models/location_models.dart';

class LocationMatch {
  const LocationMatch({
    required this.cityId,
    required this.districtId,
    required this.city,
    required this.district,
  });

  final int? cityId;
  final int? districtId;
  final String city;
  final String district;
}

abstract final class LocationMatcher {
  static String fold(String raw) {
    var s = raw.toLowerCase().trim().replaceAll('ə', 'e').replaceAll('ı', 'i')
        .replaceAll('ö', 'o').replaceAll('ü', 'u').replaceAll('ç', 'c')
        .replaceAll('ş', 's').replaceAll('ğ', 'g');
    s = s.replaceAll('baku', 'baki').replaceAll('ganja', 'gence');
    return s;
  }

  static LocationMatch match(
    List<CityModel> locations, {
    int? cityId,
    int? districtId,
    String? cityName,
    String? districtName,
    List<String> hints = const [],
  }) {
    CityModel? city;
    city = _findCity(locations, hints);
    if (city == null && cityId != null) {
      for (final c in locations) {
        if (c.id == cityId) city = c;
      }
    }
    if (city == null && cityName != null) {
      city = _findCity(locations, [cityName]);
    }
    city ??= locations.isEmpty ? null : locations.first;

    DistrictModel? district;
    final districts = city?.districts ?? const <DistrictModel>[];
    district = _findDistrict(districts, hints);
    if (district == null && districtId != null) {
      for (final d in districts) {
        if (d.id == districtId) district = d;
      }
    }
    if (district == null && districtName != null && districtName.isNotEmpty) {
      district = _findDistrict(districts, [districtName]);
    }
    if (district == null) {
      for (final c in locations) {
        final d = _findDistrict(c.districts, hints);
        if (d != null) {
          city = c;
          district = d;
          break;
        }
      }
    }
    district ??= (city?.districts.length == 1) ? city!.districts.first : null;

    return LocationMatch(
      cityId: city?.id,
      districtId: district?.id,
      city: city?.name ?? cityName ?? 'Bakı',
      district: district?.name ?? districtName ?? '',
    );
  }

  static CityModel? _findCity(List<CityModel> cities, List<String> names) {
    final folded = names.map(fold).where((s) => s.length > 2).toList();
    for (final c in cities) {
      final cn = fold(c.name);
      for (final n in folded) {
        if (n == cn || n.contains(cn) || cn.contains(n)) return c;
      }
    }
    return null;
  }

  static DistrictModel? _findDistrict(
    List<DistrictModel> districts,
    List<String> names,
  ) {
    final folded = names.map(fold).where((s) => s.length > 2).toList();
    for (final d in districts) {
      final dn = fold(d.name);
      for (final n in folded) {
        if (n == dn || n.contains(dn) || dn.contains(n)) return d;
      }
    }
    return null;
  }
}
