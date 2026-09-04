import 'package:home_service_app/core/remote/app_remote_config.dart';

class ScheduleSlot {
  const ScheduleSlot({
    required this.dayOfWeek,
    required this.timeSlot,
    this.isAvailable = true,
  });

  final int dayOfWeek;
  final String timeSlot;
  final bool isAvailable;

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      dayOfWeek: json['day_of_week'] as int,
      timeSlot: json['time_slot'] as String,
      isAvailable: json['is_available'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'time_slot': timeSlot,
        'is_available': isAvailable,
      };

  ScheduleSlot copyWith({bool? isAvailable}) {
    return ScheduleSlot(
      dayOfWeek: dayOfWeek,
      timeSlot: timeSlot,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class TimeSlots {
  static const all = ['morning', 'afternoon', 'evening', 'night'];

  /// Short labels for the edit matrix header.
  static String labelShort(String slot) => t('web.schedule.${slot}_short');

  /// Full labels for public profile chips.
  static String labelFull(String slot) => t('web.schedule.$slot');
}

class WeekDays {
  static String label(int day) => t('web.schedule.day_$day');

  static const count = 7;
}
