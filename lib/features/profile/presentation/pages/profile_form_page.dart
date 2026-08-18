import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_cubit.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_state.dart';
import 'package:home_service_app/features/profile/presentation/widgets/audio_intro_recorder.dart';
import 'package:home_service_app/features/profile/presentation/widgets/work_location_picker.dart';
import 'package:home_service_app/features/profile/presentation/widgets/schedule_matrix.dart';
import 'package:home_service_app/features/profile/presentation/widgets/searchable_category_picker.dart';

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
            SnackBar(content: Text(t('profile.form.saved'))),
          );
          context.pop(true);
        }
      },
      builder: (context, state) {
        final cubit = context.read<ProfileFormCubit>();
        final isEdit = state.profileId != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isEdit ? t('profile.form.edit_title') : t('profile.form.new_title'),
            ),
          ),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SearchableCategoryPicker(
                      categories: state.categories,
                      selectedIds: state.categoryIds,
                      onChanged: cubit.setCategoryIds,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.title,
                      decoration: InputDecoration(
                        labelText: t('profile.form.title_label'),
                        hintText: t('onboarding.title_hint'),
                      ),
                      onChanged: cubit.setTitle,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.bio,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: t('profile.form.bio_label'),
                      ),
                      onChanged: cubit.setBio,
                    ),
                    const SizedBox(height: 12),
                    WorkLocationPicker(
                      cities: state.locations,
                      cityId: state.cityId,
                      districtId: state.districtId,
                      latitude: state.latitude,
                      longitude: state.longitude,
                      onCity: cubit.setCityId,
                      onDistrict: cubit.setDistrictId,
                      onCoordinates: cubit.setCoordinates,
                      onPlaceResolved: cubit.applyPlace,
                      onUseGps: cubit.useCurrentLocation,
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
                        state.saving
                            ? t('profile.form.saving')
                            : t('profile.form.save'),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
