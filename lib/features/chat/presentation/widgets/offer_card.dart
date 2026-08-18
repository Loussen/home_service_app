import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';
import 'package:intl/intl.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.isClient,
    required this.isProvider,
    this.myUserId,
    this.busy = false,
    this.onAccept,
    this.onDecline,
    this.onComplete,
    this.onCancel,
    this.onReview,
  });

  final ChatOfferModel offer;
  final bool isClient;
  final bool isProvider;
  final int? myUserId;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM, HH:mm').format(offer.scheduledAt.toLocal());
    final price = '${offer.priceAzn.toStringAsFixed(0)} AZN';
    final duration = offer.durationHours == null
        ? null
        : t('offer.duration', params: {
            'hours': offer.durationHours!.toStringAsFixed(
              offer.durationHours! % 1 == 0 ? 0 : 1,
            ),
          });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                t('offer.title'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              _StatusBadge(status: offer.status),
            ],
          ),
          const SizedBox(height: 10),
          _Row(icon: Icons.event, label: when),
          if (duration != null) ...[
            const SizedBox(height: 6),
            _Row(icon: Icons.schedule, label: duration),
          ],
          const SizedBox(height: 6),
          _Row(icon: Icons.payments_outlined, label: price),
          if (offer.note != null && offer.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(offer.note!, style: const TextStyle(color: AppColors.muted)),
          ],
          if (_hasActions) ...[
            const SizedBox(height: 12),
            if (offer.isPending && isClient)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onDecline,
                      child: Text(t('offer.decline')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : onAccept,
                      child: Text(t('offer.accept')),
                    ),
                  ),
                ],
              ),
            if (offer.isPending && isProvider)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: busy ? null : onCancel,
                  child: Text(t('offer.cancel')),
                ),
              ),
            if (offer.isAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : onComplete,
                  child: Text(t('offer.complete')),
                ),
              ),
          ],
          if (offer.isCompleted) ...[
            const SizedBox(height: 12),
            ..._reviewRows(),
          ],
        ],
      ),
    );
  }

  List<Widget> _reviewRows() {
    final mine = myUserId == null ? null : offer.reviewBy(myUserId!);
    ChatReviewModel? theirs;
    if (myUserId != null) {
      for (final r in offer.reviews) {
        if (r.reviewerId != myUserId) {
          theirs = r;
          break;
        }
      }
    }
    return [
      if (mine != null)
        _ReviewLine(label: t('review.yours'), rating: mine.rating),
      if (theirs != null) ...[
        if (mine != null) const SizedBox(height: 6),
        _ReviewLine(label: t('review.theirs'), rating: theirs.rating),
      ],
      if (mine == null && onReview != null) ...[
        if (theirs != null) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy ? null : onReview,
            child: Text(t('review.write')),
          ),
        ),
      ],
    ];
  }

  bool get _hasActions =>
      (offer.isPending && isClient) ||
      (offer.isPending && isProvider) ||
      offer.isAccepted;
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.rating});

  final String label;
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted)),
        const Spacer(),
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: 16,
            color: AppColors.primary,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'accepted' => (t('offer.status.accepted'), AppColors.skySoft, AppColors.sky),
      'completed' => (t('offer.status.completed'), const Color(0xFFE8F6EA), AppColors.published),
      'declined' => (t('offer.status.declined'), AppColors.peach, AppColors.primary),
      'cancelled' => (t('offer.status.cancelled'), AppColors.peach, AppColors.muted),
      _ => (t('offer.status.pending'), AppColors.cream, const Color(0xFF8A6A12)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
