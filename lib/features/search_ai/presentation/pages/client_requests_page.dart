import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/utils/request_status.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';
import 'package:home_service_app/features/search_ai/domain/search_repository.dart';

enum _RequestsFilter { all, matched, unmatched }

class ClientRequestsPage extends StatefulWidget {
  const ClientRequestsPage({super.key});

  @override
  State<ClientRequestsPage> createState() => _ClientRequestsPageState();
}

class _ClientRequestsPageState extends State<ClientRequestsPage> {
  bool _loading = true;
  List<ServiceRequestModel> _items = [];
  String? _error;
  _RequestsFilter _filter = _RequestsFilter.all;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  String get _filterParam => switch (_filter) {
        _RequestsFilter.matched => 'matched',
        _RequestsFilter.unmatched => 'unmatched',
        _RequestsFilter.all => 'all',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });
    final result = await getIt<SearchRepository>().listRequests(
      page: page,
      perPage: 10,
      filter: _filterParam,
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (pageData) => setState(() {
        _loading = false;
        _items = pageData.items;
        _page = pageData.currentPage;
        _lastPage = pageData.lastPage;
        _total = pageData.total;
      }),
    );
  }

  void _setFilter(_RequestsFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _load(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                t('tabs.client.requests'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(t('web.requests.filter_all')),
                    selected: _filter == _RequestsFilter.all,
                    onSelected: (_) => _setFilter(_RequestsFilter.all),
                  ),
                  ChoiceChip(
                    label: Text(t('web.requests.filter_matched')),
                    selected: _filter == _RequestsFilter.matched,
                    onSelected: (_) => _setFilter(_RequestsFilter.matched),
                  ),
                  ChoiceChip(
                    label: Text(t('web.requests.filter_unmatched')),
                    selected: _filter == _RequestsFilter.unmatched,
                    onSelected: (_) => _setFilter(_RequestsFilter.unmatched),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            _error ??
                                (_filter == _RequestsFilter.all
                                    ? t('requests.empty')
                                    : t('web.requests.filter_empty')),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _load(page: 1),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final r = _items[index];
                              final matchCount =
                                  r.matchesCount ?? r.matches.length;
                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    await context.push('/requests/${r.id}');
                                    if (mounted) _load(page: _page);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppColors.divider),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      r.transcribedText ??
                                                          t(
                                                            'requests.item_fallback',
                                                            params: {
                                                              'id': '${r.id}',
                                                            },
                                                          ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.mist,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                      border: Border.all(
                                                        color:
                                                            AppColors.divider,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      requestStatusLabel(
                                                          r.status),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Builder(
                                                    builder: (_) {
                                                      final live = isRequestLive(
                                                        r.status,
                                                        r.expiresAt,
                                                      );
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: live
                                                              ? const Color(
                                                                  0xFFE8F3EA)
                                                              : AppColors
                                                                  .parchment,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      999),
                                                          border: Border.all(
                                                            color: live
                                                                ? AppColors
                                                                    .published
                                                                : AppColors
                                                                    .divider,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          requestLifecycleLabel(
                                                            r.status,
                                                            r.expiresAt,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800,
                                                            color: live
                                                                ? AppColors
                                                                    .published
                                                                : AppColors
                                                                    .muted,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Builder(
                                                builder: (_) {
                                                  final created =
                                                      formatIsoDateTime(
                                                          r.createdAt);
                                                  final expires =
                                                      formatIsoDateTime(
                                                          r.expiresAt);
                                                  if (created == null &&
                                                      expires == null) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (created != null)
                                                          Text(
                                                            t(
                                                              'jobs.created_at',
                                                              params: {
                                                                'when': created,
                                                              },
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                              color: AppColors
                                                                  .muted,
                                                              fontSize: 12.5,
                                                            ),
                                                          ),
                                                        if (expires != null) ...[
                                                          if (created != null)
                                                            const SizedBox(
                                                                height: 2),
                                                          Text(
                                                            t(
                                                              'jobs.expires_at',
                                                              params: {
                                                                'when': expires,
                                                              },
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                              color: AppColors
                                                                  .muted,
                                                              fontSize: 12.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (r.displayPlace != null) ...[
                                                Text(
                                                  r.displayPlace!,
                                                  style: const TextStyle(
                                                    color: AppColors.muted,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              Text(
                                                [
                                                  if (r.serviceWhenLabel != null)
                                                    t(
                                                      'requests.when',
                                                      params: {
                                                        'when':
                                                            r.serviceWhenLabel!,
                                                      },
                                                    ),
                                                  t(
                                                    'requests.matches_count',
                                                    params: {
                                                      'count': '$matchCount',
                                                    },
                                                  ),
                                                ].join(' · '),
                                                style: const TextStyle(
                                                  color: AppColors.muted,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: AppColors.muted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            if (_lastPage > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('web.requests.page_info', params: {
                          'page': '$_page',
                          'last': '$_lastPage',
                          'total': '$_total',
                        }),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          _page > 1 ? () => _load(page: _page - 1) : null,
                      child: Text(t('web.requests.prev')),
                    ),
                    TextButton(
                      onPressed: _page < _lastPage
                          ? () => _load(page: _page + 1)
                          : null,
                      child: Text(t('web.requests.next')),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
