import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/utils/json_numbers.dart';
import 'package:home_service_app/features/wallet/domain/wallet_repository.dart';

class WalletState {
  const WalletState({
    this.balance = 0,
    this.transactions = const [],
    this.loading = false,
    this.message,
  });

  final double balance;
  final List<dynamic> transactions;
  final bool loading;
  final String? message;

  WalletState copyWith({
    double? balance,
    List<dynamic>? transactions,
    bool? loading,
    String? message,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      loading: loading ?? this.loading,
      message: message,
    );
  }
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repo) : super(const WalletState());

  final WalletRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final bal = await _repo.balance();
    final tx = await _repo.transactions();

    final b = bal.fold((f) => null, (d) => d);
    final txs = tx.fold((f) => <dynamic>[], (d) => d);

    if (b == null) {
      emit(state.copyWith(loading: false, message: t('wallet.load_failed')));
      return;
    }

    emit(state.copyWith(
      loading: false,
      balance: parseDouble(b['balance']),
      transactions: txs,
    ));
  }
}
