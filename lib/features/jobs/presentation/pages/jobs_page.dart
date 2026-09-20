import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/utils/request_status.dart';
import 'package:home_service_app/features/home/presentation/widgets/profile_completeness_banner.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';
import 'package:home_service_app/features/jobs/jobs_inbox_signal.dart';
import 'package:home_service_app/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:home_service_app/features/jobs/presentation/cubit/jobs_state.dart';
import 'package:home_service_app/features/jobs/presentation/widgets/job_detail_sheet.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JobsCubit>()..load()..startPolling(),
      child: const _JobsView(),
    );
  }
}

class _JobsView extends StatefulWidget {
  const _JobsView();

  @override
  State<_JobsView> createState() => _JobsViewState();
}

class _JobsViewState extends State<_JobsView> with WidgetsBindingObserver {
  StreamSubscription<void>? _inboxSub;
  bool _openingPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inboxSub = JobsInboxSignal.stream.listen((_) async {
      if (!mounted) return;
      await context.read<JobsCubit>().refreshQuiet();
      if (mounted) _tryOpenPendingJob();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryOpenPendingJob();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<JobsCubit>().refreshQuiet().then((_) {
        if (mounted) _tryOpenPendingJob();
      });
    }
  }

  @override
  void dispose() {
    _inboxSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  IncomingJobModel? _findJob(
    List<IncomingJobModel> items,
    JobsOpenTarget target,
  ) {
    if (target.matchId != null && target.matchId! > 0) {
      for (final job in items) {
        if (job.matchId == target.matchId) return job;
      }
    }
    if (target.requestId != null && target.requestId! > 0) {
      for (final job in items) {
        if (job.requestId == target.requestId) return job;
      }
    }
    return null;
  }

  void _tryOpenPendingJob() {
    if (!mounted || _openingPending) return;
    final pending = JobsInboxSignal.peekPending();
    if (pending == null || !pending.hasTarget) return;
    final cubit = context.read<JobsCubit>();
    if (cubit.state.loading) return;
    final job = _findJob(cubit.state.items, pending);
    if (job == null) return;
    JobsInboxSignal.clearPending();
    _openingPending = true;
    final busy = cubit.state.replyingId == job.matchId;
    _openDetail(context, job: job, busy: busy).whenComplete(() {
      _openingPending = false;
    });
  }

  Future<void> _openDetail(
    BuildContext context, {
    required IncomingJobModel job,
    required bool busy,
  }) {
    return showJobDetailSheet(
      context,
      job: job,
      busy: busy,
      onReply: () async {
        final conv = await context.read<JobsCubit>().reply(job);
        if (conv != null && context.mounted) {
          context.push('/chat/${conv.id}');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                t('jobs.title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                t('jobs.subtitle'),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
            const ProfileCompletenessBanner(),
            const SizedBox(height: 8),
            Expanded(
              child: BlocConsumer<JobsCubit, JobsState>(
                listener: (context, state) {
                  if (state.message != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message!)),
                    );
                  }
                  if (!state.loading) {
                    _tryOpenPendingJob();
                  }
                },
                builder: (context, state) {
                  if (state.loading && state.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.items.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => context.read<JobsCubit>().load(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(32),
                        children: [
                          const SizedBox(height: 80),
                          Text(
                            t('jobs.empty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => context.read<JobsCubit>().load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final job = state.items[index];
                        final busy = state.replyingId == job.matchId;
                        return _JobCard(
                          job: job,
                          busy: busy,
                          onOpen: () => _openDetail(
                            context,
                            job: job,
                            busy: busy,
                          ),
                          onReply: () async {
                            final conv =
                                await context.read<JobsCubit>().reply(job);
                            if (conv != null && context.mounted) {
                              context.push('/chat/${conv.id}');
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onOpen,
    required this.onReply,
    required this.busy,
  });

  final IncomingJobModel job;
  final VoidCallback onOpen;
  final VoidCallback onReply;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.clientName?.isNotEmpty == true
                          ? job.clientName!
                          : t('jobs.client_fallback'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (job.requestStatus != null &&
                      job.requestStatus!.isNotEmpty) ...[
                    _statusChip(requestStatusLabel(job.requestStatus)),
                    const SizedBox(width: 6),
                    _lifecycleChip(
                      requestLifecycleLabel(
                        job.requestStatus,
                        job.expiresAt,
                      ),
                      live: isRequestLive(job.requestStatus, job.expiresAt),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (job.hasAudio) ...[
                    const Icon(
                      Icons.mic_none_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                  ],
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
              if (job.transcribedText != null) ...[
                const SizedBox(height: 8),
                Text(
                  job.transcribedText!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.3),
                ),
              ],
              Builder(
                builder: (_) {
                  final created = formatIsoDateTime(job.createdAt);
                  final expires = formatIsoDateTime(job.expiresAt);
                  if (created == null && expires == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (created != null)
                          Text(
                            t('jobs.created_at', params: {'when': created}),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        if (expires != null) ...[
                          if (created != null) const SizedBox(height: 2),
                          Text(
                            t('jobs.expires_at', params: {'when': expires}),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (job.reasons.isNotEmpty)
                    ...job.reasons.map((r) => _chip(r.label))
                  else ...[
                    if (job.categoryName != null) _chip(job.categoryName!),
                    _chip('${job.distanceKm.toStringAsFixed(1)} km'),
                  ],
                  if (job.serviceWhenLabel != null)
                    _chip(
                      t(
                        'jobs.when',
                        params: {'when': job.serviceWhenLabel!},
                      ),
                    ),
                  if (job.isUrgent) _chip(t('search.urgent_title')),
                  if (job.displayPlace != null) _chip(job.displayPlace!),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t('jobs.open_detail'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : onReply,
                  child: Text(busy ? t('jobs.reply_opening') : t('jobs.reply')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _lifecycleChip(String label, {required bool live}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: live ? const Color(0xFFE8F3EA) : AppColors.parchment,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: live ? AppColors.published : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: live ? AppColors.published : AppColors.muted,
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
