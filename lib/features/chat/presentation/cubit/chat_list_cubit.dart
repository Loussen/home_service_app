import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/chat/domain/chat_repository.dart';
import 'package:home_service_app/features/chat/presentation/cubit/chat_list_state.dart';

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit(this._repo) : super(const ChatListState());

  final ChatRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.list();
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (items) => emit(state.copyWith(loading: false, items: items)),
    );
  }
}
