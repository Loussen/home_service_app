import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/bookings/data/models/booking_model.dart';

abstract class BookingsRepository {
  Future<Either<Failure, List<BookingModel>>> list();

  Future<Either<Failure, BookingModel>> cancel(int id);
}
