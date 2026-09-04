import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/core/remote/app_remote_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
import 'package:home_service_app/features/profile/domain/profile_repository.dart';
import 'package:home_service_app/features/search_ai/domain/search_repository.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SearchAiCubit extends Cubit<SearchAiState> {
  SearchAiCubit(this._repo, this._profiles) : super(const SearchAiState());

  final SearchRepository _repo;
  final ProfileRepository _profiles;
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _recordTimer;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  int _lastAudioSeconds = 0;

  Future<void> init() async {
    emit(state.copyWith(phase: SearchPhase.locating, clearMessage: true));
    await Future.wait([
      _resolveLocation(),
      _loadCategories(),
    ]);
    emit(state.copyWith(phase: SearchPhase.idle));
  }

  Future<void> _loadCategories() async {
    final result = await _profiles.categories();
    result.fold(
      (_) {},
      (cats) => emit(state.copyWith(categories: cats)),
    );
  }

  /// Re-fetch category tree after language change (localized `name` + names).
  Future<void> reloadCategories() => _loadCategories();

  void setCategory(int? id) => emit(state.copyWith(
        selectedCategoryId: id,
        clearCategory: id == null,
      ));

  void setScheduledAt(DateTime? value) => emit(state.copyWith(
        scheduledAt: value,
        clearSchedule: value == null,
      ));

  void setTimeSlot(String? slot) => emit(state.copyWith(
        timeSlot: slot,
        clearTimeSlot: slot == null,
      ));
  void setChildAge(int? age) => emit(state.copyWith(
        childAge: age,
        clearChildAge: age == null,
      ));
  void setHasPet(bool? hasPet) => emit(state.copyWith(
        hasPet: hasPet,
        clearHasPet: hasPet == null,
      ));
  void setBudgetMax(double? budget) => emit(state.copyWith(
        budgetMax: budget,
        clearBudgetMax: budget == null,
      ));

  void setText(String value) => emit(state.copyWith(text: value));

  void setLocation(double lat, double lng, String? address) {
    emit(state.copyWith(latitude: lat, longitude: lng, address: address));
  }

  void setUrgent(bool value) => emit(state.copyWith(isUrgent: value));

  Future<void> _resolveLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      emit(state.copyWith(latitude: pos.latitude, longitude: pos.longitude));
    } catch (_) {
      // keep Baku default
    }
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await _stopRecording();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      emit(state.copyWith(
        phase: SearchPhase.error,
        message: t('search.mic_required'),
      ));
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/request_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    emit(state.copyWith(
      isRecording: true,
      phase: SearchPhase.recording,
      recordSeconds: 0,
      clearAudio: true,
      clearMessage: true,
    ));

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.recordSeconds + 1;
      emit(state.copyWith(recordSeconds: next));
      if (next >= 20) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final seconds = state.recordSeconds;
    final path = await _recorder.stop();
    emit(state.copyWith(
      isRecording: false,
      phase: SearchPhase.idle,
      localAudioPath: path,
      recordSeconds: 0,
    ));
    if (path == null) return;
    if (seconds < 5) {
      emit(state.copyWith(
        phase: SearchPhase.error,
        message: t('web.request.voice_too_short', params: {'sec': '5'}),
        clearAudio: true,
      ));
      return;
    }
    _lastAudioSeconds = seconds.clamp(5, 20);
    await submit();
  }

  Future<void> submit() async {
    final hasAudio = state.localAudioPath != null;
    var text = state.text.trim();
    final hasText = text.isNotEmpty;
    final hasCategory = state.selectedCategoryId != null;

    if (!hasAudio && !hasText && !hasCategory) {
      emit(state.copyWith(
        phase: SearchPhase.error,
        message: t('search.input_required'),
      ));
      return;
    }

    if (!hasAudio && !hasText && hasCategory) {
      final cat = state.categories
          .expand((c) => CategoryModel.flatten([c]))
          .map((e) => e.$1)
          .where((c) => c.id == state.selectedCategoryId)
          .firstOrNull;
      text = cat?.displayName ?? t('search.category_fallback');
    }

    emit(state.copyWith(
      phase: SearchPhase.submitting,
      clearMessage: true,
      clearRequest: true,
    ));

    final result = hasAudio
        ? await _repo.submitAudio(
            filePath: state.localAudioPath!,
            latitude: state.latitude,
            longitude: state.longitude,
            address: state.address,
            isUrgent: state.isUrgent,
            categoryId: state.selectedCategoryId,
            scheduledAt: state.scheduledAt,
            timeSlot: state.timeSlot,
            childAge: state.childAge,
            hasPet: state.hasPet,
            budgetMax: state.budgetMax,
            durationSeconds: _lastAudioSeconds > 0 ? _lastAudioSeconds : null,
          )
        : await _repo.submitText(
            text: text,
            latitude: state.latitude,
            longitude: state.longitude,
            categoryId: state.selectedCategoryId,
            address: state.address,
            isUrgent: state.isUrgent,
            scheduledAt: state.scheduledAt,
            timeSlot: state.timeSlot,
            childAge: state.childAge,
            hasPet: state.hasPet,
            budgetMax: state.budgetMax,
          );

    await result.fold(
      (f) async {
        emit(state.copyWith(phase: SearchPhase.error, message: f.message));
      },
      (request) async {
        emit(state.copyWith(
          phase: request.isProcessing
              ? SearchPhase.processing
              : SearchPhase.results,
          request: request,
        ));
        if (request.isProcessing) {
          _startPolling(request.id);
        } else if (request.matches.isEmpty && request.isReady) {
          // soft re-fetch once
          await refreshRequest(request.id);
        }
      },
    );
  }

  void _startPolling(int id) {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      _pollAttempts++;
      if (_pollAttempts > 20) {
        _pollTimer?.cancel();
        emit(state.copyWith(
          phase: SearchPhase.results,
          message: t('search.still_processing'),
        ));
        return;
      }
      await refreshRequest(id, fromPoll: true);
    });
  }

  Future<void> refreshRequest(int id, {bool fromPoll = false}) async {
    final result = await _repo.getRequest(id);
    result.fold(
      (f) {
        if (!fromPoll) {
          emit(state.copyWith(phase: SearchPhase.error, message: f.message));
        }
      },
      (request) {
        if (request.isReady || request.matches.isNotEmpty) {
          _pollTimer?.cancel();
          emit(state.copyWith(
            phase: SearchPhase.results,
            request: request,
          ));
        } else if (!fromPoll) {
          emit(state.copyWith(request: request, phase: SearchPhase.processing));
        } else {
          emit(state.copyWith(request: request));
        }
      },
    );
  }

  /// Open an existing request (from «Sorğularım») and show matches.
  Future<void> openRequest(int id) async {
    emit(state.copyWith(phase: SearchPhase.processing, clearMessage: true));
    await refreshRequest(id);
    if (state.phase == SearchPhase.processing && state.request != null) {
      _startPolling(id);
    }
  }

  Future<void> markUrgent() async {
    final id = state.request?.id;
    if (id == null) return;
    final result = await _repo.markUrgent(id);
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (data) => emit(state.copyWith(
        request: data.request,
        message: t('search.urgent_sent',
            params: {'balance': '${data.balance}'}),
      )),
    );
  }

  void reset() {
    _pollTimer?.cancel();
    _recordTimer?.cancel();
    emit(SearchAiState(
      latitude: state.latitude,
      longitude: state.longitude,
      address: state.address,
      categories: state.categories,
    ));
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _recordTimer?.cancel();
    _recorder.dispose();
    return super.close();
  }
}
