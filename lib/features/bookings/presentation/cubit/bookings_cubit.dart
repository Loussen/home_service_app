import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_service_app/features/bookings/data/models/booking_model.dart';
import 'package:home_service_app/features/bookings/domain/bookings_repository.dart';

class BookingsState {
  const BookingsState({
    this.items = const [],
    this.loading = false,
    this.cancellingId,
    this.message,
  });

  final List<BookingModel> items;
  final bool loading;
  final int? cancellingId;
  final String? message;

  List<BookingModel> get upcoming =>
      items.where((b) => b.isScheduled).toList();

  List<BookingModel> get past =>
      items.where((b) => !b.isScheduled).toList();

  BookingsState copyWith({
    List<BookingModel>? items,
    bool? loading,
    int? cancellingId,
    String? message,
    bool clearCancelling = false,
    bool clearMessage = false,
  }) {
    return BookingsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      cancellingId: clearCancelling ? null : (cancellingId ?? this.cancellingId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class BookingsCubit extends Cubit<BookingsState> {
  BookingsCubit(this._repo) : super(const BookingsState());

  final BookingsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearMessage: true));
    final result = await _repo.list();
    result.fold(
      (f) => emit(state.copyWith(loading: false, message: f.message)),
      (items) => emit(state.copyWith(loading: false, items: items)),
    );
  }

  Future<void> cancel(int id) async {
    emit(state.copyWith(cancellingId: id, clearMessage: true));
    final result = await _repo.cancel(id);
    result.fold(
      (f) => emit(state.copyWith(clearCancelling: true, message: f.message)),
      (updated) {
        final next = state.items.map((b) => b.id == id ? updated : b).toList();
        emit(state.copyWith(clearCancelling: true, items: next));
      },
    );
  }
}
