import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/chat/data/models/conversation_model.dart';

class ChatThreadState extends Equatable {
  const ChatThreadState({
    this.loading = false,
    this.sending = false,
    this.conversation,
    this.message,
  });

  final bool loading;
  final bool sending;
  final ConversationModel? conversation;
  final String? message;

  ChatThreadState copyWith({
    bool? loading,
    bool? sending,
    ConversationModel? conversation,
    String? message,
    bool clearMessage = false,
  }) {
    return ChatThreadState(
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      conversation: conversation ?? this.conversation,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [loading, sending, conversation, message];
}
