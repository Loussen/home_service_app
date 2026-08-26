import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/app/widgets/ms_widgets.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
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
        body: BlocBuilder<WalletCubit, WalletState>(
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
                              return ListTile(
                                title: Text('${map['type']}'),
                                subtitle: Text('${map['status']}'),
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
