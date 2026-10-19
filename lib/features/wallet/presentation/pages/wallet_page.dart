import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/app/widgets/ms_widgets.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/core/remote/bootstrap_model.dart';
import 'package:home_service_app/features/wallet/presentation/cubit/wallet_cubit.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WalletCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: Text(t('wallet.title'))),
        body: BlocConsumer<WalletCubit, WalletState>(
          listenWhen: (p, c) => c.message != null && c.message != p.message,
          listener: (context, state) {
            final msg = state.message;
            if (msg == null || msg.isEmpty) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          },
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                MsCard(
                  color: AppColors.parchment,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('wallet.title'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.balance.toStringAsFixed(2)} AZN',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                MsSectionTitle(t('wallet.packages')),
                const SizedBox(height: 12),
                for (final pkg in state.packages) ...[
                  _PackageTile(
                    package: pkg,
                    storePrice: state.storeProducts[pkg.productId]?.price,
                    busy: state.purchasingProductId == pkg.productId,
                    enabled: state.purchasingProductId == null &&
                        state.storeReady &&
                        state.storeProducts.containsKey(pkg.productId),
                    popular: pkg.pay == 30,
                    onBuy: () => context.read<WalletCubit>().buyPackage(pkg),
                  ),
                  const SizedBox(height: 10),
                ],
                if (state.storeHint != null && state.storeHint!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      state.storeHint!,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 8),
                MsSectionTitle(t('wallet.transactions')),
                const SizedBox(height: 12),
                if (state.transactions.isEmpty)
                  MsCard(
                    child: Text(
                      t('wallet.empty'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                else
                  MsCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < state.transactions.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          Builder(
                            builder: (context) {
                              final map =
                                  state.transactions[i] as Map<String, dynamic>;
                              final type = '${map['type'] ?? ''}';
                              final status = '${map['status'] ?? ''}';
                              return ListTile(
                                title: Text(_walletTxLabel(type)),
                                subtitle: Text(_walletStatusLabel(status)),
                                trailing: Text(
                                  '${map['amount']} ₼',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _walletTxLabel(String type) {
  final key = 'wallet.tx.$type';
  final label = t(key);
  return label == key ? type : label;
}

String _walletStatusLabel(String status) {
  final key = 'wallet.status.$status';
  final label = t(key);
  return label == key ? status : label;
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.onBuy,
    required this.busy,
    required this.enabled,
    required this.popular,
    this.storePrice,
  });

  final WalletIapProduct package;
  final VoidCallback onBuy;
  final bool busy;
  final bool enabled;
  final bool popular;
  final String? storePrice;

  @override
  Widget build(BuildContext context) {
    final payLabel = storePrice ??
        t('wallet.buy_pay', params: {
          'pay': package.pay.toStringAsFixed(
            package.pay == package.pay.roundToDouble() ? 0 : 2,
          ),
        });
    final creditLabel = t('wallet.credit_gets', params: {
      'credit': package.credit.toStringAsFixed(
        package.credit == package.credit.roundToDouble() ? 0 : 2,
      ),
    });

    return MsCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        creditLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (popular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.peach,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t('wallet.popular'),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  payLabel,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: enabled && !busy ? onBuy : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(72, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t('wallet.buy')),
          ),
        ],
      ),
    );
  }
}
