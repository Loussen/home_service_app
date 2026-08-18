import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/verification/data/models/verification_document_model.dart';
import 'package:home_service_app/features/verification/domain/verification_repository.dart';

class VerificationState {
  const VerificationState({
    this.documents = const [],
    this.loading = false,
    this.uploading = false,
    this.message,
  });

  final List<VerificationDocumentModel> documents;
  final bool loading;
  final bool uploading;
  final String? message;

  VerificationDocumentModel? get latest =>
      documents.isEmpty ? null : documents.first;

  bool get canUpload =>
      !documents.any((d) => d.isPending);

  VerificationState copyWith({
    List<VerificationDocumentModel>? documents,
    bool? loading,
    bool? uploading,
    String? message,
    bool clearMessage = false,
  }) {
    return VerificationState(
      documents: documents ?? this.documents,
      loading: loading ?? this.loading,
      uploading: uploading ?? this.uploading,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class VerificationCubit extends Cubit<VerificationState> {
  VerificationCubit(this._repo) : super(const VerificationState());

  final VerificationRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.list();
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (docs) => emit(state.copyWith(loading: false, documents: docs)),
    );
  }

  Future<void> upload(String filePath) async {
    if (state.uploading || !state.canUpload) return;
    emit(state.copyWith(uploading: true, clearMessage: true));
    final result = await _repo.upload(filePath: filePath);
    result.fold(
      (f) => emit(state.copyWith(uploading: false, message: f.message)),
      (doc) => emit(state.copyWith(
        uploading: false,
        documents: [doc, ...state.documents],
        message: null,
      )),
    );
  }
}
