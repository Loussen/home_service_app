import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

/// Renders Google Map only when [AppConfig.hasGoogleMapsKey] is true.
class MatchesMap extends StatefulWidget {
  const MatchesMap({
    super.key,
    required this.request,
    this.selectedProviderId,
    this.onProviderTap,
    this.expanded = false,
  });

  final ServiceRequestModel request;
  final int? selectedProviderId;
  final ValueChanged<int>? onProviderTap;
  final bool expanded;

  @override
  State<MatchesMap> createState() => _MatchesMapState();
}

class _MatchesMapState extends State<MatchesMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(MatchesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedProviderId != widget.selectedProviderId &&
        widget.selectedProviderId != null) {
      _focusProvider(widget.selectedProviderId!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Set<Marker> _markers() {
    final request = widget.request;
    final selected = widget.selectedProviderId;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: LatLng(request.latitude, request.longitude),
        infoWindow: InfoWindow(title: t('search.map_your_location')),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    for (final m in request.matches) {
      final p = m.provider;
      if (p == null) continue;
      final id = p.id;
      markers.add(
        Marker(
          markerId: MarkerId('p_$id'),
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(
            title: (p.userName != null && p.userName!.trim().isNotEmpty)
                ? p.userName!
                : (p.title ?? p.category?.nameAz ?? t('match.provider_fallback')),
            snippet: t('match.score', params: {'score': '${m.matchScore.round()}'}),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selected == id
                ? BitmapDescriptor.hueOrange
                : (p.isVip ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen),
          ),
          onTap: () => widget.onProviderTap?.call(id),
        ),
      );
    }
    return markers;
  }

  Future<void> _fitBounds() async {
    final c = _controller;
    if (c == null) return;

    final request = widget.request;
    var minLat = request.latitude;
    var maxLat = request.latitude;
    var minLng = request.longitude;
    var maxLng = request.longitude;

    for (final m in request.matches) {
      final p = m.provider;
      if (p == null) continue;
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    if (request.matches.isEmpty) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(request.latitude, request.longitude),
          13,
        ),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  Future<void> _focusProvider(int providerId) async {
    MatchModel? match;
    for (final m in widget.request.matches) {
      if (m.provider?.id == providerId) {
        match = m;
        break;
      }
    }
    final p = match?.provider;
    if (p == null || _controller == null) return;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(p.latitude, p.longitude), 14.5),
    );
  }

  Future<void> _zoom(bool inward) async {
    final c = _controller;
    if (c == null) return;
    await c.animateCamera(
      inward ? CameraUpdate.zoomIn() : CameraUpdate.zoomOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGoogleMapsKey) {
      return _Placeholder(
        matchCount: widget.request.matches.length,
        latitude: widget.request.latitude,
        longitude: widget.request.longitude,
      );
    }

    final height = widget.expanded ? 420.0 : 260.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.request.latitude,
                  widget.request.longitude,
                ),
                zoom: 12.5,
              ),
              markers: _markers(),
              onMapCreated: (c) {
                _controller = c;
                _fitBounds();
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: false,
              mapToolbarEnabled: false,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
            ),
            Positioned(
              right: 10,
              bottom: 12,
              child: Column(
                children: [
                  _ZoomFab(icon: Icons.add, onTap: () => _zoom(true)),
                  const SizedBox(height: 8),
                  _ZoomFab(icon: Icons.remove, onTap: () => _zoom(false)),
                  const SizedBox(height: 8),
                  _ZoomFab(icon: Icons.fit_screen, onTap: _fitBounds),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomFab extends StatelessWidget {
  const _ZoomFab({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.matchCount,
    required this.latitude,
    required this.longitude,
  });

  final int matchCount;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peach.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(t('search.map_unavailable'), style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t('search.map_providers_count', params: {'count': '$matchCount'}),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            t('search.map_key_hint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
