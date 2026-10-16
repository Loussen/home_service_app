import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/remote/bootstrap_model.dart';
import 'package:home_service_app/core/utils/json_numbers.dart';
import 'package:home_service_app/features/wallet/data/wallet_iap_service.dart';
import 'package:home_service_app/features/wallet/domain/wallet_repository.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class WalletState {
  const WalletState({
    this.balance = 0,
    this.transactions = const [],
    this.packages = const [],
    this.storeProducts = const {},
    this.loading = false,
    this.purchasingProductId,
    this.message,
    this.storeReady = false,
    this.storeHint,
  });

  final double balance;
  final List<dynamic> transactions;
  final List<WalletIapProduct> packages;
  final Map<String, ProductDetails> storeProducts;
  final bool loading;
  final String? purchasingProductId;
  final String? message;
  final bool storeReady;
  /// Why Play/App Store prices are missing (testers / signing / notFound).
  final String? storeHint;

  WalletState copyWith({
    double? balance,
    List<dynamic>? transactions,
    List<WalletIapProduct>? packages,
    Map<String, ProductDetails>? storeProducts,
    bool? loading,
    String? purchasingProductId,
    bool clearPurchasing = false,
    String? message,
    bool? storeReady,
    String? storeHint,
    bool clearStoreHint = false,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      packages: packages ?? this.packages,
      storeProducts: storeProducts ?? this.storeProducts,
      loading: loading ?? this.loading,
      purchasingProductId: clearPurchasing
          ? null
          : (purchasingProductId ?? this.purchasingProductId),
      message: message,
      storeReady: storeReady ?? this.storeReady,
      storeHint: clearStoreHint ? null : (storeHint ?? this.storeHint),
    );
  }
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repo, this._iap) : super(const WalletState()) {
    _iap.listen(_onStorePurchase);
  }

  final WalletRepository _repo;
  final WalletIapService _iap;
  final Set<String> _handled = {};

  Future<void> load() async {
    emit(state.copyWith(loading: true, message: null));
    final bal = await _repo.balance();
    final tx = await _repo.transactions();

    final b = bal.fold((f) => null, (d) => d);
    final txs = tx.fold((f) => <dynamic>[], (d) => d);

    if (b == null) {
      emit(state.copyWith(loading: false, message: t('wallet.load_failed')));
      return;
    }

    final packages = _resolvePackages(b);
    var storeProducts = <String, ProductDetails>{};
    var storeReady = false;
    String? storeHint;
    if (_iap.isMobileStore) {
      storeReady = await _iap.isAvailable();
      if (!storeReady) {
        storeHint = t('wallet.store_unavailable');
      } else if (packages.isNotEmpty) {
        final ids = packages.map((e) => e.productId).toSet();
        final q = await _iap.queryProducts(ids);
        storeProducts = q.products;
        if (storeProducts.isEmpty) {
          final missing = q.notFound.isEmpty
              ? ids.join(', ')
              : q.notFound.join(', ');
          storeHint = q.error != null && q.error!.isNotEmpty
              ? q.error
              : t('wallet.products_not_found', params: {'ids': missing});
        } else if (q.notFound.isNotEmpty) {
          storeHint = t('wallet.products_partial', params: {
            'ids': q.notFound.join(', '),
          });
        }
      }
    }

    emit(state.copyWith(
      loading: false,
      balance: parseDouble(b['balance']),
      transactions: txs,
      packages: packages,
      storeProducts: storeProducts,
      storeReady: storeReady,
      storeHint: storeHint,
      clearStoreHint: storeHint == null,
    ));
  }

  List<WalletIapProduct> _resolvePackages(Map<String, dynamic> balancePayload) {
    final fromApi = balancePayload['iap_products'];
    if (fromApi is List) {
      final parsed = fromApi
          .whereType<Map>()
          .map((e) => WalletIapProduct.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.productId.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    final boot = AppRemoteConfig.instance.payload.config.walletIapProducts;
    if (boot.isNotEmpty) return boot;
    // Fallback SKUs if bootstrap/API not refreshed yet.
    return const [
      WalletIapProduct(productId: 'mysancho_wallet_10', pay: 10, credit: 10),
      WalletIapProduct(productId: 'mysancho_wallet_30', pay: 30, credit: 36),
      WalletIapProduct(productId: 'mysancho_wallet_50', pay: 50, credit: 65),
    ];
  }

  Future<void> buyPackage(WalletIapProduct package) async {
    if (state.purchasingProductId != null) return;
    if (!_iap.isMobileStore || !state.storeReady) {
      emit(state.copyWith(message: t('wallet.store_unavailable')));
      return;
    }
    final product = state.storeProducts[package.productId];
    if (product == null) {
      emit(state.copyWith(message: t('wallet.product_missing')));
      return;
    }
    emit(state.copyWith(
      purchasingProductId: package.productId,
      message: null,
    ));
    try {
      final started = await _iap.buy(product);
      if (!started) {
        emit(state.copyWith(
          clearPurchasing: true,
          message: t('wallet.purchase_failed'),
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        clearPurchasing: true,
        message: t('wallet.purchase_failed'),
      ));
    }
  }

  Future<void> _onStorePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      return;
    }

    if (purchase.status == PurchaseStatus.canceled) {
      emit(state.copyWith(clearPurchasing: true));
      await _iap.complete(purchase);
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      emit(state.copyWith(
        clearPurchasing: true,
        message: purchase.error?.message ?? t('wallet.purchase_failed'),
      ));
      await _iap.complete(purchase);
      return;
    }

    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }

    final key =
        '${purchase.productID}:${purchase.purchaseID ?? purchase.verificationData.serverVerificationData}';
    if (_handled.contains(key)) {
      await _iap.complete(purchase);
      return;
    }
    _handled.add(key);

    final platform = (!kIsWeb && Platform.isIOS) ? 'ios' : 'android';
    final result = await _repo.confirmIap(
      platform: platform,
      productId: purchase.productID,
      verificationData: purchase.verificationData.serverVerificationData,
      purchaseId: purchase.purchaseID,
    );

    await _iap.complete(purchase);

    await result.fold(
      (f) async {
        emit(state.copyWith(
          clearPurchasing: true,
          message: f.message.isNotEmpty ? f.message : t('wallet.purchase_failed'),
        ));
      },
      (data) async {
        emit(state.copyWith(
          clearPurchasing: true,
          balance: parseDouble(data['balance']),
          message: t('wallet.purchase_ok'),
        ));
        final tx = await _repo.transactions();
        tx.fold((_) {}, (list) {
          emit(state.copyWith(transactions: list, message: t('wallet.purchase_ok')));
        });
      },
    );
  }

  @override
  Future<void> close() async {
    await _iap.dispose();
    return super.close();
  }
}
