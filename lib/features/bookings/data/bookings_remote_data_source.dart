import 'package:home_service_app/core/network/api_client.dart';
import 'package:home_service_app/features/bookings/data/models/booking_model.dart';

class BookingsRemoteDataSource {
  BookingsRemoteDataSource(this._client);

  final ApiClient _client;

  Future<List<BookingModel>> list() async {
    final res = await _client.dio.get('/bookings');
    final list = res.data['data'] as List<dynamic>;
    return list
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> cancel(int id) async {
    final res = await _client.dio.post('/bookings/$id/cancel');
    return BookingModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
