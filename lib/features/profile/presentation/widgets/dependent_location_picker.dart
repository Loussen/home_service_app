import 'package:flutter/material.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/features/profile/data/models/location_models.dart';

class DependentLocationPicker extends StatelessWidget {
  const DependentLocationPicker({
    super.key,
    required this.cities,
    required this.cityId,
    required this.districtId,
    required this.onCity,
    required this.onDistrict,
  });

  final List<CityModel> cities;
  final int? cityId;
  final int? districtId;
  final ValueChanged<int> onCity;
  final ValueChanged<int> onDistrict;

  CityModel? get _city {
    for (final c in cities) {
      if (c.id == cityId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final districts = _city?.districts ?? const <DistrictModel>[];
    final cityIds = {for (final c in cities) c.id};
    final districtIds = {for (final d in districts) d.id};

    return Column(
      children: [
        DropdownButtonFormField<int>(
          value: cityId != null && cityIds.contains(cityId) ? cityId : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: t('location.city_label')),
          hint: Text(t('location.city_hint')),
          items: cities
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    c.type == 'rayon'
                        ? t('location.rayon_suffix', params: {'name': c.name})
                        : c.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null) onCity(id);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: districtId != null && districtIds.contains(districtId)
              ? districtId
              : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: t('location.district_label')),
          hint: Text(
            cityId == null
                ? t('location.district_pick_city')
                : t('location.district_hint'),
            style: const TextStyle(color: AppColors.muted),
          ),
          items: districts
              .map(
                (d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: cityId == null
              ? null
              : (id) {
                  if (id != null) onDistrict(id);
                },
        ),
      ],
    );
  }
}
