import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_cubit.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_state.dart';
import 'package:home_service_app/features/search_ai/presentation/pages/search_ai_page.dart';

/// Client «Sorğularım» → uyğunluqlar / CONNECT (API-dən tam sorğu yüklənir).
class RequestDetailPage extends StatelessWidget {
  const RequestDetailPage({super.key, required this.requestId});

  final int requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchAiCubit>()..openRequest(requestId),
      child: _RequestDetailView(requestId: requestId),
    );
  }
}

class _RequestDetailView extends StatelessWidget {
  const _RequestDetailView({required this.requestId});

  final int requestId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchAiCubit, SearchAiState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<SearchAiCubit>();
        final title = state.request?.transcribedText?.trim();
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: Text(
              (title != null && title.isNotEmpty)
                  ? (title.length > 36 ? '${title.substring(0, 36)}…' : title)
                  : t('tabs.client.requests'),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profiles');
                }
              },
            ),
            actions: [
              IconButton(
                tooltip: t('common.retry'),
                onPressed: () => cubit.openRequest(requestId),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _body(context, state, cubit),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    SearchAiState state,
    SearchAiCubit cubit,
  ) {
    if (state.phase == SearchPhase.processing ||
        state.phase == SearchPhase.submitting ||
        state.phase == SearchPhase.locating) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.phase == SearchPhase.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.message ?? t('error.generic'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => cubit.openRequest(requestId),
                child: Text(t('common.retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (state.phase == SearchPhase.results && state.request != null) {
      return RequestResultsBody(
        state: state,
        onUrgent: cubit.markUrgent,
        onRefresh: () => cubit.refreshRequest(state.request!.id),
      );
    }
    return Center(
      child: Text(
        t('search.no_matches'),
        style: const TextStyle(color: AppColors.muted),
      ),
    );
  }
}
