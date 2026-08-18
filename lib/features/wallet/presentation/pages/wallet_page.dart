import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/features/wallet/presentation/cubit/wallet_cubit.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WalletCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(t('wallet.title'))),
        body: BlocBuilder<WalletCubit, WalletState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${state.balance.toStringAsFixed(2)} AZN',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 24),
                Text(t('wallet.transactions'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (state.transactions.isEmpty)
                  Text(t('wallet.empty'))
                else
                  ...state.transactions.map((t) {
                    final map = t as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${map['type']}'),
                      subtitle: Text('${map['status']}'),
                      trailing: Text('${map['amount']} ₼'),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
