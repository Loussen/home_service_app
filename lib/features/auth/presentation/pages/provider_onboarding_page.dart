import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_service_app/app/config/app_colors.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:home_service_app/app/di/injection.dart';
import 'package:home_service_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/data/models/location_models.dart';
import 'package:home_service_app/features/profile/data/places_client.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_cubit.dart';
import 'package:home_service_app/features/profile/presentation/cubit/profile_form_state.dart';
import 'package:home_service_app/features/profile/presentation/widgets/audio_intro_recorder.dart';
import 'package:home_service_app/features/profile/presentation/widgets/schedule_matrix.dart';
import 'package:home_service_app/features/profile/presentation/widgets/searchable_category_picker.dart';
import 'package:home_service_app/features/profile/presentation/widgets/work_location_picker.dart';

class ProviderOnboardingPage extends StatelessWidget {
  const ProviderOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileFormCubit>()..init(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _page = PageController();
  final _name = TextEditingController();
  int _step = 0;

  List<String> get _titles {
    final fromRemote = AppRemoteConfig.instance.config.onboardingSteps
        .map((s) => s.title)
        .where((s) => s.isNotEmpty)
        .toList();
    if (fromRemote.length >= 5) return fromRemote;
    return [
      t('onboarding.step.name'),
      t('onboarding.step.categories'),
      t('onboarding.step.location'),
      t('onboarding.step.schedule'),
      t('onboarding.step.about'),
    ];
  }

  int get _stepCount => _titles.length;

  @override
  void initState() {
    super.initState();
    _name.text = context.read<AuthCubit>().state.user?.name ?? '';
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _next(ProfileFormState form) async {
    if (_step == 0 && _name.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('onboarding.name_required'))),
      );
      return;
    }
    if (_step == 1 && form.categoryIds.isEmpty) {
      final max = AppRemoteConfig.instance.config.maxCategoryTags;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('category.min_one', params: {'max': '$max'}))),
      );
      return;
    }
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      await _page.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    await context.read<AuthCubit>().updateName(_name.text.trim());
    final ok = await context.read<ProfileFormCubit>().save();
    if (ok && mounted) context.go('/search');
  }

  void _back() {
    if (_step == 0) {
      context.go('/search');
      return;
    }
    setState(() => _step--);
    _page.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileFormCubit, ProfileFormState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, form) {
        final cubit = context.read<ProfileFormCubit>();
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_step + 1) / _stepCount,
                            minHeight: 8,
                            backgroundColor: AppColors.peach,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/search'),
                        child: Text(t('onboarding.skip')),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _titles[_step],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: form.loading
                      ? const Center(child: CircularProgressIndicator())
                      : PageView(
                          controller: _page,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _NameStep(controller: _name),
                            _CategoryStep(
                              categories: form.categories,
                              selectedIds: form.categoryIds,
                              onChanged: cubit.setCategoryIds,
                            ),
                            _LocationStep(
                              cities: form.locations,
                              cityId: form.cityId,
                              districtId: form.districtId,
                              lat: form.latitude,
                              lng: form.longitude,
                              onCity: cubit.setCityId,
                              onDistrict: cubit.setDistrictId,
                              onGps: cubit.useCurrentLocation,
                              onCoordinates: cubit.setCoordinates,
                              onPlace: cubit.applyPlace,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: SingleChildScrollView(
                                child: ScheduleMatrix(
                                  values: form.schedules,
                                  onToggle: cubit.toggleSlot,
                                ),
                              ),
                            ),
                            _AboutStep(
                              title: form.title,
                              bio: form.bio,
                              audioUrl: form.audioIntroUrl,
                              localPath: form.localAudioPath,
                              onTitle: cubit.setTitle,
                              onBio: cubit.setBio,
                              onAudio: (p) => cubit.setLocalAudio(p),
                            ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: ElevatedButton(
                    onPressed: form.saving ? null : () => _next(form),
                    child: Text(
                      form.saving
                          ? t('onboarding.saving')
                          : (_step == _stepCount - 1
                              ? t('onboarding.create_profile')
                              : t('onboarding.continue')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        Text(
          t('onboarding.name_hint'),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: t('onboarding.name_label'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
      ],
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<CategoryModel> categories;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SearchableCategoryPicker(
        categories: categories,
        selectedIds: selectedIds,
        onChanged: onChanged,
        embedded: true,
        max: AppRemoteConfig.instance.config.maxCategoryTags,
      ),
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.cities,
    required this.cityId,
    required this.districtId,
    required this.lat,
    required this.lng,
    required this.onCity,
    required this.onDistrict,
    required this.onGps,
    required this.onCoordinates,
    required this.onPlace,
  });

  final List<CityModel> cities;
  final int? cityId;
  final int? districtId;
  final double lat;
  final double lng;
  final ValueChanged<int> onCity;
  final ValueChanged<int> onDistrict;
  final VoidCallback onGps;
  final void Function(double lat, double lng) onCoordinates;
  final ValueChanged<ResolvedPlace> onPlace;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        Text(
          t('onboarding.location_hint'),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        WorkLocationPicker(
          cities: cities,
          cityId: cityId,
          districtId: districtId,
          latitude: lat,
          longitude: lng,
          onCity: onCity,
          onDistrict: onDistrict,
          onCoordinates: onCoordinates,
          onPlaceResolved: onPlace,
          onUseGps: onGps,
        ),
      ],
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep({
    required this.title,
    required this.bio,
    required this.audioUrl,
    required this.localPath,
    required this.onTitle,
    required this.onBio,
    required this.onAudio,
  });

  final String title;
  final String bio;
  final String? audioUrl;
  final String? localPath;
  final ValueChanged<String> onTitle;
  final ValueChanged<String> onBio;
  final ValueChanged<String> onAudio;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        TextFormField(
          initialValue: title,
          decoration: InputDecoration(
            labelText: t('onboarding.title_label'),
            hintText: t('onboarding.title_hint'),
          ),
          onChanged: onTitle,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: bio,
          maxLines: 3,
          decoration: InputDecoration(labelText: t('onboarding.about_label')),
          onChanged: onBio,
        ),
        const SizedBox(height: 16),
        AudioIntroRecorder(
          existingUrl: audioUrl,
          localPath: localPath,
          onRecorded: onAudio,
        ),
      ],
    );
  }
}
