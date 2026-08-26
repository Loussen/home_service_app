import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/config/app_config.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_cubit.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_state.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/match_card.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/matches_map.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/search_location_field.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/search_filters_panel.dart';

class SearchAiPage extends StatelessWidget {
  const SearchAiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchAiCubit>()..init(),
      child: const _SearchAiView(),
    );
  }
}

class _SearchAiView extends StatefulWidget {
  const _SearchAiView();

  @override
  State<_SearchAiView> createState() => _SearchAiViewState();
}

class _SearchAiViewState extends State<_SearchAiView>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  late final AnimationController _micPulse;

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _micPulse.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchAiCubit, SearchAiState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          if (state.message!.contains(t('common.balance_remaining'))) {
            context.read<AuthCubit>().bootstrap();
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<SearchAiCubit>();
        final busy = state.phase == SearchPhase.submitting ||
            state.phase == SearchPhase.processing ||
            state.phase == SearchPhase.locating;

        final remote = AppRemoteConfig.instance;
        final urgentFee = remote.config.fees.urgent;
        final voiceEnabled = remote.flags.voiceSearch;
        final urgentQuota = context.watch<AuthCubit>().state.user?.urgentQuota;
        final canUrgent = urgentQuota?.canUrgent ?? true;
        final urgentKm =
            (urgentQuota?.radiusKm ?? remote.config.urgentRadiusKm).toStringAsFixed(0);
        final urgentHours =
            '${urgentQuota?.hours ?? remote.config.urgentHours}';
        final urgentRemaining =
            '${urgentQuota?.dailyRemaining ?? remote.config.urgentDailyLimit}';

        if (state.isRecording) {
          if (!_micPulse.isAnimating) _micPulse.repeat(reverse: true);
        } else if (_micPulse.isAnimating) {
          _micPulse
            ..stop()
            ..value = 0;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(AppConfig.appName),
            actions: [
              if (state.phase == SearchPhase.results)
                IconButton(
                  onPressed: cubit.reset,
                  icon: const Icon(Icons.refresh),
                  tooltip: t('search.new_request'),
                ),
            ],
          ),
          body: state.phase == SearchPhase.results && state.request != null
              ? _ResultsBody(
                  state: state,
                  onUrgent: cubit.markUrgent,
                  onRefresh: () => cubit.refreshRequest(state.request!.id),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      t('search.headline'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('search.subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    if (voiceEnabled) ...[
                      const SizedBox(height: 28),
                      Center(
                        child: GestureDetector(
                          onTap: busy ? null : cubit.toggleRecording,
                          child: AnimatedBuilder(
                            animation: _micPulse,
                            builder: (context, _) {
                              final pulse = state.isRecording
                                  ? 0.35 + (_micPulse.value * 0.35)
                                  : 0.28;
                              final ring = state.isRecording
                                  ? 8.0 + (_micPulse.value * 10)
                                  : 0.0;
                              return Container(
                                width: 156,
                                height: 156,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (state.isRecording
                                              ? AppColors.badge
                                              : AppColors.primary)
                                          .withValues(alpha: pulse),
                                      blurRadius: 28 + ring,
                                      spreadRadius: 2 + ring * 0.3,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: state.isRecording
                                          ? [
                                              const Color(0xFFD45A4A),
                                              AppColors.primaryDark,
                                            ]
                                          : [
                                              AppColors.primary,
                                              AppColors.primaryDark,
                                            ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: state.isRecording ? 0.55 : 0.35,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    state.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                    size: 52,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          state.isRecording
                              ? t('search.recording',
                                  params: {'seconds': '${state.recordSeconds}'})
                              : state.localAudioPath != null
                                  ? t('search.audio_ready')
                                  : t('search.tap_mic'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              t('search.or_text'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    ],
                    if (!voiceEnabled) const SizedBox(height: 20),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textCtrl,
                      minLines: 2,
                      maxLines: 4,
                      enabled: !busy && !state.isRecording,
                      decoration: InputDecoration(
                        hintText: t('search.text_hint'),
                      ),
                      onChanged: cubit.setText,
                    ),
                    const SizedBox(height: 12),
                    SearchFiltersPanel(
                      categories: state.categories,
                      selectedCategoryId: state.selectedCategoryId,
                      scheduledAt: state.scheduledAt,
                      timeSlot: state.timeSlot,
                      enabled: !busy && !state.isRecording,
                      childAge: state.childAge,
                      hasPet: state.hasPet,
                      budgetMax: state.budgetMax,
                      onCategoryChanged: cubit.setCategory,
                      onScheduledAtChanged: cubit.setScheduledAt,
                      onTimeSlotChanged: cubit.setTimeSlot,
                      onChildAgeChanged: cubit.setChildAge,
                      onHasPetChanged: cubit.setHasPet,
                      onBudgetMaxChanged: cubit.setBudgetMax,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primary,
                      title: Text(t('search.urgent_title')),
                      subtitle: Text(
                        t(
                          canUrgent
                              ? 'search.urgent_subtitle'
                              : 'search.urgent_limit',
                          params: {
                            'fee': urgentFee.toStringAsFixed(0),
                            'km': urgentKm,
                            'hours': urgentHours,
                            'count': urgentRemaining,
                          },
                        ),
                      ),
                      value: canUrgent && state.isUrgent,
                      onChanged: busy || !canUrgent ? null : cubit.setUrgent,
                    ),
                    const SizedBox(height: 8),
                    SearchLocationField(
                      latitude: state.latitude,
                      longitude: state.longitude,
                      address: state.address,
                      enabled: !busy && !state.isRecording,
                      onChanged: cubit.setLocation,
                    ),
                    const SizedBox(height: 12),
                    _SubmitChargeInfo(
                      user: context.watch<AuthCubit>().state.user,
                      isUrgent: canUrgent && state.isUrgent,
                      fallbackUrgentFee: urgentFee,
                    ),
                    const SizedBox(height: 16),
                    if (state.phase == SearchPhase.submitting ||
                        state.phase == SearchPhase.processing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(t('search.processing')),
                          ],
                        ),
                      ),
                    ElevatedButton(
                      onPressed: busy || state.isRecording
                          ? null
                          : () {
                              if (!canUrgent) cubit.setUrgent(false);
                              cubit.submit();
                            },
                      child: Text(
                        busy ? t('search.submitting') : t('search.submit'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SubmitChargeInfo extends StatelessWidget {
  const _SubmitChargeInfo({
    required this.user,
    required this.isUrgent,
    required this.fallbackUrgentFee,
  });

  final UserModel? user;
  final bool isUrgent;
  final double fallbackUrgentFee;

  @override
  Widget build(BuildContext context) {
    // Search request itself is free; only urgent adds a charge.
    const base = 0.0;
    final urgent = isUrgent
        ? (user?.urgentQuota?.fee ?? fallbackUrgentFee)
        : 0.0;
    final total = base + urgent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balansdan çıxılacaq: ${total.toStringAsFixed(2)} AZN',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Axtarış: ${base.toStringAsFixed(2)} AZN'
            '${isUrgent ? ' + Təcili: ${urgent.toStringAsFixed(2)} AZN' : ''}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBody extends StatefulWidget {
  const _ResultsBody({
    required this.state,
    required this.onUrgent,
    required this.onRefresh,
  });

  final SearchAiState state;
  final VoidCallback onUrgent;
  final VoidCallback onRefresh;

  @override
  State<_ResultsBody> createState() => _ResultsBodyState();
}

class _ResultsBodyState extends State<_ResultsBody> {
  int? _connectingId;
  int? _selectedProviderId;
  bool _mapView = false;
  final _scroll = ScrollController();
  final _cardKeys = <int, GlobalKey>{};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int providerId) =>
      _cardKeys.putIfAbsent(providerId, GlobalKey.new);

  void _selectProvider(int? providerId, {bool scrollToCard = false}) {
    setState(() => _selectedProviderId = providerId);
    if (providerId != null && scrollToCard && !_mapView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keyFor(providerId).currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            alignment: 0.2,
          );
        }
      });
    }
  }

  MatchModel? _matchFor(int? providerId) {
    if (providerId == null) return null;
    for (final m in widget.state.request!.matches) {
      if (m.provider?.id == providerId) return m;
    }
    return null;
  }

  Future<void> _connect(MatchModel match) async {
    final profileId = match.provider?.id;
    if (profileId == null) return;
    setState(() => _connectingId = profileId);
    final result = await getIt<ChatRepository>().connect(
      providerProfileId: profileId,
      serviceRequestId: widget.state.request?.id,
    );
    if (!mounted) return;
    setState(() => _connectingId = null);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (conversation) {
        context.read<AuthCubit>().bootstrap();
        context.push('/chat/${conversation.id}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.state.request!;
    final matches = request.matches;
    final onUrgent = widget.onUrgent;
    final onRefresh = widget.onRefresh;
    final selected = _matchFor(_selectedProviderId);

    if (_mapView) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _ResultsHeader(
              request: request,
              matchCount: matches.length,
              mapView: _mapView,
              onToggleView: () => setState(() => _mapView = false),
              onUrgent: onUrgent,
            ),
          ),
          Expanded(
            child: MatchesMap(
              request: request,
              expanded: true,
              selectedProviderId: _selectedProviderId,
              onProviderTap: (id) => _selectProvider(id),
            ),
          ),
          if (selected != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: MatchCard(
                  match: selected,
                  selected: true,
                  connecting: _connectingId == selected.provider?.id,
                  onConnect: selected.provider == null
                      ? null
                      : () => _connect(selected),
                ),
              ),
            ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        children: [
          if (request.transcribedText != null) ...[
            Text(t('search.your_request'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              request.transcribedText!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResultChip(
                label: _statusAz(request.status),
                background: AppColors.skySoft,
                foreground: AppColors.sky,
              ),
              if (request.category != null)
                _ResultChip(
                  label: request.category!.nameAz,
                  background: AppColors.peach,
                  foreground: AppColors.primaryDark,
                ),
              if (request.parsedCriteria?['time_slot'] != null)
                _ResultChip(
                  label: _timeSlotAz('${request.parsedCriteria!['time_slot']}'),
                  background: AppColors.cream,
                  foreground: AppColors.primaryDark,
                ),
              if (request.isUrgent)
                _ResultChip(
                  label: t('search.urgent_title'),
                  background: AppColors.peach,
                  foreground: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (context.watch<AuthCubit>().state.user?.isClient == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                t('match.connect_remaining', params: {
                  'count':
                      '${context.watch<AuthCubit>().state.user?.connectQuota?.dailyRemaining ?? 0}',
                }),
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          _ResultsHeader(
            request: request,
            matchCount: matches.length,
            mapView: _mapView,
            onToggleView: matches.isEmpty
                ? null
                : () => setState(() {
                      _mapView = true;
                      _selectProvider(matches.first.provider?.id);
                    }),
            onUrgent: onUrgent,
          ),
          const SizedBox(height: 8),
          MatchesMap(
            request: request,
            selectedProviderId: _selectedProviderId,
            onProviderTap: (id) => _selectProvider(id, scrollToCard: true),
          ),
          const SizedBox(height: 16),
          ..._searchMetaBanners(context, request),
          const SizedBox(height: 8),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  request.transcriptionFailed
                      ? t('search.transcript_failed')
                      : t('search.no_matches'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...matches.map((m) {
              final pid = m.provider?.id;
              return Padding(
                key: pid != null ? _keyFor(pid) : null,
                padding: const EdgeInsets.only(bottom: 8),
                child: MatchCard(
                  match: m,
                  selected: pid != null && pid == _selectedProviderId,
                  connecting: _connectingId == pid,
                  onConnect: m.provider == null ? null : () => _connect(m),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.request,
    required this.matchCount,
    required this.mapView,
    required this.onUrgent,
    this.onToggleView,
  });

  final ServiceRequestModel request;
  final int matchCount;
  final bool mapView;
  final VoidCallback onUrgent;
  final VoidCallback? onToggleView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            t('search.matches_count', params: {'count': '$matchCount'}),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (onToggleView != null)
          TextButton.icon(
            onPressed: onToggleView,
            icon: Icon(mapView ? Icons.view_list : Icons.map_outlined, size: 18),
            label: Text(mapView ? t('search.view_list') : t('search.view_map')),
          ),
        if (!request.isUrgent)
          TextButton.icon(
            onPressed: (context.watch<AuthCubit>().state.user?.canUrgent ?? true)
                ? onUrgent
                : null,
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: Text(t('search.urgent_title')),
          ),
      ],
    );
  }
}

List<Widget> _searchMetaBanners(
  BuildContext context,
  ServiceRequestModel request,
) {
  final meta = request.searchMeta;
  if (meta == null) return const [];

  final notes = <String>[];
  if (meta['expanded'] == true) {
    notes.add(t('search.meta.expanded', params: {
      'from': '${meta['base_radius_km'] ?? 50}',
      'to': '${meta['radius_km'] ?? ''}',
    }));
  }
  if (meta['dropped_category'] == true) {
    notes.add(t('search.meta.dropped_category'));
  }
  if (meta['dropped_area'] == true) {
    notes.add(t('search.meta.dropped_area'));
  }
  if (meta['dropped_schedule'] == true) {
    notes.add(t('search.meta.dropped_schedule'));
  }
  if (meta['urgent'] == true) {
    notes.add(t('search.meta.urgent_radius', params: {
      'km': '${meta['base_radius_km'] ?? meta['radius_km'] ?? 5}',
    }));
  }
  if (notes.isEmpty) return const [];

  return [
    for (final n in notes)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(n, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
  ];
}

String _statusAz(String status) {
  return switch (status) {
    'processing' => t('request.status.processing'),
    'active' => 'Aktiv',
    'matched' => t('request.status.matched'),
    'completed' => t('request.status.completed'),
    'cancelled' => t('request.status.cancelled'),
    _ => status,
  };
}

String _timeSlotAz(String slot) {
  return switch (slot) {
    'morning' => 'Səhər',
    'afternoon' => 'Günorta',
    'evening' => 'Axşam',
    'night' => 'Gecə',
    _ => slot,
  };
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      backgroundColor: background,
      side: BorderSide(color: foreground.withValues(alpha: 0.25)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
