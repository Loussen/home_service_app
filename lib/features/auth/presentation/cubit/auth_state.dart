import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/auth/data/models/user_model.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.pendingPhone,
    this.message,
    this.loading = false,
    this.isNewUser = false,
    this.accountBlocked = false,
  });

  final AuthStatus status;
  final UserModel? user;
  final String? pendingPhone;
  final String? message;
  final bool loading;
  final bool isNewUser;
  final bool accountBlocked;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? pendingPhone,
    String? message,
    bool? loading,
    bool? isNewUser,
    bool? accountBlocked,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      message: clearMessage ? null : (message ?? this.message),
      loading: loading ?? this.loading,
      isNewUser: isNewUser ?? this.isNewUser,
      accountBlocked: accountBlocked ?? this.accountBlocked,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        pendingPhone,
        message,
        loading,
        isNewUser,
        accountBlocked,
      ];
}
