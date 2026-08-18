import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:intl/intl.dart';

Future<void> showOfferComposer(
  BuildContext context, {
  required Future<void> Function({
    required DateTime scheduledAt,
    required double priceAzn,
    double? durationHours,
    String? note,
  }) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _OfferComposerSheet(onSubmit: onSubmit),
  );
}

class _OfferComposerSheet extends StatefulWidget {
  const _OfferComposerSheet({required this.onSubmit});

  final Future<void> Function({
    required DateTime scheduledAt,
    required double priceAzn,
    double? durationHours,
    String? note,
  }) onSubmit;

  @override
  State<_OfferComposerSheet> createState() => _OfferComposerSheetState();
}

class _OfferComposerSheetState extends State<_OfferComposerSheet> {
  final _price = TextEditingController();
  final _hours = TextEditingController();
  final _note = TextEditingController();
  DateTime _when = DateTime.now().add(const Duration(hours: 2));
  bool _busy = false;

  @override
  void dispose() {
    _price.dispose();
    _hours.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null || !mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _send() async {
    final price = double.tryParse(_price.text.replaceAll(',', '.'));
    if (price == null || price < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('offer.price_required'))),
      );
      return;
    }
    if (!_when.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('offer.time_future'))),
      );
      return;
    }
    final hours = _hours.text.trim().isEmpty
        ? null
        : double.tryParse(_hours.text.replaceAll(',', '.'));
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        scheduledAt: _when,
        priceAzn: price,
        durationHours: hours,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t('offer.compose_title'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: AppColors.primary),
            title: Text(DateFormat('d MMM yyyy, HH:mm').format(_when)),
            subtitle: Text(t('offer.pick_time')),
            onTap: _busy ? null : _pickDate,
          ),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: t('offer.price_label')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: t('offer.hours_label')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: InputDecoration(labelText: t('offer.note_label')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? t('offer.sending') : t('offer.send')),
          ),
        ],
      ),
    );
  }
}
