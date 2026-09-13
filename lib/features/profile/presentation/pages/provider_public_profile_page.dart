import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';
import 'package:home_service_app/features/profile/data/models/schedule_slot.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
import 'package:just_audio/just_audio.dart';

class ProviderPublicProfilePage extends StatefulWidget {
  const ProviderPublicProfilePage({
    super.key,
    required this.profileId,
    this.serviceRequestId,
  });

  final int profileId;
  final int? serviceRequestId;

  @override
  State<ProviderPublicProfilePage> createState() =>
      _ProviderPublicProfilePageState();
}

class _ProviderPublicProfilePageState extends State<ProviderPublicProfilePage> {
  ProviderProfileModel? _profile;
  String? _error;
  bool _loading = true;
  bool _connecting = false;
  bool _favoriteBusy = false;
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await getIt<ProfileRepository>().getPublicProfile(widget.profileId);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (p) => setState(() {
        _loading = false;
        _profile = p;
      }),
    );
  }

  Future<void> _connect() async {
    final id = _profile?.id ?? widget.profileId;
    setState(() => _connecting = true);
    final result = await getIt<ChatRepository>().connect(
      providerProfileId: id,
      serviceRequestId: widget.serviceRequestId,
    );
    if (!mounted) return;
    setState(() => _connecting = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (conversation) {
        context.push('/chat/${conversation.id}');
        context.read<AuthCubit>().bootstrap();
      },
    );
  }

  Future<void> _toggleFavorite() async {
    final profile = _profile;
    if (profile == null || _favoriteBusy) return;
    final next = !profile.isFavorite;
    setState(() {
      _favoriteBusy = true;
      _profile = profile.copyWith(isFavorite: next);
    });
    final repo = getIt<ProfileRepository>();
    final result = next
        ? await repo.addFavorite(profile.id)
        : await repo.removeFavorite(profile.id);
    if (!mounted) return;
    setState(() => _favoriteBusy = false);
    result.fold(
      (f) {
        setState(() => _profile = profile.copyWith(isFavorite: !next));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.message)),
        );
      },
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next ? t('favorites.added') : t('favorites.removed'),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAudio(String url) async {
    try {
      if (_playing) {
        await _player.stop();
        setState(() => _playing = false);
        return;
      }
      await _player.setUrl(url);
      setState(() => _playing = true);
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
      if (mounted) setState(() => _playing = false);
    } catch (_) {
      if (mounted) {
        setState(() => _playing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('audio.play_failed'))),
        );
      }
    }
  }

  String _displayName(ProviderProfileModel p) {
    final name = p.userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (p.title?.isNotEmpty == true) return p.title!;
    if (p.categoryLabels.isNotEmpty) return p.categoryLabels.first;
    return t('match.provider_fallback');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canConnect = context.watch<AuthCubit>().state.user?.isClient == true;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(t('provider.profile_title')),
        backgroundColor: AppColors.canvas,
        actions: [
          if (canConnect && _profile != null)
            IconButton(
              tooltip: _profile!.isFavorite
                  ? t('favorites.toggle_remove')
                  : t('favorites.toggle_add'),
              onPressed: _favoriteBusy ? null : _toggleFavorite,
              icon: Icon(
                _profile!.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                color: _profile!.isFavorite
                    ? AppColors.secondary
                    : AppColors.primary,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: Text(t('common.retry'))),
                      ],
                    ),
                  ),
                )
              : _profile == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            children: [
                              Text(
                                _displayName(_profile!),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (_profile!.title?.isNotEmpty == true &&
                                  _profile!.title != _displayName(_profile!)) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _profile!.title!,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ..._profile!.categoryLabels.map(
                                    (n) => _Chip(label: n),
                                  ),
                                  if (_profile!.isVerified)
                                    _Chip(
                                      label: t('profiles.badge.verified'),
                                      accent: AppColors.secondary,
                                    ),
                                  if (_profile!.isVip)
                                    _Chip(
                                      label: t('profiles.badge.vip'),
                                      accent: AppColors.gold,
                                    ),
                                  if (_profile!.ratingCount > 0)
                                    _Chip(
                                      label:
                                          '★ ${_profile!.ratingAvg.toStringAsFixed(1)} (${_profile!.ratingCount})',
                                    ),
                                ],
                              ),
                              if (_profile!.district != null ||
                                  _profile!.city != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  [
                                    _profile!.district,
                                    _profile!.city,
                                  ].whereType<String>().join(', '),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                              if (_profile!.bio?.isNotEmpty == true) ...[
                                const SizedBox(height: 18),
                                Text(
                                  t('provider.about'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _profile!.bio!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                              if (_profile!.audioIntroUrl != null) ...[
                                const SizedBox(height: 18),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _toggleAudio(_profile!.audioIntroUrl!),
                                  icon: Icon(
                                    _playing ? Icons.stop : Icons.play_arrow,
                                  ),
                                  label: Text(
                                    _playing
                                        ? t('provider.stop_intro')
                                        : t('provider.play_intro'),
                                  ),
                                ),
                              ],
                              if (_profile!.schedules
                                  .any((s) => s.isAvailable)) ...[
                                const SizedBox(height: 22),
                                Text(
                                  t('schedule.title'),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _ScheduleSummary(slots: _profile!.schedules),
                              ],
                            ],
                          ),
                        ),
                        if (canConnect)
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (context.watch<AuthCubit>().state.user?.connectQuota != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        context
                                            .watch<AuthCubit>()
                                            .state
                                            .user!
                                            .connectQuota!
                                            .hintLabel(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ElevatedButton(
                                    onPressed: _connecting ? null : _connect,
                                    child: Text(
                                      _connecting
                                          ? t('match.connecting')
                                          : t('match.connect'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({required this.slots});

  final List<ScheduleSlot> slots;

  @override
  Widget build(BuildContext context) {
    final byDay = <int, Set<String>>{};
    for (final s in slots.where((s) => s.isAvailable)) {
      byDay.putIfAbsent(s.dayOfWeek, () => {}).add(s.timeSlot);
    }
    final days = byDay.keys.toList()..sort();
    if (days.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
            _ScheduleDayRow(
              dayLabel: WeekDays.label(days[i]),
              striped: i.isOdd,
              activeSlots: [
                for (final slot in TimeSlots.all)
                  if (byDay[days[i]]!.contains(slot)) slot,
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleDayRow extends StatelessWidget {
  const _ScheduleDayRow({
    required this.dayLabel,
    required this.activeSlots,
    required this.striped,
  });

  final String dayLabel;
  final List<String> activeSlots;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: striped ? AppColors.peachRow : AppColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              dayLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: -0.2,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final slot in activeSlots)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      TimeSlots.labelFull(slot),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
              ],
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
