class DistrictModel {
  const DistrictModel({
    required this.id,
    required this.cityId,
    required this.name,
    required this.slug,
  });

  final int id;
  final int cityId;
  final String name;
  final String slug;

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'] as int,
      cityId: json['city_id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.type = 'city',
    this.districts = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String type;
  final List<DistrictModel> districts;

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final districtsJson = json['districts'] as List<dynamic>? ?? [];
    return CityModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String? ?? 'city',
      districts: districtsJson
          .map((e) => DistrictModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
