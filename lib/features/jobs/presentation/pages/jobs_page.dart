import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/home/presentation/widgets/profile_completeness_banner.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';
import 'package:home_service_app/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:home_service_app/features/jobs/presentation/cubit/jobs_state.dart';
import 'package:home_service_app/features/jobs/presentation/widgets/job_detail_sheet.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JobsCubit>()..load(),
      child: const _JobsView(),
    );
  }
}

class _JobsView extends StatelessWidget {
  const _JobsView();

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
                },
                builder: (context, state) {
                  if (state.loading && state.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          t('jobs.empty'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
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
                  if (job.address != null) _chip(job.address!),
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
