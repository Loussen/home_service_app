import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

/// Renders Google Map only when [AppConfig.hasGoogleMapsKey] is true.
/// Otherwise a non-crashing placeholder (API key not initialized).
class MatchesMap extends StatelessWidget {
  const MatchesMap({
    super.key,
    required this.request,
  });

  final ServiceRequestModel request;

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGoogleMapsKey) {
      return _Placeholder(
        matchCount: request.matches.length,
        latitude: request.latitude,
        longitude: request.longitude,
      );
    }

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: LatLng(request.latitude, request.longitude),
        infoWindow: const InfoWindow(title: 'Sizin məkanınız'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    for (final m in request.matches) {
      final p = m.provider;
      if (p == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('p_${p.id}'),
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(
            title: p.title ?? p.category?.nameAz ?? 'Provider',
            snippet:
                '${m.matchScore.round()}% · ${m.distanceKm.toStringAsFixed(1)} km',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            p.isVip ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(request.latitude, request.longitude),
            zoom: 12.5,
          ),
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
              Text('Xəritə (debug)', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$matchCount provider · mərkəz '
            '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Google Maps açmaq üçün API key verin:\n'
            'flutter run --dart-define=GOOGLE_MAPS_API_KEY=...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
