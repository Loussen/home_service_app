import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';
import 'package:home_service_app/features/jobs/data/models/incoming_job_model.dart';
import 'package:home_service_app/features/jobs/domain/jobs_repository.dart';
import 'package:home_service_app/features/jobs/presentation/cubit/jobs_state.dart';

class JobsCubit extends Cubit<JobsState> {
  JobsCubit(this._jobs, this._chat) : super(const JobsState());

  final JobsRepository _jobs;
  final ChatRepository _chat;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _jobs.list();
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (items) => emit(state.copyWith(loading: false, items: items)),
    );
  }

  Future<ConversationModel?> reply(IncomingJobModel job) async {
    final requestId = job.requestId;
    if (requestId == null) return null;
    emit(state.copyWith(replyingId: job.matchId, clearMessage: true));
    final result = await _chat.replyToJob(
      serviceRequestId: requestId,
      providerProfileId: job.providerProfileId,
    );
    return result.fold(
      (f) {
        emit(state.copyWith(clearReply: true, message: f.message));
        return null;
      },
      (c) {
        emit(state.copyWith(clearReply: true));
        return c;
      },
    );
  }
}
