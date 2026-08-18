import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/verification/data/models/verification_document_model.dart';
import 'package:home_service_app/features/verification/presentation/cubit/verification_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<VerificationCubit>()..load(),
      child: const _VerificationView(),
    );
  }
}

class _VerificationView extends StatelessWidget {
  const _VerificationView();

  Future<void> _pickAndUpload(BuildContext context) async {
    final cubit = context.read<VerificationCubit>();
    if (!cubit.state.canUpload || cubit.state.uploading) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (file == null || !context.mounted) return;
    await cubit.upload(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationCubit, VerificationState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final latest = state.latest;

        return Scaffold(
          appBar: AppBar(title: Text(t('verify.title'))),
          body: state.loading && state.documents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Text(
                      t('verify.subtitle'),
                      style: const TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    if (latest != null) _StatusCard(document: latest),
                    if (latest == null && !state.loading)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(t('verify.empty')),
                      ),
                    const SizedBox(height: 20),
                    if (state.canUpload)
                      ElevatedButton.icon(
                        onPressed: state.uploading
                            ? null
                            : () => _pickAndUpload(context),
                        icon: state.uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          state.uploading
                              ? t('verify.uploading')
                              : t('verify.upload'),
                        ),
                      )
                    else if (latest?.isPending == true)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.skySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          t('verify.pending_hint'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (state.documents.length > 1) ...[
                      const SizedBox(height: 28),
                      Text(
                        t('verify.history'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...state.documents.skip(1).map(
                            (d) => _HistoryTile(document: d),
                          ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.document});

  final VerificationDocumentModel document;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (document.status) {
      'approved' => (
          t('verify.status.approved'),
          const Color(0xFFE8F6EA),
          AppColors.published,
        ),
      'rejected' => (
          t('verify.status.rejected'),
          AppColors.peach,
          AppColors.primary,
        ),
      _ => (
          t('verify.status.pending'),
          AppColors.skySoft,
          AppColors.sky,
        ),
    };
    final when = document.createdAt != null
        ? DateFormat('d MMM yyyy, HH:mm').format(document.createdAt!.toLocal())
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t('verify.latest'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          if (when != null) ...[
            const SizedBox(height: 8),
            Text(when, style: const TextStyle(color: AppColors.muted)),
          ],
          if (document.adminNote != null &&
              document.adminNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              document.adminNote!,
              style: const TextStyle(height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.document});

  final VerificationDocumentModel document;

  @override
  Widget build(BuildContext context) {
    final when = document.createdAt != null
        ? DateFormat('d MMM yyyy').format(document.createdAt!.toLocal())
        : '—';
    final status = switch (document.status) {
      'approved' => t('verify.status.approved'),
      'rejected' => t('verify.status.rejected'),
      _ => t('verify.status.pending'),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$when · $status'),
      subtitle: document.adminNote != null && document.adminNote!.isNotEmpty
          ? Text(document.adminNote!)
          : null,
    );
  }
}
