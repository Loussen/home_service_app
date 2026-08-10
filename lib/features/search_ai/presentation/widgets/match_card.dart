import 'package:flutter/material.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final p = match.provider;
    final theme = Theme.of(context);
    final score = match.matchScore.round();
    final title = p?.title?.isNotEmpty == true
        ? p!.title!
        : (p?.category?.nameAz ?? 'Provider');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score% match',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (p?.category != null)
                  _Chip(label: p!.category!.nameAz),
                if (p?.isVerified == true) const _Chip(label: 'Verified'),
                if (p?.isVip == true) const _Chip(label: 'VIP'),
                _Chip(label: '${match.distanceKm.toStringAsFixed(1)} km'),
                if (p?.ratingCount != null && p!.ratingCount > 0)
                  _Chip(label: '★ ${p.ratingAvg.toStringAsFixed(1)}'),
              ],
            ),
            if (p?.district != null || p?.city != null) ...[
              const SizedBox(height: 8),
              Text(
                [p?.district, p?.city].whereType<String>().join(', '),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (p?.bio?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                p!.bio!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (match.matchScore / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
