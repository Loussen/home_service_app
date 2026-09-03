import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:intl/intl.dart';

class SearchFiltersPanel extends StatelessWidget {
  const SearchFiltersPanel({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.scheduledAt,
    required this.timeSlot,
    required this.enabled,
    required this.childAge,
    required this.hasPet,
    required this.budgetMax,
    required this.onCategoryChanged,
    required this.onScheduledAtChanged,
    required this.onTimeSlotChanged,
    required this.onChildAgeChanged,
    required this.onHasPetChanged,
    required this.onBudgetMaxChanged,
  });

  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final DateTime? scheduledAt;
  final String? timeSlot;
  final bool enabled;
  final int? childAge;
  final bool? hasPet;
  final double? budgetMax;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<DateTime?> onScheduledAtChanged;
  final ValueChanged<String?> onTimeSlotChanged;
  final ValueChanged<int?> onChildAgeChanged;
  final ValueChanged<bool?> onHasPetChanged;
  final ValueChanged<double?> onBudgetMaxChanged;

  static const _slots = ['morning', 'afternoon', 'evening', 'night'];
  static const _budgetOptions = [20, 40, 60, 100, 150, 250];

  List<CategoryModel> get _leaves {
    return CategoryModel.flatten(categories)
        .where((e) => e.$1.children.isEmpty)
        .map((e) => e.$1)
        .toList();
  }

  String _slotLabel(String slot) => t('search.slot.$slot');

  Future<void> _pickDateTime(BuildContext context) async {
    final initial = scheduledAt ?? DateTime.now().add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!picked.isAfter(DateTime.now())) return;
    onScheduledAtChanged(picked);
    onTimeSlotChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final leaves = _leaves;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('search.filter_category'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (leaves.isEmpty)
          Text(t('search.filters_loading'), style: const TextStyle(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in leaves)
                ChoiceChip(
                  label: Text(cat.displayName),
                  selected: selectedCategoryId == cat.id,
                  selectedColor: AppColors.peach,
                  onSelected: enabled
                      ? (selected) => onCategoryChanged(
                            selected ? cat.id : null,
                          )
                      : null,
                ),
            ],
          ),
        const SizedBox(height: 16),
        Text(
          t('search.filter_when'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in _slots)
              ChoiceChip(
                label: Text(_slotLabel(slot)),
                selected: timeSlot == slot && scheduledAt == null,
                selectedColor: AppColors.skySoft,
                onSelected: enabled
                    ? (selected) {
                        onTimeSlotChanged(selected ? slot : null);
                        if (selected) onScheduledAtChanged(null);
                      }
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? () => _pickDateTime(context) : null,
                icon: const Icon(Icons.event, size: 18),
                label: Text(
                  scheduledAt == null
                      ? t('search.pick_datetime')
                      : DateFormat('d MMM, HH:mm').format(scheduledAt!.toLocal()),
                ),
              ),
            ),
            if (scheduledAt != null || timeSlot != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: t('search.clear_filters'),
                onPressed: enabled
                    ? () {
                        onScheduledAtChanged(null);
                        onTimeSlotChanged(null);
                      }
                    : null,
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(
          t('search.filter_more'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t('search.child_age'),
                  border: const OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: childAge,
                    hint: Text(t('search.not_selected')),
                    items: List.generate(
                      18,
                      (i) => DropdownMenuItem<int>(
                        value: i,
                        child: Text('$i'),
                      ),
                    ),
                    onChanged: enabled ? onChildAgeChanged : null,
                  ),
                ),
              ),
            ),
            if (childAge != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: t('search.clear_filters'),
                onPressed: enabled ? () => onChildAgeChanged(null) : null,
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(t('search.pet_yes')),
              selected: hasPet == true,
              selectedColor: AppColors.peach,
              onSelected: enabled
                  ? (selected) => onHasPetChanged(selected ? true : null)
                  : null,
            ),
            ChoiceChip(
              label: Text(t('search.pet_no')),
              selected: hasPet == false,
              selectedColor: AppColors.skySoft,
              onSelected: enabled
                  ? (selected) => onHasPetChanged(selected ? false : null)
                  : null,
            ),
            if (hasPet != null)
              ActionChip(
                label: Text(t('search.clear_filters')),
                onPressed: enabled ? () => onHasPetChanged(null) : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final budget in _budgetOptions)
              ChoiceChip(
                label: Text('<= $budget AZN'),
                selected: budgetMax?.round() == budget,
                selectedColor: AppColors.cream,
                onSelected: enabled
                    ? (selected) =>
                        onBudgetMaxChanged(selected ? budget.toDouble() : null)
                    : null,
              ),
            if (budgetMax != null)
              ActionChip(
                label: Text(t('search.clear_filters')),
                onPressed: enabled ? () => onBudgetMaxChanged(null) : null,
              ),
          ],
        ),
      ],
    );
  }
}
