import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/config/auth_router_refresh.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/core/push/push_service.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/auth/domain/auth_repository.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo, this._push, this._api) : super(const AuthState()) {
    _api.onAccountBlocked = handleAccountBlocked;
  }

  final AuthRepository _repo;
  final PushService _push;
  final ApiClient _api;
  bool _handlingBlock = false;

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    final prev = change.currentState;
    final next = change.nextState;
    if (prev.status != next.status ||
        prev.isNewUser != next.isNewUser ||
        prev.pendingPhone != next.pendingPhone ||
        prev.user?.id != next.user?.id ||
        prev.user?.needsRole != next.user?.needsRole ||
        prev.user?.needsProviderOnboarding !=
            next.user?.needsProviderOnboarding ||
        prev.user?.providerApprovalStatus !=
            next.user?.providerApprovalStatus) {
      notifyAuthRouter();
    }
  }

  Future<void> bootstrap() async {
    final result = await _repo.bootstrap();
    if (isClosed) return;
    // User already started OTP while /me was in flight — don't restore over it.
    if (state.pendingPhone != null && state.pendingPhone!.isNotEmpty) return;

    result.fold(
      (f) {
        if (f is AccountBlockedFailure) {
          emit(AuthState(
            status: AuthStatus.unauthenticated,
            message: f.message,
            accountBlocked: true,
          ));
        } else {
          emit(const AuthState(status: AuthStatus.unauthenticated));
        }
      },
      (user) {
        if (state.pendingPhone != null && state.pendingPhone!.isNotEmpty) {
          return;
        }
        if (user.isBlocked) {
          handleAccountBlocked(
            user.profileStatusLabel ?? t('web.auth.blocked_body'),
          );
          return;
        }
        emit(AuthState(status: AuthStatus.authenticated, user: user));
        unawaited(_push.register());
      },
    );
  }

  Future<bool> sendOtp(String phone) async {
    // Always start a clean OTP flow — never keep a stale Sanctum session
    // that would make GoRouter skip /otp → /search.
    await _repo.clearLocalSession();
    emit(AuthState(
      status: AuthStatus.unauthenticated,
      pendingPhone: phone,
      loading: true,
    ));
    final result = await _repo.sendOtp(phone);
    return result.fold(
      (f) {
        emit(state.copyWith(
          loading: false,
          message: f.message,
          accountBlocked: f is AccountBlockedFailure,
        ));
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
        emit(state.copyWith(
          loading: false,
          message: f.message,
          accountBlocked: f is AccountBlockedFailure,
        ));
        return false;
      },
      (data) {
        if (data.user.isBlocked) {
          handleAccountBlocked(
            data.user.profileStatusLabel ?? t('web.auth.blocked_body'),
          );
          return false;
        }
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

  Future<bool> resubmitProviderReview() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.resubmitProviderReview();
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

  void handleAccountBlocked([String? message]) {
    if (_handlingBlock) return;
    _handlingBlock = true;
    final msg = message ?? t('web.auth.blocked_body');
    unawaited(_push.unregister());
    emit(AuthState(
      status: AuthStatus.unauthenticated,
      message: msg,
      accountBlocked: true,
    ));
    unawaited(_repo.logout().whenComplete(() {
      _handlingBlock = false;
    }));
  }

  Future<void> logout() async {
    await _push.unregister();
    emit(const AuthState(status: AuthStatus.unauthenticated));
    await _repo.logout();
  }

  void clearAccountBlockedFlag() {
    if (state.accountBlocked) {
      emit(state.copyWith(accountBlocked: false, clearMessage: true));
    }
  }
}
