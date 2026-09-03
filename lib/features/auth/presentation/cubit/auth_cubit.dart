import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/core/push/push_service.dart';
import 'package:home_service_app/features/auth/domain/auth_repository.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo, this._push) : super(const AuthState());

  final AuthRepository _repo;
  final PushService _push;

  Future<void> bootstrap() async {
    final result = await _repo.bootstrap();
    result.fold(
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
      (user) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
        unawaited(_push.register());
      },
    );
  }

  Future<bool> sendOtp(String phone) async {
    emit(state.copyWith(loading: true, clearMessage: true, pendingPhone: phone));
    final result = await _repo.sendOtp(phone);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, message: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false));
        return true;
      },
    );
  }

  Future<bool> verifyOtp(String code) async {
    final phone = state.pendingPhone;
    if (phone == null) return false;

    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.verifyOtp(phone, code);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, message: f.message));
        return false;
      },
      (data) {
        emit(AuthState(
          status: AuthStatus.authenticated,
          user: data.user,
          isNewUser: data.isNew,
        ));
        unawaited(_push.register());
        return true;
      },
    );
  }

  Future<bool> setRole(String role) async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.setRole(role);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, message: f.message));
        return false;
      },
      (user) {
        emit(state.copyWith(
          loading: false,
          status: AuthStatus.authenticated,
          user: user,
          isNewUser: false,
        ));
        return true;
      },
    );
  }

  Future<void> updateName(String name) async {
    final result = await _repo.updateProfile(name: name.trim());
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (user) => emit(state.copyWith(user: user)),
    );
  }

  Future<bool> uploadAvatar(String filePath) async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.uploadAvatar(filePath);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, message: f.message));
        return false;
      },
      (user) {
        emit(state.copyWith(loading: false, user: user));
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _push.unregister();
    emit(const AuthState(status: AuthStatus.unauthenticated));
    await _repo.logout();
  }
}
