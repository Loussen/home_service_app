import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_cubit.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_state.dart';
import 'package:home_service_app/features/profile/presentation/widgets/audio_intro_recorder.dart';
import 'package:home_service_app/features/profile/presentation/widgets/schedule_matrix.dart';

class ProfileFormPage extends StatelessWidget {
  const ProfileFormPage({super.key, this.profileId});

  final int? profileId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileFormCubit>(param1: profileId)..init(),
      child: const _ProfileFormView(),
    );
  }
}

class _ProfileFormView extends StatelessWidget {
  const _ProfileFormView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileFormCubit, ProfileFormState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
        if (state.savedProfile != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil yadda saxlanıldı')),
          );
          context.pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<ProfileFormCubit>();
        final isEdit = state.profileId != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Profil redaktə' : 'Yeni profil'),
          ),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey(state.categoryId),
                      initialValue: state.categoryId,
                      decoration: const InputDecoration(labelText: 'Kateqoriya'),
                      items: state.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nameAz),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) cubit.setCategory(v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.title,
                      decoration: const InputDecoration(
                        labelText: 'Başlıq',
                        hintText: 'məs. Təcrübəli dayə',
                      ),
                      onChanged: cubit.setTitle,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.bio,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Haqqında',
                      ),
                      onChanged: cubit.setBio,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: state.city,
                            decoration: const InputDecoration(labelText: 'Şəhər'),
                            onChanged: cubit.setCity,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: state.district,
                            decoration:
                                const InputDecoration(labelText: 'Rayon'),
                            onChanged: cubit.setDistrict,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.my_location),
                      title: Text(
                        '${state.latitude.toStringAsFixed(5)}, ${state.longitude.toStringAsFixed(5)}',
                      ),
                      subtitle: const Text('İşə çıxdığınız məkan'),
                      trailing: TextButton(
                        onPressed: cubit.useCurrentLocation,
                        child: const Text('Yenilə'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ScheduleMatrix(
                      values: state.schedules,
                      onToggle: cubit.toggleSlot,
                    ),
                    const SizedBox(height: 16),
                    AudioIntroRecorder(
                      existingUrl: state.audioIntroUrl,
                      localPath: state.localAudioPath,
                      onRecorded: cubit.setLocalAudio,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.saving
                          ? null
                          : () => cubit.save(),
                      child: Text(
                        state.saving ? 'Saxlanılır...' : 'Yadda saxla',
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
