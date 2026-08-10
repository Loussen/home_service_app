import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_cubit.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_state.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/match_card.dart';
import 'package:home_service_app/features/search_ai/presentation/widgets/matches_map.dart';

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

class _SearchAiViewState extends State<_SearchAiView> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
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
          if (state.message!.contains('Qalan:')) {
            context.read<AuthCubit>().bootstrap();
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<SearchAiCubit>();
        final busy = state.phase == SearchPhase.submitting ||
            state.phase == SearchPhase.processing ||
            state.phase == SearchPhase.locating;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI səsli sorğu'),
            actions: [
              if (state.phase == SearchPhase.results)
                IconButton(
                  onPressed: cubit.reset,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Yeni sorğu',
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
                      'Nə axtarırsınız?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mikrofonu basıb danışın və ya mətni yazın. AI yaxınlıqdakı peşəkarları tapacaq.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: busy ? null : cubit.toggleRecording,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: state.isRecording
                                ? Colors.red.shade400
                                : Theme.of(context).colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: (state.isRecording
                                        ? Colors.red
                                        : Theme.of(context).colorScheme.primary)
                                    .withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            state.isRecording ? Icons.stop : Icons.mic,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        state.isRecording
                            ? 'Yazılır… ${state.recordSeconds}s'
                            : state.localAudioPath != null
                                ? 'Səs hazırdır — göndərin'
                                : 'Basın və danışın',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'və ya mətn',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textCtrl,
                      minLines: 2,
                      maxLines: 4,
                      enabled: !busy && !state.isRecording,
                      decoration: const InputDecoration(
                        hintText:
                            'məs. Nərimanovda sabah günorta 2 saata dayə axtarıram',
                      ),
                      onChanged: cubit.setText,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Təcili (urgent)'),
                      subtitle: const Text('Yaxın provider-lərə dərhal bildiriş · balansdan'),
                      value: state.isUrgent,
                      onChanged: busy ? null : cubit.setUrgent,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(
                        '${state.latitude.toStringAsFixed(4)}, ${state.longitude.toStringAsFixed(4)}',
                      ),
                      subtitle: const Text('Axtarış mərkəzi'),
                    ),
                    const SizedBox(height: 16),
                    if (state.phase == SearchPhase.submitting ||
                        state.phase == SearchPhase.processing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            LinearProgressIndicator(),
                            SizedBox(height: 8),
                            Text('AI emal edir və match edir…'),
                          ],
                        ),
                      ),
                    ElevatedButton(
                      onPressed: busy || state.isRecording ? null : cubit.submit,
                      child: Text(
                        busy ? 'Göndərilir…' : 'Axtar',
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.state,
    required this.onUrgent,
    required this.onRefresh,
  });

  final SearchAiState state;
  final VoidCallback onUrgent;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final request = state.request!;
    final matches = request.matches;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (request.transcribedText != null) ...[
            Text('Sizin sorğunuz', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              request.transcribedText!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(request.status)),
              if (request.category != null)
                Chip(label: Text(request.category!.nameAz)),
              if (request.parsedCriteria?['time_slot'] != null)
                Chip(
                  label: Text('${request.parsedCriteria!['time_slot']}'),
                ),
              if (request.isUrgent) const Chip(label: Text('Təcili')),
            ],
          ),
          const SizedBox(height: 12),
          MatchesMap(request: request),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${matches.length} uyğunluq',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (!request.isUrgent)
                TextButton.icon(
                  onPressed: onUrgent,
                  icon: const Icon(Icons.campaign_outlined, size: 18),
                  label: const Text('Urgent'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (matches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Uyğun provider tapılmadı.\nRadiusu genişləndirin və ya digər vaxt seçin.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...matches.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MatchCard(match: m),
                )),
        ],
      ),
    );
  }
}
