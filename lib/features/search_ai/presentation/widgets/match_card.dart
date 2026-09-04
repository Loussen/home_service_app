import 'package:flutter/material.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onConnect,
    this.onOpenProfile,
    this.connecting = false,
    this.selected = false,
  });

  final MatchModel match;
  final VoidCallback? onConnect;
  final VoidCallback? onOpenProfile;
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenProfile,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: selected ? 0.08 : 0.04),
                blurRadius: selected ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t('match.score', params: {'score': '$score'}),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (match.reasons.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: match.reasons.map((r) {
                    if (r.key == 'match.reason.bump') {
                      return Tooltip(
                        message: t(
                          'match.reason.bump_hint',
                          params: r.params.isEmpty ? null : r.params,
                        ),
                        child: _BumpBadge(
                          label: t(
                            'profiles.bump_remaining',
                            params: r.params.isEmpty ? null : r.params,
                          ),
                        ),
                      );
                    }
                    return _Chip(label: r.label);
                  }).toList(),
                ),
                const SizedBox(height: 6),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ...?p?.categoryLabels.map((n) => _Chip(label: n)),
                  if (p?.isVerified == true)
                    _Chip(
                      label: t('profiles.badge.verified'),
                      accent: AppColors.secondary,
                    ),
                  if (p?.isVip == true)
                    _Chip(
                      label: t('profiles.badge.vip'),
                      accent: AppColors.gold,
                    ),
                  if (p?.bumpActive == true &&
                      !match.reasons.any((r) => r.key == 'match.reason.bump'))
                    Tooltip(
                      message: t('match.reason.bump_hint', params: {
                        'hours': '${p!.bumpRemainingHours}',
                      }),
                      child: _BumpBadge(
                        label: t('profiles.bump_remaining', params: {
                          'hours': '${p.bumpRemainingHours}',
                        }),
                      ),
                    ),
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
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (match.matchScore / 100).clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: AppColors.peach,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onOpenProfile != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onOpenProfile,
                        child: Text(t('match.view_profile')),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          connecting || onConnect == null ? null : onConnect,
                      child: Text(
                        connecting
                            ? t('match.connecting')
                            : t('match.connect'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BumpBadge extends StatelessWidget {
  const _BumpBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.north,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (accent ?? AppColors.ink).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ?? AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
