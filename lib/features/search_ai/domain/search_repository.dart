import 'package:dartz/dartz.dart';
import 'package:home_service_app/core/error/failures.dart';
import 'package:home_service_app/features/search_ai/data/models/service_request_model.dart';

abstract class SearchRepository {
  Future<Either<Failure, ServiceRequestModel>> submitAudio({
    required String filePath,
    required double latitude,
    required double longitude,
    String? address,
    bool isUrgent,
    int? categoryId,
    DateTime? scheduledAt,
    String? timeSlot,
    int? childAge,
    bool? hasPet,
    double? budgetMax,
  });

  Future<Either<Failure, ServiceRequestModel>> submitText({
    required String text,
    required double latitude,
    required double longitude,
    int? categoryId,
    String? address,
    bool isUrgent,
    DateTime? scheduledAt,
    String? timeSlot,
    int? childAge,
    bool? hasPet,
    double? budgetMax,
  });

  Future<Either<Failure, ServiceRequestModel>> getRequest(int id);

  Future<Either<Failure, List<ServiceRequestModel>>> listRequests();

  Future<Either<Failure, ({ServiceRequestModel request, double balance})>>
      markUrgent(int id);
}
