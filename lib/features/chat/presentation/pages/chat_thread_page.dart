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
import 'package:home_service_app/app/widgets/app_confirm_dialog.dart';

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
    final isProvider =
        context.read<AuthCubit>().state.user?.isProvider == true;
    final ok = await showAppConfirm(
      context,
      title: t('block.title'),
      message: t(
        isProvider ? 'block.confirm.provider' : 'block.confirm.client',
      ),
      confirmLabel: t('block.confirm_action'),
      cancelLabel: t('block.cancel'),
      destructive: true,
    );
    if (ok != true || !context.mounted) return;
    final blocked = await cubit.blockUser(userId);
    if (blocked && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('block.done'))),
      );
      await cubit.load();
    }
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    ChatThreadCubit cubit,
    int userId,
    String name,
  ) async {
    final ok = await showAppConfirm(
      context,
      title: t('block.unblock_title'),
      message: t('block.unblock_confirm', params: {'name': name}),
      confirmLabel: t('block.unblock_action'),
      cancelLabel: t('block.cancel'),
    );
    if (ok != true || !context.mounted) return;
    final done = await cubit.unblockUser(userId);
    if (done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('block.unblocked'))),
      );
      await cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthCubit>().state.user;
    final myId = me?.id;

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
        final isClient =
            myId != null && conv != null && conv.clientId == myId;
        final isProviderParty =
            myId != null && conv != null && conv.providerId == myId;
        final canSendOffer = me?.isProvider == true &&
            isProviderParty &&
            (conv?.canSendOffer ?? false) &&
            (conv?.canMessage ?? true);
        final isBlocked = conv?.isBlocked == true;
        final isProvider = isProviderParty;
        final title = conv?.otherUser?.displayName ??
            conv?.profileTitle ??
            t('chat.fallback_name');
        final phone = conv?.otherUser?.phone;
        final requestContext = conv?.serviceRequest?.contextLine;
        final cubit = context.read<ChatThreadCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
                    if (isBlocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t('chat.blocked_badge'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (requestContext != null)
                  Text(
                    requestContext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  )
                else if (phone != null && phone.isNotEmpty)
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
              if (canSendOffer)
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
                    } else if (value == 'unblock') {
                      _confirmUnblock(
                        context,
                        cubit,
                        otherId,
                        conv.otherUser!.displayName,
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Text(t('report.menu')),
                    ),
                    if (conv?.blockedByMe == true)
                      PopupMenuItem(
                        value: 'unblock',
                        child: Text(t('block.unblock_action')),
                      )
                    else if (conv?.isBlocked != true)
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
              if (isBlocked)
                Material(
                  color: AppColors.peach,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.block,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            conv?.blockedByMe == true
                                ? t('chat.blocked_by_me_hint')
                                : t('chat.blocked_hint'),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (conv?.blockedByMe == true &&
                            conv?.otherUser?.id != null)
                          TextButton(
                            onPressed: state.sending
                                ? null
                                : () => _confirmUnblock(
                                      context,
                                      cubit,
                                      conv!.otherUser!.id,
                                      conv.otherUser!.displayName,
                                    ),
                            child: Text(t('block.unblock_action')),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: state.loading && conv == null
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        child: ListView.builder(
                          controller: _scroll,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  busy: state.sending || isBlocked,
                                  onAccept: () => cubit.offerAction(
                                      msg.offer!.id, 'accept'),
                                  onDecline: () => cubit.offerAction(
                                      msg.offer!.id, 'decline'),
                                  onComplete: () => cubit.offerAction(
                                      msg.offer!.id, 'complete'),
                                  onCancel: () => cubit.offerAction(
                                      msg.offer!.id, 'cancel'),
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
                                            : Border.all(
                                                color: AppColors.divider),
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
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: isBlocked
                      ? Text(
                          t('chat.blocked_composer'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _input,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onTapOutside: (_) => FocusManager
                                    .instance.primaryFocus
                                    ?.unfocus(),
                                onSubmitted: state.sending
                                    ? null
                                    : (value) {
                                        final text = value.trim();
                                        if (text.isEmpty) return;
                                        _input.clear();
                                        cubit.send(text);
                                      },
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
                                        final text = _input.text.trim();
                                        if (text.isEmpty) return;
                                        _input.clear();
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        cubit.send(text);
                                      },
                                icon: Icon(
                                  state.sending
                                      ? Icons.hourglass_empty
                                      : Icons.send,
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
