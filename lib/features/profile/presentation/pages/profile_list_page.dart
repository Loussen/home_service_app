import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_list_cubit.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_list_state.dart';

class ProfileListPage extends StatelessWidget {
  const ProfileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileListCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Xidmət profilləri')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/profiles/new');
            if (context.mounted) {
              context.read<ProfileListCubit>().load();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Yeni profil'),
        ),
        body: BlocConsumer<ProfileListCubit, ProfileListState>(
          listener: (context, state) {
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
          },
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.profiles.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Hələ profil yoxdur.\nDayə, təmizlikçi və s. üçün ayrıca profil yaradın.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<ProfileListCubit>().load(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: state.profiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = state.profiles[index];
                  return Card(
                    child: ListTile(
                      title: Text(p.title?.isNotEmpty == true
                          ? p.title!
                          : (p.category?.nameAz ?? 'Profil')),
                      subtitle: Text([
                        p.category?.nameAz,
                        if (p.district?.isNotEmpty == true) p.district,
                        if (p.isVerified) '✓ Verified',
                        if (p.isVip) 'VIP',
                        '${p.schedules.where((s) => s.isAvailable).length} slot',
                      ].whereType<String>().join(' · ')),
                      isThreeLine: true,
                      onTap: () async {
                        await context.push('/profiles/${p.id}');
                        if (context.mounted) {
                          context.read<ProfileListCubit>().load();
                        }
                      },
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          final cubit = context.read<ProfileListCubit>();
                          if (value == 'bump') {
                            final balance = await cubit.bump(p.id);
                            if (balance != null && context.mounted) {
                              context.read<AuthCubit>().bootstrap();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Yuxarı qaldırıldı. Balans: ${balance.toStringAsFixed(2)} AZN',
                                  ),
                                ),
                              );
                            }
                          } else if (value == 'delete') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Silinsin?'),
                                content: const Text('Bu profil silinəcək.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Xeyr'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Bəli'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) await cubit.delete(p.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'bump',
                            child: Text('Bump-up (balansdan)'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Sil'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
