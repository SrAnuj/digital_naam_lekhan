import 'package:dio/dio.dart';

import '../../../core/services/app_services.dart';

class HomeRepository {
  HomeRepository._();

  static Future<Map<String, dynamic>> fetchHome() async {
    try {
      final response = await AppServices.api.dio.get('/home');

      final body = response.data;

      if (body is! Map) {
        throw Exception('Invalid home API response.');
      }

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to load home data.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw Exception('Home data is missing from the response.');
      }

      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      final responseData = e.response?.data;

      final message =
          responseData is Map ? responseData['message']?.toString() : null;

      throw Exception(
        message ??
            (e.response?.statusCode == 401
                ? 'Session expired. Please log in again.'
                : 'Unable to connect to the server. Please try again.'),
      );
    }
  }
}
