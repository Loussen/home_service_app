import 'package:flutter/material.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';

class SearchableCategoryPicker extends StatefulWidget {
  const SearchableCategoryPicker({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
    this.embedded = false,
    this.label = '',
    this.max = 0,
  });

  final List<CategoryModel> categories;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final bool embedded;
  final String label;
  final int max;

  @override
  State<SearchableCategoryPicker> createState() =>
      _SearchableCategoryPickerState();
}

class _SearchableCategoryPickerState extends State<SearchableCategoryPicker> {
  final _query = TextEditingController();

  int get _max =>
      widget.max > 0
          ? widget.max
          : AppRemoteConfig.instance.config.maxCategoryTags;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<(CategoryModel, int, String)> get _all =>
      CategoryModel.flatten(widget.categories);

  List<(CategoryModel, int, String)> _filter(String q) => _all
      .where((e) => CategoryModel.matchesQuery(e.$1, e.$3, q))
      .toList();

  String _pathFor(int id) {
    for (final e in _all) {
      if (e.$1.id == id) return e.$3;
    }
    return '';
  }

  void _toggle(int id, [void Function(void Function())? setModal]) {
    CategoryModel? cat;
    for (final e in _all) {
      if (e.$1.id == id) cat = e.$1;
    }
    if (cat != null && cat.hasChildren) return;

    final next = List<int>.from(widget.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (next.length >= _max) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('category.max_reached', params: {'max': '$_max'})),
          ),
        );
        return;
      }
      next.add(id);
    }
    widget.onChanged(next);
    setModal?.call(() {});
    if (mounted) setState(() {});
  }

  Future<void> _openSheet() async {
    _query.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final items = _filter(_query.text);
            return SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      t('category.selected_count', params: {
                        'count': '${widget.selectedIds.length}',
                        'max': '$_max',
                      }),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: t('category.search_hint'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (_) => setModal(() {}),
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? Center(child: Text(t('category.not_found')))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) => _CategoryTile(
                              item: items[i],
                              selectedIds: widget.selectedIds,
                              onTap: (id) => _toggle(id, setModal),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(t('category.done')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chips = widget.selectedIds.map((id) {
      final label = _pathFor(id);
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: InputChip(
          label: Text(label.isEmpty ? '#$id' : label.split(' → ').last),
          selected: true,
          showCheckmark: true,
          backgroundColor: AppColors.primary,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          deleteIconColor: Colors.white,
          side: BorderSide.none,
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          onDeleted: () => _toggle(id),
        ),
      );
    }).toList();

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('category.leaf_hint', params: {'max': '$_max'}),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Wrap(children: chips),
          const SizedBox(height: 8),
          TextField(
            controller: _query,
            decoration: InputDecoration(
              hintText: t('category.search_tap'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filter(_query.text).length,
              itemBuilder: (_, i) => _CategoryTile(
                item: _filter(_query.text)[i],
                selectedIds: widget.selectedIds,
                onTap: _toggle,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.isEmpty ? t('category.label') : widget.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          children: [
            ...chips,
            if (widget.selectedIds.length < _max)
              ActionChip(
                avatar: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(t('category.add')),
                labelStyle: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                backgroundColor: Colors.white,
                color: const WidgetStatePropertyAll(Colors.white),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                onPressed: _openSheet,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          t('category.selected_count', params: {
            'count': '${widget.selectedIds.length}',
            'max': '$_max',
          }),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.selectedIds,
    required this.onTap,
  });

  final (CategoryModel, int, String) item;
  final List<int> selectedIds;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cat = item.$1;
    final depth = item.$2;
    final path = item.$3;
    final selected = selectedIds.contains(cat.id);
    final isGroup = cat.hasChildren;

    return Padding(
      padding: EdgeInsets.fromLTRB(8 + depth * 8.0, 0, 8, 8),
      child: Material(
        color: isGroup
            ? Colors.transparent
            : (selected ? AppColors.primary : AppColors.skySoft),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: isGroup ? null : () => onTap(cat.id),
          dense: isGroup,
          title: Text(
            cat.nameAz,
            style: TextStyle(
              fontWeight: isGroup ? FontWeight.w800 : FontWeight.w700,
              color: isGroup
                  ? AppColors.muted
                  : (selected ? Colors.white : AppColors.ink),
            ),
          ),
          subtitle: !isGroup && depth > 0
              ? Text(
                  path,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white70 : AppColors.muted,
                  ),
                )
              : null,
          trailing: isGroup
              ? null
              : Icon(
                  selected ? Icons.check_circle : Icons.add_circle_outline,
                  color: selected ? Colors.white : AppColors.primary,
                ),
        ),
      ),
    );
  }
}
