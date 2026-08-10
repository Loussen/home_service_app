import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_service_app/features/search_ai/domain/search_repository.dart';
import 'package:home_service_app/features/search_ai/presentation/cubit/search_ai_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class SearchAiCubit extends Cubit<SearchAiState> {
  SearchAiCubit(this._repo) : super(const SearchAiState());

  final SearchRepository _repo;
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _recordTimer;
  Timer? _pollTimer;
  int _pollAttempts = 0;

  Future<void> init() async {
    emit(state.copyWith(phase: SearchPhase.locating, clearMessage: true));
    await _resolveLocation();
    emit(state.copyWith(phase: SearchPhase.idle));
  }

  void setText(String value) => emit(state.copyWith(text: value));

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
        message: 'Mikrofon icazəsi lazımdır',
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
      if (next >= 60) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    emit(state.copyWith(
      isRecording: false,
      phase: SearchPhase.idle,
      localAudioPath: path,
      recordSeconds: 0,
    ));
  }

  Future<void> submit() async {
    final hasAudio = state.localAudioPath != null;
    final hasText = state.text.trim().isNotEmpty;

    if (!hasAudio && !hasText) {
      emit(state.copyWith(
        phase: SearchPhase.error,
        message: 'Səs yazın və ya mətni daxil edin',
      ));
      return;
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
            isUrgent: state.isUrgent,
          )
        : await _repo.submitText(
            text: state.text.trim(),
            latitude: state.latitude,
            longitude: state.longitude,
            isUrgent: state.isUrgent,
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
          message: 'Emal hələ davam edir — sonra yeniləyin',
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

  Future<void> markUrgent() async {
    final id = state.request?.id;
    if (id == null) return;
    final result = await _repo.markUrgent(id);
    result.fold(
      (f) => emit(state.copyWith(message: f.message)),
      (data) => emit(state.copyWith(
        request: data.request,
        message: 'Təcili bildiriş göndərildi. Qalan: ${data.balance} AZN',
      )),
    );
  }

  void reset() {
    _pollTimer?.cancel();
    _recordTimer?.cancel();
    emit(SearchAiState(
      latitude: state.latitude,
      longitude: state.longitude,
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
