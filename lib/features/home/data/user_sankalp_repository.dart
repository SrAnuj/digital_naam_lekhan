import 'package:dio/dio.dart';
import 'package:sankalp/core/services/app_services.dart';

class UserSankalpRepository {
  UserSankalpRepository._();

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw Exception('Invalid server response.');
  }

  static Exception _handleError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        final message = responseData['message']?.toString();

        if (message != null && message.isNotEmpty) {
          return Exception(message);
        }
      }

      return Exception('Unable to load your Sankalps.');
    }

    return Exception(
      error.toString().replaceFirst('Exception: ', ''),
    );
  }

  static Future<List<Map<String, dynamic>>> fetchMySankalps() async {
    try {
      final response = await AppServices.api.dio.get(
        '/user-sankalps',
      );

      final body = _toMap(response.data);

      if (body['status'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to load Sankalps.',
        );
      }

      final data = body['data'];

      if (data is! List) {
        throw Exception('Invalid Sankalp list response.');
      }

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
}
