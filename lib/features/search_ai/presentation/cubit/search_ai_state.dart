import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/profile/data/models/category_model.dart';
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
    this.address,
    this.text = '',
    this.localAudioPath,
    this.isUrgent = false,
    this.request,
    this.message,
    this.isRecording = false,
    this.recordSeconds = 0,
    this.categories = const [],
    this.selectedCategoryId,
    this.scheduledAt,
    this.timeSlot,
  });

  final SearchPhase phase;
  final double latitude;
  final double longitude;
  final String? address;
  final String text;
  final String? localAudioPath;
  final bool isUrgent;
  final ServiceRequestModel? request;
  final String? message;
  final bool isRecording;
  final int recordSeconds;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final DateTime? scheduledAt;
  final String? timeSlot;

  SearchAiState copyWith({
    SearchPhase? phase,
    double? latitude,
    double? longitude,
    String? address,
    String? text,
    String? localAudioPath,
    bool? isUrgent,
    ServiceRequestModel? request,
    String? message,
    bool? isRecording,
    int? recordSeconds,
    List<CategoryModel>? categories,
    int? selectedCategoryId,
    DateTime? scheduledAt,
    String? timeSlot,
    bool clearMessage = false,
    bool clearAudio = false,
    bool clearRequest = false,
    bool clearCategory = false,
    bool clearSchedule = false,
    bool clearTimeSlot = false,
  }) {
    return SearchAiState(
      phase: phase ?? this.phase,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      text: text ?? this.text,
      localAudioPath: clearAudio ? null : (localAudioPath ?? this.localAudioPath),
      isUrgent: isUrgent ?? this.isUrgent,
      request: clearRequest ? null : (request ?? this.request),
      message: clearMessage ? null : (message ?? this.message),
      isRecording: isRecording ?? this.isRecording,
      recordSeconds: recordSeconds ?? this.recordSeconds,
      categories: categories ?? this.categories,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      scheduledAt: clearSchedule ? null : (scheduledAt ?? this.scheduledAt),
      timeSlot: clearTimeSlot ? null : (timeSlot ?? this.timeSlot),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        latitude,
        longitude,
        address,
        text,
        localAudioPath,
        isUrgent,
        request,
        message,
        isRecording,
        recordSeconds,
        categories,
        selectedCategoryId,
        scheduledAt,
        timeSlot,
      ];
}
