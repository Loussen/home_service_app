import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';

Future<void> showReviewComposer(
  BuildContext context, {
  required Future<bool> Function({required int rating, String? comment}) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReviewComposerSheet(onSubmit: onSubmit),
  );
}

class _ReviewComposerSheet extends StatefulWidget {
  const _ReviewComposerSheet({required this.onSubmit});

  final Future<bool> Function({required int rating, String? comment}) onSubmit;

  @override
  State<_ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<_ReviewComposerSheet> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('review.stars_required'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await widget.onSubmit(
        rating: _rating,
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
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
            t('review.compose_title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: _busy ? null : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            enabled: !_busy,
            decoration: InputDecoration(labelText: t('review.comment_label')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? t('review.sending') : t('review.send')),
          ),
        ],
      ),
    );
  }
}
