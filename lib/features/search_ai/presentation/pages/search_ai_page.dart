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
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_cubit.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_state.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/match_card.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/matches_map.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/search_location_field.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/search_filters_panel.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/search_voice_prompt_player.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/request_ttl_confirm.dart';

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
    with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _prompts = SearchVoicePromptPlayer();
  late final TabController _tabs;
  late final AnimationController _micPulse;
  late final AnimationController _logoPulse;
  bool _greetingPlaying = false;
  bool _greetingDone = false;
  bool _acceptedPlayedForSubmit = false;
  SearchPhase? _lastPhase;
  bool _ttlDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _tabs.addListener(_onTabChanged);
    // Small delay so route transition + audio session settle after boot → search.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _maybePlayGreeting();
      });
    });
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index != 0 && _greetingPlaying) {
      _prompts.stop();
      _logoPulse
        ..stop()
        ..value = 0;
      setState(() {
        _greetingPlaying = false;
        _greetingDone = true;
      });
    }
  }

  Future<void> _maybePlayGreeting() async {
    if (!mounted || _greetingDone || _greetingPlaying) return;
    if (!AppRemoteConfig.instance.flags.voiceSearch) {
      setState(() => _greetingDone = true);
      return;
    }
    await _prompts.playGreeting(
      onStart: () {
        if (!mounted) return;
        setState(() => _greetingPlaying = true);
        _logoPulse.repeat(reverse: true);
      },
      onDone: () {
        if (!mounted) return;
        _logoPulse
          ..stop()
          ..value = 0;
        setState(() {
          _greetingPlaying = false;
          _greetingDone = true;
        });
      },
    );
  }

  Future<void> _maybePlayAccepted(SearchAiState state) async {
    final startedSubmit = state.phase == SearchPhase.submitting &&
        state.localAudioPath != null &&
        _lastPhase != SearchPhase.submitting;
    _lastPhase = state.phase;
    if (!startedSubmit || _acceptedPlayedForSubmit) return;
    _acceptedPlayedForSubmit = true;
    await _prompts.playAccepted(
      onStart: () {
        if (!mounted) return;
        setState(() => _greetingPlaying = true);
        _logoPulse.repeat(reverse: true);
      },
      onDone: () {
        if (!mounted) return;
        _logoPulse
          ..stop()
          ..value = 0;
        setState(() => _greetingPlaying = false);
      },
    );
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _micPulse.dispose();
    _logoPulse.dispose();
    _textCtrl.dispose();
    _prompts.dispose();
    super.dispose();
  }

  Future<void> _maybeConfirmTtl(BuildContext context, SearchAiState state) async {
    if (state.phase != SearchPhase.confirmTtl || _ttlDialogOpen) return;
    _ttlDialogOpen = true;
    final hours = await confirmRequestTtl(context);
    if (!mounted) return;
    _ttlDialogOpen = false;
    final cubit = context.read<SearchAiCubit>();
    if (hours == null) {
      cubit.cancelTtlConfirm();
      return;
    }
    await cubit.submit(ttlHours: hours);
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
        if (state.phase == SearchPhase.idle ||
            state.phase == SearchPhase.results ||
            state.phase == SearchPhase.error) {
          _acceptedPlayedForSubmit = false;
        }
        _maybePlayAccepted(state);
        _maybeConfirmTtl(context, state);
      },
      builder: (context, state) {
        final cubit = context.read<SearchAiCubit>();
        final busy = state.phase == SearchPhase.submitting ||
            state.phase == SearchPhase.processing ||
            state.phase == SearchPhase.locating ||
            state.phase == SearchPhase.confirmTtl;

        final remote = AppRemoteConfig.instance;
        final urgentFee = remote.config.fees.urgent;
        final voiceEnabled = remote.flags.voiceSearch;
        final urgentQuota = context.watch<AuthCubit>().state.user?.urgentQuota;
        final canUrgent = urgentQuota?.canUrgent ?? true;
        final urgentKm =
            (urgentQuota?.radiusKm ?? remote.config.urgentRadiusKm)
                .toStringAsFixed(0);
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
              ? RequestResultsBody(
                  state: state,
                  onUrgent: cubit.markUrgent,
                  onRefresh: () => cubit.refreshRequest(state.request!.id),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('search.headline'),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('search.subtitle'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.mist,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TabBar(
                              controller: _tabs,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.muted,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              tabs: [
                                Tab(text: t('search.tab.voice')),
                                Tab(text: t('search.tab.manual')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _VoiceSearchTab(
                            state: state,
                            busy: busy,
                            voiceEnabled: voiceEnabled,
                            greetingPlaying: _greetingPlaying,
                            greetingDone: _greetingDone,
                            micPulse: _micPulse,
                            logoPulse: _logoPulse,
                            canRecord: !_greetingPlaying &&
                                _greetingDone &&
                                !busy,
                            onToggleRecord: cubit.toggleRecording,
                          ),
                          _ManualSearchTab(
                            state: state,
                            busy: busy,
                            textCtrl: _textCtrl,
                            cubit: cubit,
                            canUrgent: canUrgent,
                            urgentFee: urgentFee,
                            urgentKm: urgentKm,
                            urgentHours: urgentHours,
                            urgentRemaining: urgentRemaining,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _VoiceSearchTab extends StatelessWidget {
  const _VoiceSearchTab({
    required this.state,
    required this.busy,
    required this.voiceEnabled,
    required this.greetingPlaying,
    required this.greetingDone,
    required this.micPulse,
    required this.logoPulse,
    required this.canRecord,
    required this.onToggleRecord,
  });

  final SearchAiState state;
  final bool busy;
  final bool voiceEnabled;
  final bool greetingPlaying;
  final bool greetingDone;
  final AnimationController micPulse;
  final AnimationController logoPulse;
  final bool canRecord;
  final VoidCallback onToggleRecord;

  @override
  Widget build(BuildContext context) {
    if (!voiceEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t('search.voice_disabled'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        if (busy &&
            !state.isRecording &&
            state.phase != SearchPhase.confirmTtl) ...[
          _SearchBusyPanel(
            uploading: state.phase == SearchPhase.submitting &&
                state.localAudioPath != null,
            processing: state.phase == SearchPhase.processing,
          ),
          if (greetingPlaying) ...[
            const SizedBox(height: 20),
            _SpeakingLogo(pulse: logoPulse),
          ],
        ] else if (greetingPlaying || !greetingDone) ...[
          _SpeakingLogo(pulse: logoPulse),
          const SizedBox(height: 18),
          Text(
            greetingPlaying
                ? t('search.voice_greeting_playing')
                : t('search.voice_greeting_loading'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            t('search.voice_greeting_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ] else ...[
          Center(
            child: GestureDetector(
              onTap: canRecord ? onToggleRecord : null,
              child: AnimatedBuilder(
                animation: micPulse,
                builder: (context, _) {
                  final pulse = state.isRecording
                      ? 0.35 + (micPulse.value * 0.35)
                      : 0.28;
                  final ring =
                      state.isRecording ? 8.0 + (micPulse.value * 10) : 0.0;
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
                        state.isRecording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
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
          const SizedBox(height: 12),
          Text(
            t('search.voice_tab_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _SpeakingLogo extends StatelessWidget {
  const _SpeakingLogo({required this.pulse});

  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final scale = 1.0 + (pulse.value * 0.06);
          final glow = 0.12 + (pulse.value * 0.16);
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: glow),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/brand/logo-color.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManualSearchTab extends StatelessWidget {
  const _ManualSearchTab({
    required this.state,
    required this.busy,
    required this.textCtrl,
    required this.cubit,
    required this.canUrgent,
    required this.urgentFee,
    required this.urgentKm,
    required this.urgentHours,
    required this.urgentRemaining,
  });

  final SearchAiState state;
  final bool busy;
  final TextEditingController textCtrl;
  final SearchAiCubit cubit;
  final bool canUrgent;
  final double urgentFee;
  final String urgentKm;
  final String urgentHours;
  final String urgentRemaining;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        if (busy) ...[
          _SearchBusyPanel(
            uploading: false,
            processing: state.phase == SearchPhase.processing,
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: textCtrl,
          minLines: 2,
          maxLines: 4,
          enabled: !busy,
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
          enabled: !busy,
          onCategoryChanged: cubit.setCategory,
          onScheduledAtChanged: cubit.setScheduledAt,
          onTimeSlotChanged: cubit.setTimeSlot,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.primary,
          title: Text(t('search.urgent_title')),
          subtitle: Text(
            t(
              canUrgent ? 'search.urgent_subtitle' : 'search.urgent_limit',
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
          enabled: !busy,
          onChanged: cubit.setLocation,
        ),
        const SizedBox(height: 12),
        _SubmitChargeInfo(
          user: context.watch<AuthCubit>().state.user,
          isUrgent: canUrgent && state.isUrgent,
          fallbackUrgentFee: urgentFee,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: busy
              ? null
              : () {
                  if (!canUrgent) cubit.setUrgent(false);
                  cubit.requestSubmit();
                },
          child: Text(
            busy ? t('search.submitting') : t('search.submit'),
          ),
        ),
      ],
    );
  }
}

class _SearchBusyPanel extends StatelessWidget {
  const _SearchBusyPanel({
    required this.uploading,
    required this.processing,
  });

  final bool uploading;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final title = uploading
        ? t('search.voice_uploading')
        : processing
            ? t('search.processing')
            : t('search.submitting');
    final hint = uploading
        ? t('search.voice_uploading_hint')
        : t('search.processing_hint');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: AppColors.primary,
              backgroundColor: AppColors.mist,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              minHeight: 4,
              color: AppColors.secondary,
              backgroundColor: AppColors.peach,
            ),
          ),
        ],
      ),
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
            t('search.fee_total', params: {
              'amount': total.toStringAsFixed(2),
            }),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isUrgent
                ? t('search.fee_breakdown_urgent', params: {
                    'base': base.toStringAsFixed(2),
                    'urgent': urgent.toStringAsFixed(2),
                  })
                : t('search.fee_breakdown', params: {
                    'base': base.toStringAsFixed(2),
                  }),
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

class RequestResultsBody extends StatefulWidget {
  const RequestResultsBody({
    required this.state,
    required this.onUrgent,
    required this.onRefresh,
  });

  final SearchAiState state;
  final VoidCallback onUrgent;
  final VoidCallback onRefresh;

  @override
  State<RequestResultsBody> createState() => _RequestResultsBodyState();
}

class _RequestResultsBodyState extends State<RequestResultsBody> {
  int? _connectingId;
  int? _selectedProviderId;
  bool _mapView = false;
  final _scroll = ScrollController();
  final _cardKeys = <int, GlobalKey>{};
  final _favoriteOverrides = <int, bool>{};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int providerId) =>
      _cardKeys.putIfAbsent(providerId, GlobalKey.new);

  bool _isFavorite(MatchModel m) {
    final id = m.provider?.id;
    if (id == null) return false;
    return _favoriteOverrides[id] ?? m.provider?.isFavorite ?? false;
  }

  Future<void> _toggleFavorite(MatchModel match) async {
    final id = match.provider?.id;
    if (id == null) return;
    final next = !_isFavorite(match);
    setState(() => _favoriteOverrides[id] = next);
    final repo = getIt<ProfileRepository>();
    final result = next
        ? await repo.addFavorite(id)
        : await repo.removeFavorite(id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _favoriteOverrides[id] = !next);
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
        // Navigate first — bootstrap rebuild must not race the shell push
        // (duplicate pageKey / HeroControllerScope crash).
        context.push('/chat/${conversation.id}');
        context.read<AuthCubit>().bootstrap();
      },
    );
  }

  void _openProfile(MatchModel match) {
    final profileId = match.provider?.id;
    if (profileId == null) return;
    final requestId = widget.state.request?.id;
    final q = requestId != null ? '?requestId=$requestId' : '';
    context.push('/providers/$profileId$q');
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
                  isFavorite: _isFavorite(selected),
                  onToggleFavorite: selected.provider == null
                      ? null
                      : () => _toggleFavorite(selected),
                  onOpenProfile: selected.provider == null
                      ? null
                      : () => _openProfile(selected),
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
                  label: request.category!.displayName,
                  background: AppColors.peach,
                  foreground: AppColors.primaryDark,
                ),
              if (request.parsedCriteria?['time_slot'] != null)
                _ResultChip(
                  label: t('web.schedule.${request.parsedCriteria!['time_slot']}'),
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
                context.watch<AuthCubit>().state.user?.connectQuota?.hintLabel() ??
                    t('match.connect_remaining', params: {'count': '0'}),
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
                  isFavorite: _isFavorite(m),
                  onToggleFavorite:
                      m.provider == null ? null : () => _toggleFavorite(m),
                  onOpenProfile:
                      m.provider == null ? null : () => _openProfile(m),
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
