import 'package:intl/intl.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

String requestStatusLabel(String? status) {
  return switch ((status ?? '').trim()) {
    'processing' => t('request.status.processing'),
    'active' => t('request.status.active'),
    'matched' => t('request.status.matched'),
    'completed' => t('request.status.completed'),
    'cancelled' => t('request.status.cancelled'),
    'expired' => t('request.status.expired'),
    '' => '—',
    _ => status!,
  };
}

/// Still open for replies (not finished / not past TTL).
bool isRequestLive(String? status, String? expiresAt) {
  final s = (status ?? '').trim();
  if (s == 'expired' || s == 'cancelled' || s == 'completed') return false;
  if (expiresAt != null && expiresAt.trim().isNotEmpty) {
    try {
      if (DateTime.parse(expiresAt).toLocal().isBefore(DateTime.now())) {
        return false;
      }
    } catch (_) {}
  }
  return true;
}

String requestLifecycleLabel(String? status, String? expiresAt) {
  return isRequestLive(status, expiresAt)
      ? t('jobs.badge.active')
      : t('jobs.badge.inactive');
}

String? formatIsoDateTime(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  try {
    return DateFormat('d MMM, HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return null;
  }
}

/// Prefer place spoken/parsed in the request; hide reverse-geocoded family GPS.
String? displayRequestPlace(
  Map<String, dynamic>? parsedCriteria,
  String? address,
) {
  if (parsedCriteria != null) {
    final district = (parsedCriteria['district'] as String?)?.trim();
    final city = (parsedCriteria['city'] as String?)?.trim();
    final parts = <String>[
      if (district != null && district.isNotEmpty) district,
      if (city != null && city.isNotEmpty) city,
    ];
    if (parts.isNotEmpty) return parts.join(', ');

    final source = (parsedCriteria['location_source'] as String?)?.trim();
    if (source == 'ai_place' || source == 'ai_place_unresolved') {
      final a = address?.trim();
      if (a != null && a.isNotEmpty) return a;
    }
  }
  return null;
}
