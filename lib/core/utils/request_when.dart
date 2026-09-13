import 'package:intl/intl.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

/// Formats desired service time from [parsed_criteria].
String? formatRequestServiceWhen(Map<String, dynamic>? criteria) {
  if (criteria == null || criteria.isEmpty) return null;

  final scheduledRaw = criteria['scheduled_at'] ?? criteria['user_scheduled_at'];
  if (scheduledRaw is String && scheduledRaw.trim().isNotEmpty) {
    try {
      final dt = DateTime.parse(scheduledRaw).toLocal();
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {}
  }

  final hhmm = criteria['time_hhmm']?.toString().trim();
  final slot = criteria['time_slot']?.toString().trim();
  final slotLabel =
      (slot != null && slot.isNotEmpty) ? t('web.schedule.$slot') : null;

  String? when;
  if (hhmm != null && hhmm.isNotEmpty) {
    when = slotLabel != null ? '$hhmm · $slotLabel' : hhmm;
  } else if (slotLabel != null) {
    when = slotLabel;
  }

  final duration = criteria['duration_hours'];
  if (duration != null) {
    final hours = duration is num
        ? duration
        : num.tryParse(duration.toString());
    if (hours != null && hours > 0) {
      final durLabel = t('requests.duration_hours', params: {
        'hours': hours % 1 == 0
            ? hours.toInt().toString()
            : hours.toString(),
      });
      when = when == null ? durLabel : '$when · $durLabel';
    }
  }

  return when;
}
