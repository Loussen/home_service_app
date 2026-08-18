import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/bookings/data/models/booking_model.dart';
import 'package:home_service_app/features/bookings/presentation/cubit/bookings_cubit.dart';
import 'package:intl/intl.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BookingsCubit>()..load(),
      child: const _BookingsView(),
    );
  }
}

class _BookingsView extends StatelessWidget {
  const _BookingsView();

  Future<void> _confirmCancel(BuildContext context, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('bookings.cancel_title')),
        content: Text(t('bookings.cancel_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('block.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('bookings.cancel_action')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<BookingsCubit>().cancel(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('bookings.title'))),
      body: BlocConsumer<BookingsCubit, BookingsState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t('bookings.empty'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<BookingsCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (state.upcoming.isNotEmpty) ...[
                  Text(
                    t('bookings.upcoming'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...state.upcoming.map(
                    (b) => _BookingCard(
                      booking: b,
                      busy: state.cancellingId == b.id,
                      onOpenChat: () => context.push('/chat/${b.conversationId}'),
                      onCancel: () => _confirmCancel(context, b.id),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (state.past.isNotEmpty) ...[
                  Text(
                    t('bookings.past'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...state.past.map(
                    (b) => _BookingCard(
                      booking: b,
                      onOpenChat: () => context.push('/chat/${b.conversationId}'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onOpenChat,
    this.onCancel,
    this.busy = false,
  });

  final BookingModel booking;
  final VoidCallback onOpenChat;
  final VoidCallback? onCancel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM, HH:mm').format(booking.scheduledAt.toLocal());
    final title = booking.otherUserName ?? t('chat.fallback_name');
    final subtitle = [
      if (booking.profileTitle != null && booking.profileTitle!.isNotEmpty)
        booking.profileTitle,
      if (booking.categoryName != null && booking.categoryName!.isNotEmpty)
        booking.categoryName,
    ].whereType<String>().join(' · ');

    final (statusLabel, bg, fg) = switch (booking.status) {
      'completed' => (
          t('bookings.status.completed'),
          const Color(0xFFE8F6EA),
          AppColors.published,
        ),
      'cancelled' => (
          t('bookings.status.cancelled'),
          AppColors.peach,
          AppColors.muted,
        ),
      _ => (
          t('bookings.status.scheduled'),
          AppColors.skySoft,
          AppColors.sky,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          ],
          const SizedBox(height: 10),
          _Line(icon: Icons.event, text: when),
          _Line(
            icon: Icons.payments_outlined,
            text: '${booking.priceAzn.toStringAsFixed(0)} AZN',
          ),
          if (booking.durationHours != null) ...[
            const SizedBox(height: 4),
            _Line(
              icon: Icons.schedule,
              text: t('offer.duration', params: {
                'hours': booking.durationHours!.toStringAsFixed(
                  booking.durationHours! % 1 == 0 ? 0 : 1,
                ),
              }),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenChat,
                  child: Text(t('bookings.open_chat')),
                ),
              ),
              if (booking.isScheduled && onCancel != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onCancel,
                    child: Text(
                      busy ? t('bookings.cancelling') : t('bookings.cancel_action'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
