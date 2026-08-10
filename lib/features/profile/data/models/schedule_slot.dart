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

  static String labelAz(String slot) => switch (slot) {
        'morning' => 'Səhər',
        'afternoon' => 'Günorta',
        'evening' => 'Axşam',
        'night' => 'Gecə',
        _ => slot,
      };
}

class WeekDays {
  static const labels = {
    1: 'B.e',
    2: 'Ç.a',
    3: 'Ç',
    4: 'C.a',
    5: 'C',
    6: 'Ş',
    7: 'B',
  };
}
