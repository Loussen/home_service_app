import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
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
          context.read<AuthCubit>().bootstrap();
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
                    _AvailabilitySection(
                      fullThisWeek: state.fullThisWeek,
                      quietStart: state.quietHoursStart,
                      quietEnd: state.quietHoursEnd,
                      onFullChanged: cubit.setFullThisWeek,
                      onQuietChanged: cubit.setQuietHours,
                    ),
                    const SizedBox(height: 16),
                    AudioIntroRecorder(
                      existingUrl: state.audioIntroUrl,
                      localPath: state.localAudioPath,
                      onRecorded: cubit.setLocalAudio,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.saving
                            ? null
                            : () => cubit.save(),
                        child: Text(
                          state.saving
                              ? t('profile.form.saving')
                              : t('profile.form.save'),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({
    required this.fullThisWeek,
    required this.quietStart,
    required this.quietEnd,
    required this.onFullChanged,
    required this.onQuietChanged,
  });

  final bool fullThisWeek;
  final String? quietStart;
  final String? quietEnd;
  final ValueChanged<bool> onFullChanged;
  final void Function(String? start, String? end) onQuietChanged;

  static const _presets = <(String, String)>[
    ('22:00', '08:00'),
    ('21:00', '09:00'),
  ];

  bool _presetSelected(String start, String end) =>
      quietStart == start && quietEnd == end;

  Future<void> _pickCustom(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      initialTime: _parse(quietStart) ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _parse(quietEnd) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (end == null || !context.mounted) return;
    onQuietChanged(_fmt(start), _fmt(end));
  }

  TimeOfDay? _parse(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final hasQuiet = quietStart != null && quietEnd != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('profile.availability.title'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('profile.availability.full_week')),
          subtitle: Text(t('profile.availability.full_week_hint')),
          value: fullThisWeek,
          onChanged: onFullChanged,
        ),
        const SizedBox(height: 4),
        Text(
          t('profile.availability.quiet'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          t('profile.availability.quiet_hint'),
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(t('profile.availability.quiet_none')),
              selected: !hasQuiet,
              selectedColor: AppColors.skySoft,
              onSelected: (_) => onQuietChanged(null, null),
            ),
            for (final preset in _presets)
              ChoiceChip(
                label: Text('${preset.$1}–${preset.$2}'),
                selected: _presetSelected(preset.$1, preset.$2),
                selectedColor: AppColors.peach,
                onSelected: (selected) => onQuietChanged(
                  selected ? preset.$1 : null,
                  selected ? preset.$2 : null,
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.schedule, size: 16),
              label: Text(
                hasQuiet &&
                        !_presets.any((p) => _presetSelected(p.$1, p.$2))
                    ? '$quietStart–$quietEnd'
                    : t('profile.availability.quiet_custom'),
              ),
              onPressed: () => _pickCustom(context),
            ),
          ],
        ),
      ],
    );
  }
}
