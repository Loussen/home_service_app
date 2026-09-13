import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';

Future<void> showJobDetailSheet(
  BuildContext context, {
  required IncomingJobModel job,
  required bool busy,
  required VoidCallback onReply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _JobDetailSheet(
      job: job,
      busy: busy,
      onReply: onReply,
    ),
  );
}

class _JobDetailSheet extends StatefulWidget {
  const _JobDetailSheet({
    required this.job,
    required this.busy,
    required this.onReply,
  });

  final IncomingJobModel job;
  final bool busy;
  final VoidCallback onReply;

  @override
  State<_JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<_JobDetailSheet> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loadingAudio = false;

  IncomingJobModel get job => widget.job;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final url = job.audioUrl;
    if (url == null || url.isEmpty) return;
    try {
      if (_playing) {
        await _player.stop();
        if (mounted) setState(() => _playing = false);
        return;
      }
      setState(() => _loadingAudio = true);
      await _player.setUrl(url);
      if (!mounted) return;
      setState(() {
        _loadingAudio = false;
        _playing = true;
      });
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
      if (mounted) setState(() => _playing = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingAudio = false;
        _playing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('audio.play_failed'))),
      );
    }
  }

  String? _formatIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final client = job.clientName?.trim().isNotEmpty == true
        ? job.clientName!
        : t('jobs.client_fallback');

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    t('jobs.detail_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.peach,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${job.matchScore.round()}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              client,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (job.transcribedText?.trim().isNotEmpty == true) ...[
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
                        job.transcribedText!,
                        style: const TextStyle(height: 1.4, fontSize: 16),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (job.hasAudio) ...[
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _loadingAudio ? null : _toggleAudio,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.peach,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _loadingAudio
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          _playing
                                              ? Icons.stop_rounded
                                              : Icons.play_arrow_rounded,
                                          color: AppColors.primary,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _playing
                                            ? t('jobs.audio_stop')
                                            : t('jobs.audio_play'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        t('jobs.audio_hint'),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (job.categoryName != null)
                          _DetailChip(label: job.categoryName!),
                        _DetailChip(
                          label:
                              '${job.distanceKm.toStringAsFixed(1)} km',
                        ),
                        if (job.serviceWhenLabel != null)
                          _DetailChip(
                            label: t(
                              'jobs.when',
                              params: {'when': job.serviceWhenLabel!},
                            ),
                          ),
                        if (job.isUrgent)
                          _DetailChip(
                            label: t('search.urgent_title'),
                            accent: true,
                          ),
                        if (job.address != null)
                          _DetailChip(label: job.address!),
                        if (_formatIso(job.createdAt) != null)
                          _DetailChip(
                            label: t(
                              'jobs.created_at',
                              params: {'when': _formatIso(job.createdAt)!},
                            ),
                          ),
                        if (_formatIso(job.expiresAt) != null)
                          _DetailChip(
                            label: t(
                              'jobs.expires_at',
                              params: {'when': _formatIso(job.expiresAt)!},
                            ),
                          ),
                      ],
                    ),
                    if (job.reasons.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        t('jobs.detail_match'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...job.reasons.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.label,
                                  style: const TextStyle(height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: widget.busy
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onReply();
                    },
              child: Text(
                widget.busy ? t('jobs.reply_opening') : t('jobs.reply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? AppColors.peach : Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent ? AppColors.primary : AppColors.ink,
        ),
      ),
    );
  }
}
