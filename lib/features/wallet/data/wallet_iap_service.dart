import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

typedef WalletIapPurchaseHandler = Future<void> Function(PurchaseDetails purchase);

/// Thin StoreKit / Play Billing wrapper. Server credits via verification_data.
class WalletIapService {
  WalletIapService();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  WalletIapPurchaseHandler? _onPurchase;

  bool get isMobileStore => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<bool> isAvailable() async {
    if (!isMobileStore) return false;
    return _iap.isAvailable();
  }

  void listen(WalletIapPurchaseHandler onPurchase) {
    _onPurchase = onPurchase;
    _sub ??= _iap.purchaseStream.listen(_handlePurchases);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _onPurchase = null;
  }

  /// Returns store products plus any query error / missing IDs (for debug UI).
  Future<({
    Map<String, ProductDetails> products,
    String? error,
    Set<String> notFound,
  })> queryProducts(Set<String> ids) async {
    if (ids.isEmpty) {
      return (products: <String, ProductDetails>{}, error: null, notFound: <String>{});
    }
    final resp = await _iap.queryProductDetails(ids);
    final products = {for (final p in resp.productDetails) p.id: p};
    final err = resp.error;
    final errorText = err == null
        ? null
        : '${err.code}: ${err.message}'.trim();
    return (
      products: products,
      error: errorText,
      notFound: resp.notFoundIDs.toSet(),
    );
  }

  Future<bool> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    final handler = _onPurchase;
    if (handler == null) return;
    for (final p in purchases) {
      await handler(p);
    }
  }
}
