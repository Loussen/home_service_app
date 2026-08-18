import 'package:flutter/material.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('review.list_title'))),
      body: FutureBuilder(
        future: getIt<ChatRepository>().listReviews(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.data!.fold(
            (f) => Center(child: Text(f.message)),
            (reviews) {
              if (reviews.isEmpty) {
                return Center(child: Text(t('review.empty')));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _ReviewTile(review: review);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ChatReviewModel review;

  @override
  Widget build(BuildContext context) {
    final name = (review.reviewerName != null &&
            review.reviewerName!.trim().isNotEmpty)
        ? review.reviewerName!
        : t('chat.fallback_name');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _Stars(rating: review.rating),
          ],
        ),
        if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            review.comment!,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: 16,
            color: AppColors.primary,
          ),
      ],
    );
  }
}
