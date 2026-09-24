import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/utils/request_status.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/request_audio_player.dart';

Future<void> showChatRequestSheet(
  BuildContext context, {
  required ConversationRequestSummary request,
  bool canOpenFull = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ChatRequestSheet(
      request: request,
      canOpenFull: canOpenFull,
    ),
  );
}

class _ChatRequestSheet extends StatelessWidget {
  const _ChatRequestSheet({
    required this.request,
    required this.canOpenFull,
  });

  final ConversationRequestSummary request;
  final bool canOpenFull;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final created = formatIsoDateTime(request.createdAt);
    final expires = formatIsoDateTime(request.expiresAt);
    final place = request.displayPlace;
    final when = request.whenLabel;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t('chat.request_sheet_title'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (request.status != null && request.status!.isNotEmpty)
                  _pill(requestStatusLabel(request.status)),
                if (request.status != null)
                  _pill(
                    requestLifecycleLabel(request.status, request.expiresAt),
                    live: isRequestLive(request.status, request.expiresAt),
                  ),
                if (request.isUrgent)
                  _pill(t('search.urgent_title'), accent: true),
                if (request.categoryName != null)
                  _pill(request.categoryName!),
              ],
            ),
            const SizedBox(height: 14),
            if (request.transcribedText?.trim().isNotEmpty == true) ...[
              Text(
                t('jobs.detail_request'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                request.transcribedText!,
                style: const TextStyle(height: 1.4, fontSize: 16),
              ),
              const SizedBox(height: 14),
            ],
            if (request.hasAudio) ...[
              RequestAudioPlayer(
                audioUrl: request.audioUrl!,
                playLabelKey: 'jobs.audio_play',
                stopLabelKey: 'jobs.audio_stop',
                hintLabelKey: 'jobs.audio_hint',
              ),
              const SizedBox(height: 14),
            ],
            if (when != null || place != null || created != null) ...[
              if (when != null)
                _metaRow(Icons.schedule, t('jobs.when', params: {'when': when})),
              if (place != null)
                _metaRow(Icons.place_outlined, place),
              if (created != null)
                _metaRow(
                  Icons.event_outlined,
                  t('jobs.created_at', params: {'when': created}),
                ),
              if (expires != null)
                _metaRow(
                  Icons.timer_outlined,
                  t('jobs.expires_at', params: {'when': expires}),
                ),
              const SizedBox(height: 8),
            ],
            if (canOpenFull) ...[
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/requests/${request.id}');
                },
                child: Text(t('chat.request_open_full')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, {bool? live, bool accent = false}) {
    final isLifecycle = live != null;
    final isLive = live == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.peach
            : isLifecycle
                ? (isLive ? const Color(0xFFE8F3EA) : AppColors.parchment)
                : AppColors.mist,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent
              ? AppColors.secondary
              : isLifecycle
                  ? (isLive ? AppColors.published : AppColors.divider)
                  : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: accent
              ? AppColors.primary
              : isLifecycle
                  ? (isLive ? AppColors.published : AppColors.muted)
                  : AppColors.primary,
        ),
      ),
    );
  }
}
