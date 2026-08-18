import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';

class JobsState extends Equatable {
  const JobsState({
    this.loading = false,
    this.replyingId,
    this.items = const [],
    this.message,
  });

  final bool loading;
  final int? replyingId;
  final List<IncomingJobModel> items;
  final String? message;

  JobsState copyWith({
    bool? loading,
    int? replyingId,
    List<IncomingJobModel>? items,
    String? message,
    bool clearMessage = false,
    bool clearReply = false,
  }) {
    return JobsState(
      loading: loading ?? this.loading,
      replyingId: clearReply ? null : (replyingId ?? this.replyingId),
      items: items ?? this.items,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [loading, replyingId, items, message];
}
