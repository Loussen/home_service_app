import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';

class ChatListState extends Equatable {
  const ChatListState({
    this.loading = false,
    this.items = const [],
    this.message,
  });

  final bool loading;
  final List<ConversationModel> items;
  final String? message;

  ChatListState copyWith({
    bool? loading,
    List<ConversationModel>? items,
    String? message,
    bool clearMessage = false,
  }) {
    return ChatListState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [loading, items, message];
}
