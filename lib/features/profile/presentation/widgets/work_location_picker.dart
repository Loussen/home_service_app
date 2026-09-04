import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/features/profile/data/models/location_models.dart';
import 'package:home_service_app/features/profile/data/places_client.dart';
import 'package:home_service_app/features/profile/presentation/widgets/dependent_location_picker.dart';

class WorkLocationPicker extends StatefulWidget {
  const WorkLocationPicker({
    super.key,
    required this.cities,
    required this.cityId,
    required this.districtId,
    required this.latitude,
    required this.longitude,
    required this.onCity,
    required this.onDistrict,
    required this.onCoordinates,
    required this.onPlaceResolved,
    required this.onUseGps,
    this.addressHint,
  });

  final List<CityModel> cities;
  final int? cityId;
  final int? districtId;
  final double latitude;
  final double longitude;
  final ValueChanged<int> onCity;
  final ValueChanged<int> onDistrict;
  final void Function(double lat, double lng) onCoordinates;
  final ValueChanged<ResolvedPlace> onPlaceResolved;
  final VoidCallback onUseGps;
  final String? addressHint;

  @override
  State<WorkLocationPicker> createState() => _WorkLocationPickerState();
}

class _WorkLocationPickerState extends State<WorkLocationPicker> {
  final _search = TextEditingController();
  final _places = getIt<PlacesClient>();
  final _focus = FocusNode();
  Timer? _debounce;
  GoogleMapController? _map;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;

  @override
  void didUpdateWidget(WorkLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _map?.animateCamera(
        CameraUpdate.newLatLng(LatLng(widget.latitude, widget.longitude)),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    _map?.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final items = await _places.autocomplete(q);
        if (mounted) setState(() => _suggestions = items);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _pickSuggestion(PlaceSuggestion s) async {
    _focus.unfocus();
    setState(() {
      _search.text = s.description;
      _suggestions = [];
    });
    final place = await _places.details(s.placeId);
    if (place == null || !mounted) return;
    widget.onPlaceResolved(place);
  }

  Future<void> _fromMap(LatLng pos) async {
    widget.onCoordinates(pos.latitude, pos.longitude);
    try {
      final place = await _places.reverseGeocode(pos.latitude, pos.longitude);
      if (place != null && mounted) {
        if (place.formattedAddress != null) {
          _search.text = place.formattedAddress!;
        }
        widget.onPlaceResolved(place);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          focusNode: _focus,
          decoration: InputDecoration(
            labelText: t('location.search_address'),
            hintText: t('location.address_hint'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _suggestions = []);
                        },
                      )),
          ),
          onChanged: (v) {
            setState(() {});
            _onQuery(v);
          },
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                  title: Text(s.description, maxLines: 2),
                  onTap: () => _pickSuggestion(s),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        _MapBox(
          latitude: widget.latitude,
          longitude: widget.longitude,
          onCreated: (c) => _map = c,
          onTap: _fromMap,
          onGps: widget.onUseGps,
        ),
        if (widget.addressHint != null && widget.addressHint!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.addressHint!,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        DependentLocationPicker(
          cities: widget.cities,
          cityId: widget.cityId,
          districtId: widget.districtId,
          onCity: widget.onCity,
          onDistrict: widget.onDistrict,
        ),
      ],
    );
  }
}

class _MapBox extends StatelessWidget {
  const _MapBox({
    required this.latitude,
    required this.longitude,
    required this.onCreated,
    required this.onTap,
    required this.onGps,
  });

  final double latitude;
  final double longitude;
  final ValueChanged<GoogleMapController> onCreated;
  final ValueChanged<LatLng> onTap;
  final VoidCallback onGps;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGoogleMapsKey) {
      return Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.peach,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          t('location.maps_key_missing'),
        ),
      );
    }

    final pos = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 13.5),
              markers: {
                Marker(
                  markerId: const MarkerId('work'),
                  position: pos,
                  draggable: true,
                  onDragEnd: onTap,
                ),
              },
              onMapCreated: onCreated,
              onTap: onTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  tooltip: t('location.my_gps'),
                  onPressed: onGps,
                  icon: const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
