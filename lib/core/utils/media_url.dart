import 'package:home_service_app/app/config/app_config.dart';

/// Turns API relative storage paths into absolute URLs for [NetworkImage].
String? resolveMediaUrl(String? path) {
  if (path == null) return null;
  final p = path.trim();
  if (p.isEmpty) return null;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;

  final origin = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  if (p.startsWith('/storage/') || p.startsWith('storage/')) {
    final normalized = p.startsWith('/') ? p : '/$p';
    return '$origin$normalized';
  }
  final cleaned = p.replaceFirst(RegExp(r'^/+'), '');
  return '$origin/storage/$cleaned';
}
