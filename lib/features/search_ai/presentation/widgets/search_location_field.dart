import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/profile/data/places_client.dart';

class SearchLocationField extends StatefulWidget {
  const SearchLocationField({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.onChanged,
    this.enabled = true,
  });

  final double latitude;
  final double longitude;
  final String? address;
  final void Function(double lat, double lng, String? address) onChanged;
  final bool enabled;

  @override
  State<SearchLocationField> createState() => _SearchLocationFieldState();
}

class _SearchLocationFieldState extends State<SearchLocationField> {
  final _search = TextEditingController();
  final _places = getIt<PlacesClient>();
  final _focus = FocusNode();
  Timer? _debounce;
  GoogleMapController? _map;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.address?.trim();
    if (addr != null && addr.isNotEmpty) {
      _search.text = addr;
    }
  }

  @override
  void didUpdateWidget(SearchLocationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _map?.animateCamera(
        CameraUpdate.newLatLng(LatLng(widget.latitude, widget.longitude)),
      );
    }
    final addr = widget.address?.trim();
    if (addr != null &&
        addr.isNotEmpty &&
        addr != _search.text &&
        !_focus.hasFocus) {
      _search.text = addr;
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
    if (!widget.enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      if (q.trim().length < 2) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
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
    if (!widget.enabled) return;
    _focus.unfocus();
    setState(() {
      _search.text = s.description;
      _suggestions = [];
    });
    final place = await _places.details(s.placeId);
    if (place == null || !mounted) return;
    widget.onChanged(
      place.latitude,
      place.longitude,
      place.formattedAddress ?? s.description,
    );
  }

  Future<void> _fromMap(LatLng pos) async {
    if (!widget.enabled) return;
    widget.onChanged(pos.latitude, pos.longitude, null);
    try {
      final place = await _places.reverseGeocode(pos.latitude, pos.longitude);
      if (place != null && mounted) {
        final addr = place.formattedAddress;
        if (addr != null && addr.isNotEmpty) {
          setState(() => _search.text = addr);
          widget.onChanged(pos.latitude, pos.longitude, addr);
        }
      }
    } catch (_) {}
  }

  Future<void> _useGps() async {
    if (!widget.enabled) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    await _fromMap(LatLng(pos.latitude, pos.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final coordsHint =
        '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('search.location_label'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          focusNode: _focus,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: t('location.search_address'),
            hintText: 'məs. Nərimanov, Gənclik…',
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
                        onPressed: widget.enabled
                            ? () {
                                _search.clear();
                                setState(() => _suggestions = []);
                              }
                            : null,
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
            constraints: const BoxConstraints(maxHeight: 160),
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
        _SearchMapBox(
          latitude: widget.latitude,
          longitude: widget.longitude,
          enabled: widget.enabled,
          onCreated: (c) => _map = c,
          onTap: _fromMap,
          onGps: _useGps,
        ),
        const SizedBox(height: 6),
        Text(
          widget.address?.trim().isNotEmpty == true
              ? widget.address!.trim()
              : coordsHint,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _SearchMapBox extends StatelessWidget {
  const _SearchMapBox({
    required this.latitude,
    required this.longitude,
    required this.enabled,
    required this.onCreated,
    required this.onTap,
    required this.onGps,
  });

  final double latitude;
  final double longitude;
  final bool enabled;
  final ValueChanged<GoogleMapController> onCreated;
  final ValueChanged<LatLng> onTap;
  final VoidCallback onGps;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGoogleMapsKey) {
      return Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.peach,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(t('location.maps_key_missing')),
      );
    }

    final pos = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 13.5),
              markers: {
                Marker(
                  markerId: const MarkerId('search_center'),
                  position: pos,
                  draggable: enabled,
                  onDragEnd: enabled ? onTap : null,
                ),
              },
              onMapCreated: onCreated,
              onTap: enabled ? onTap : null,
              myLocationEnabled: enabled,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: enabled,
              zoomGesturesEnabled: enabled,
              rotateGesturesEnabled: enabled,
              tiltGesturesEnabled: enabled,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
            ),
            if (enabled)
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
