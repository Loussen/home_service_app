import 'package:flutter/material.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onConnect,
    this.connecting = false,
    this.selected = false,
  });

  final MatchModel match;
  final VoidCallback? onConnect;
  final bool connecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = match.provider;
    final theme = Theme.of(context);
    final score = match.matchScore.round();
    final name = p?.userName?.trim();
    final title = (name != null && name.isNotEmpty)
        ? name
        : (p?.title?.isNotEmpty == true
            ? p!.title!
            : (p?.categoryLabels.isNotEmpty == true
                ? p!.categoryLabels.first
                : t('match.provider_fallback')));

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      elevation: selected ? 2 : 1,
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
                    color: AppColors.peach,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t('match.score', params: {'score': '$score'}),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (match.reasons.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: match.reasons
                    .map((r) => _Chip(label: r.label))
                    .toList(),
              ),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...?p?.categoryLabels.map((n) => _Chip(label: n)),
                if (p?.isVerified == true) _Chip(label: t('profiles.badge.verified')),
                if (p?.isVip == true) _Chip(label: t('profiles.badge.vip')),
                if (match.reasons.isEmpty)
                  _Chip(label: '${match.distanceKm.toStringAsFixed(1)} km'),
                if (p?.ratingCount != null && p!.ratingCount > 0)
                  _Chip(label: '★ ${p.ratingAvg.toStringAsFixed(1)}'),
              ],
            ),
            if (match.mergedProfileCount > 1 &&
                p?.title != null &&
                p!.title!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                p.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
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
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (match.matchScore / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: connecting || onConnect == null ? null : onConnect,
                child: Text(
                  connecting ? t('match.connecting') : t('match.connect'),
                ),
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
