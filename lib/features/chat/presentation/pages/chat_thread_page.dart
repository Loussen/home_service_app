import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/chat/presentation/cubit/chat_thread_cubit.dart';
import 'package:home_service_app/features/chat/presentation/cubit/chat_thread_state.dart';
import 'package:home_service_app/features/chat/presentation/widgets/offer_card.dart';
import 'package:home_service_app/features/chat/presentation/widgets/offer_composer.dart';
import 'package:home_service_app/features/chat/presentation/widgets/review_composer.dart';
import 'package:home_service_app/features/chat/presentation/widgets/report_composer.dart';
import 'package:go_router/go_router.dart';

class ChatThreadPage extends StatelessWidget {
  const ChatThreadPage({super.key, required this.conversationId});

  final int conversationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatThreadCubit>(param1: conversationId)..load(),
      child: const _ChatThreadView(),
    );
  }
}

class _ChatThreadView extends StatefulWidget {
  const _ChatThreadView();

  @override
  State<_ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<_ChatThreadView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _composeOffer(ChatThreadCubit cubit) async {
    await showOfferComposer(
      context,
      onSubmit: ({
        required scheduledAt,
        required priceAzn,
        durationHours,
        note,
      }) =>
          cubit.sendOffer(
        scheduledAt: scheduledAt,
        priceAzn: priceAzn,
        durationHours: durationHours,
        note: note,
      ),
    );
  }

  Future<void> _composeReview(ChatThreadCubit cubit, int offerId) async {
    await showReviewComposer(
      context,
      onSubmit: ({required rating, comment}) => cubit.submitReview(
        offerId: offerId,
        rating: rating,
        comment: comment,
      ),
    );
  }

  Future<void> _reportUser(ChatThreadCubit cubit, int userId) async {
    await showReportComposer(
      context,
      onSubmit: ({required reason, details}) => cubit.reportUser(
        reportedUserId: userId,
        reason: reason,
        details: details,
        conversationId: cubit.conversationId,
      ),
    );
  }

  Future<void> _confirmBlock(
    BuildContext context,
    ChatThreadCubit cubit,
    int userId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('block.title')),
        content: Text(t('block.confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('block.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('block.confirm_action')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final blocked = await cubit.blockUser(userId);
    if (blocked && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('block.done'))),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthCubit>().state.user;
    final myId = me?.id;
    final isProvider = me?.isProvider == true;
    final isClient = me?.isClient == true;

    return BlocConsumer<ChatThreadCubit, ChatThreadState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
        if (state.conversation != null) _scrollToEnd();
      },
      builder: (context, state) {
        final conv = state.conversation;
        final title = conv?.otherUser?.displayName ??
            conv?.profileTitle ??
            t('chat.fallback_name');
        final phone = conv?.otherUser?.phone;
        final cubit = context.read<ChatThreadCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                if (phone != null && phone.isNotEmpty)
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
            actions: [
              if (isProvider)
                IconButton(
                  tooltip: t('offer.compose_title'),
                  onPressed: state.sending ? null : () => _composeOffer(cubit),
                  icon: const Icon(Icons.request_quote_outlined),
                ),
              if (conv?.otherUser?.id != null)
                PopupMenuButton<String>(
                  enabled: !state.sending,
                  onSelected: (value) {
                    final otherId = conv!.otherUser!.id;
                    if (value == 'report') {
                      _reportUser(cubit, otherId);
                    } else if (value == 'block') {
                      _confirmBlock(context, cubit, otherId);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Text(t('report.menu')),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(t('block.menu')),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: state.loading && conv == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: conv?.messages.length ?? 0,
                        itemBuilder: (context, index) {
                          final msg = conv!.messages[index];
                          if (msg.isOffer && msg.offer != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: OfferCard(
                                offer: msg.offer!,
                                isClient: isClient,
                                isProvider: isProvider,
                                myUserId: myId,
                                busy: state.sending,
                                onAccept: () =>
                                    cubit.offerAction(msg.offer!.id, 'accept'),
                                onDecline: () =>
                                    cubit.offerAction(msg.offer!.id, 'decline'),
                                onComplete: () =>
                                    cubit.offerAction(msg.offer!.id, 'complete'),
                                onCancel: () =>
                                    cubit.offerAction(msg.offer!.id, 'cancel'),
                                onReview: () =>
                                    _composeReview(cubit, msg.offer!.id),
                              ),
                            );
                          }
                          final mine = myId != null && msg.senderId == myId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: mine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      border: mine
                                          ? null
                                          : Border.all(color: AppColors.divider),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(
                                          mine ? 18 : 4,
                                        ),
                                        bottomRight: Radius.circular(
                                          mine ? 4 : 18,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.ink
                                              .withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg.body ?? '',
                                      style: TextStyle(
                                        color: mine
                                            ? Colors.white
                                            : AppColors.ink,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: t('chat.message_hint'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          onPressed: state.sending
                              ? null
                              : () {
                                  final text = _input.text;
                                  _input.clear();
                                  cubit.send(text);
                                },
                          icon: Icon(
                            state.sending ? Icons.hourglass_empty : Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
