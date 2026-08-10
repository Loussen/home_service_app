import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

enum SearchPhase {
  idle,
  locating,
  recording,
  submitting,
  processing,
  results,
  error,
}

class SearchAiState extends Equatable {
  const SearchAiState({
    this.phase = SearchPhase.idle,
    this.latitude = 40.4093,
    this.longitude = 49.8671,
    this.text = '',
    this.localAudioPath,
    this.isUrgent = false,
    this.request,
    this.message,
    this.isRecording = false,
    this.recordSeconds = 0,
  });

  final SearchPhase phase;
  final double latitude;
  final double longitude;
  final String text;
  final String? localAudioPath;
  final bool isUrgent;
  final ServiceRequestModel? request;
  final String? message;
  final bool isRecording;
  final int recordSeconds;

  SearchAiState copyWith({
    SearchPhase? phase,
    double? latitude,
    double? longitude,
    String? text,
    String? localAudioPath,
    bool? isUrgent,
    ServiceRequestModel? request,
    String? message,
    bool? isRecording,
    int? recordSeconds,
    bool clearMessage = false,
    bool clearAudio = false,
    bool clearRequest = false,
  }) {
    return SearchAiState(
      phase: phase ?? this.phase,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      text: text ?? this.text,
      localAudioPath: clearAudio ? null : (localAudioPath ?? this.localAudioPath),
      isUrgent: isUrgent ?? this.isUrgent,
      request: clearRequest ? null : (request ?? this.request),
      message: clearMessage ? null : (message ?? this.message),
      isRecording: isRecording ?? this.isRecording,
      recordSeconds: recordSeconds ?? this.recordSeconds,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        latitude,
        longitude,
        text,
        localAudioPath,
        isUrgent,
        request,
        message,
        isRecording,
        recordSeconds,
      ];
}
