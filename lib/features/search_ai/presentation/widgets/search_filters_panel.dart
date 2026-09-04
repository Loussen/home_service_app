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
    final hasLeaves = CategoryModel.flatten(categories)
        .any((e) => e.$1.children.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('search.filter_category'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (!hasLeaves)
          Text(t('search.filters_loading'), style: const TextStyle(color: AppColors.muted))
        else
          _SearchableCategoryField(
            locale: AppRemoteConfig.instance.locale,
            tree: categories,
            selectedCategoryId: selectedCategoryId,
            enabled: enabled,
            onChanged: onCategoryChanged,
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
              _FilterChip(
                label: _slotLabel(slot),
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
            _FilterChip(
              label: t('search.pet_yes'),
              selected: hasPet == true,
              selectedColor: AppColors.peach,
              onSelected: enabled
                  ? (selected) => onHasPetChanged(selected ? true : null)
                  : null,
            ),
            _FilterChip(
              label: t('search.pet_no'),
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
              _FilterChip(
                label: t('search.budget_max', params: {'amount': '$budget'}),
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

/// Soft selected surface + navy label (readable on peach / mist).
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: selectedColor,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      onSelected: onSelected,
    );
  }
}

class _CategoryLeaf {
  const _CategoryLeaf({
    required this.category,
    required this.groupLabel,
  });

  final CategoryModel category;
  final String groupLabel;

  String get name => category.displayName;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final haystack = '$groupLabel $name'.toLowerCase();
    return haystack.contains(query) ||
        CategoryModel.matchesQuery(category, name, query);
  }
}

class _CategoryGroup {
  const _CategoryGroup({required this.label, required this.leaves});

  final String label;
  final List<_CategoryLeaf> leaves;
}

/// Build parent → leaf groups (same walk as web `fillRequestCategorySelect`).
List<_CategoryGroup> _buildCategoryGroups(List<CategoryModel> tree) {
  final order = <String>[];
  final map = <String, List<_CategoryLeaf>>{};
  final other = t('web.categories.other');

  void walk(List<CategoryModel> nodes, String parentLabel) {
    for (final node in nodes) {
      final label = node.displayName;
      if (node.children.isNotEmpty) {
        walk(node.children, label);
        continue;
      }
      final groupName = parentLabel.isEmpty ? other : parentLabel;
      map.putIfAbsent(groupName, () {
        order.add(groupName);
        return <_CategoryLeaf>[];
      }).add(_CategoryLeaf(category: node, groupLabel: groupName));
    }
  }

  walk(tree, '');
  return [
    for (final label in order)
      _CategoryGroup(label: label, leaves: map[label]!),
  ];
}

class _SearchableCategoryField extends StatefulWidget {
  const _SearchableCategoryField({
    required this.locale,
    required this.tree,
    required this.selectedCategoryId,
    required this.enabled,
    required this.onChanged,
  });

  final String locale;
  final List<CategoryModel> tree;
  final int? selectedCategoryId;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  State<_SearchableCategoryField> createState() =>
      _SearchableCategoryFieldState();
}

class _SearchableCategoryFieldState extends State<_SearchableCategoryField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _menuOpen = false;
  /// Immediate pick so blur (before parent rebuild) does not clear the field.
  int? _localSelectedId;
  String? _localSelectedName;
  bool _picking = false;

  List<_CategoryGroup> get _groups => _buildCategoryGroups(widget.tree);

  int? get _effectiveSelectedId =>
      widget.selectedCategoryId ?? _localSelectedId;

  _CategoryLeaf? get _selected {
    final id = _effectiveSelectedId;
    if (id == null) return null;
    for (final g in _groups) {
      for (final leaf in g.leaves) {
        if (leaf.category.id == id) return leaf;
      }
    }
    return null;
  }

  String get _displayName =>
      _selected?.name ?? _localSelectedName ?? '';

  List<_CategoryGroup> get _filtered {
    final q = _controller.text.trim().toLowerCase();
    final out = <_CategoryGroup>[];
    for (final g in _groups) {
      final leaves = g.leaves.where((l) => l.matches(q)).toList();
      if (leaves.isEmpty) continue;
      out.add(_CategoryGroup(label: g.label, leaves: leaves));
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = _displayName;
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      setState(() => _menuOpen = true);
      return;
    }
    // Defer close so option pointer-down can commit first (web mousedown pattern).
    Future.microtask(() {
      if (!mounted || _focus.hasFocus) return;
      if (_picking) return;
      setState(() => _menuOpen = false);
      final name = _displayName;
      if (_controller.text != name) {
        _controller.text = name;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SearchableCategoryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategoryId != null &&
        widget.selectedCategoryId == _localSelectedId) {
      _localSelectedId = null;
      _localSelectedName = null;
    }
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.locale != widget.locale) {
      if (!_focus.hasFocus) {
        _controller.text = _displayName;
      }
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _pick(_CategoryLeaf leaf) {
    if (_picking && _localSelectedId == leaf.category.id) return;
    _picking = true;
    _localSelectedId = leaf.category.id;
    _localSelectedName = leaf.name;
    _controller.text = leaf.name;
    widget.onChanged(leaf.category.id);
    setState(() => _menuOpen = false);
    _focus.unfocus();
    Future.microtask(() {
      if (mounted) _picking = false;
    });
  }

  void _clear() {
    _localSelectedId = null;
    _localSelectedName = null;
    widget.onChanged(null);
    _controller.clear();
    setState(() => _menuOpen = true);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedId = _effectiveSelectedId;
    final showClear = selectedId != null || _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          enabled: widget.enabled,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: t('search.category_search_ph'),
            prefixIcon: const Icon(Icons.search, color: AppColors.muted),
            suffixIcon: showClear
                ? IconButton(
                    tooltip: t('search.clear_filters'),
                    onPressed: widget.enabled ? _clear : null,
                    icon: const Icon(Icons.close),
                  )
                : Icon(
                    _menuOpen ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted,
                  ),
          ),
        ),
        if (_menuOpen) ...[
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            elevation: 1,
            shadowColor: AppColors.primary.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        t('search.category_empty'),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, gi) {
                        final group = filtered[gi];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: gi == 0 ? 0 : 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.parchment,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                group.label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            for (final leaf in group.leaves)
                              _CategoryOptionTile(
                                label: leaf.name,
                                selected: leaf.category.id == selectedId,
                                onSelect: () => _pick(leaf),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryOptionTile extends StatelessWidget {
  const _CategoryOptionTile({
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Material(
        color: selected ? AppColors.peach : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Listener(
          // Commit before TextField blurs and unmounts the menu.
          onPointerDown: (_) => onSelect(),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
