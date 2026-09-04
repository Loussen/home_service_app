import 'package:flutter/material.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('schedule.title'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          t('schedule.hint'),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(36),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  const SizedBox.shrink(),
                  for (final slot in TimeSlots.all)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      child: Text(
                        TimeSlots.labelShort(slot),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
              for (var i = 0; i < WeekDays.count; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i.isEven ? AppColors.peachRow : Colors.white,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        WeekDays.label(i + 1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    for (final slot in TimeSlots.all)
                      _DotCell(
                        active: values['${i + 1}_$slot'] ?? false,
                        onTap: () => onToggle(i + 1, slot),
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

class _DotCell extends StatelessWidget {
  const _DotCell({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: active ? AppColors.primary : AppColors.divider,
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
