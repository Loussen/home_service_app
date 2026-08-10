import 'package:flutter/material.dart';
import 'package:home_service_app/features/profile/data/models/schedule_slot.dart';

class ScheduleMatrix extends StatelessWidget {
  const ScheduleMatrix({
    super.key,
    required this.values,
    required this.onToggle,
  });

  final Map<String, bool> values;
  final void Function(int day, String slot) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('İş cədvəli', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Uyğun vaxtları seçin (yaşıl = mövcud)',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(52),
            border: TableBorder.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              TableRow(
                children: [
                  const _HeaderCell(''),
                  for (final day in WeekDays.labels.entries)
                    _HeaderCell(day.value),
                ],
              ),
              for (final slot in TimeSlots.all)
                TableRow(
                  children: [
                    _HeaderCell(TimeSlots.labelAz(slot), small: true),
                    for (var day = 1; day <= 7; day++)
                      _SlotCell(
                        active: values['${day}_$slot'] ?? false,
                        onTap: () => onToggle(day, slot),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SlotCell extends StatelessWidget {
  const _SlotCell({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        color: active ? primary.withValues(alpha: 0.2) : Colors.transparent,
        alignment: Alignment.center,
        child: Icon(
          active ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: active ? primary : Colors.grey,
        ),
      ),
    );
  }
}
