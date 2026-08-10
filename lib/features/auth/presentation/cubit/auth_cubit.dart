import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/auth/domain/auth_repository.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> bootstrap() async {
    final result = await _repo.bootstrap();
    result.fold(
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
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
      (user) {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
        return true;
      },
    );
  }

  Future<void> setRole(String role) async {
    emit(state.copyWith(loading: true));
    final result = await _repo.setRole(role);
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (user) => emit(state.copyWith(
        loading: false,
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
