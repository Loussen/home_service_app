import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

const reportReasons = [
  'spam',
  'harassment',
  'fraud',
  'inappropriate',
  'other',
];

Future<void> showReportComposer(
  BuildContext context, {
  required Future<bool> Function({
    required String reason,
    String? details,
  }) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReportComposerSheet(onSubmit: onSubmit),
  );
}

class _ReportComposerSheet extends StatefulWidget {
  const _ReportComposerSheet({required this.onSubmit});

  final Future<bool> Function({
    required String reason,
    String? details,
  }) onSubmit;

  @override
  State<_ReportComposerSheet> createState() => _ReportComposerSheetState();
}

class _ReportComposerSheetState extends State<_ReportComposerSheet> {
  final _details = TextEditingController();
  String? _reason;
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _reasonLabel(String reason) => t('report.reason.$reason');

  Future<void> _send() async {
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('report.reason_required'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await widget.onSubmit(
        reason: _reason!,
        details: _details.text.trim().isEmpty ? null : _details.text.trim(),
      );
      if (ok && mounted) Navigator.pop(context);
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
          Text(
            t('report.title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in reportReasons)
                ChoiceChip(
                  label: Text(_reasonLabel(reason)),
                  selected: _reason == reason,
                  selectedColor: AppColors.peach,
                  onSelected: _busy
                      ? null
                      : (selected) => setState(() {
                            _reason = selected ? reason : null;
                          }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            maxLines: 3,
            enabled: !_busy,
            decoration: InputDecoration(labelText: t('report.details_label')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? t('report.sending') : t('report.send')),
          ),
        ],
      ),
    );
  }
}
