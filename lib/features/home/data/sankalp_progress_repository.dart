import 'package:dio/dio.dart';

import '../../../core/services/app_services.dart';

class SankalpProgressRepository {
  SankalpProgressRepository._();

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw Exception('Invalid server response.');
  }

  static Exception _handleError(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        final errors = responseData['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return Exception(firstError.first.toString());
          }
        }

        final message = responseData['message']?.toString();

        if (message != null && message.isNotEmpty) {
          return Exception(message);
        }
      }

      return Exception(fallback);
    }

    return Exception(
      error.toString().replaceFirst('Exception: ', ''),
    );
  }

  static Map<String, dynamic> _responseMap(dynamic body) {
    final response = _toMap(body);

    if (response['success'] != true) {
      throw Exception(
        response['message']?.toString() ?? 'Request failed.',
      );
    }

    return response;
  }

  // Fetch today's target and progress.
  static Future<Map<String, dynamic>> fetchTodaySummary(
    int sankalpId,
  ) async {
    try {
      final response = await AppServices.api.dio.get(
        '/daily-targets/$sankalpId/today',
      );

      final body = _responseMap(response.data);

      return _toMap(body['data']);
    } catch (e) {
      throw _handleError(
        e,
        fallback: 'Unable to load today progress.',
      );
    }
  }

  // Create or update today's daily target.
  static Future<Map<String, dynamic>> setDailyTarget({
    required int sankalpId,
    required int targetCount,
  }) async {
    try {
      final response = await AppServices.api.dio.post(
        '/daily-targets',
        data: {
          'sankalp_id': sankalpId,
          'target_count': targetCount,
        },
      );

      final body = _responseMap(response.data);

      return _toMap(body['data']);
    } catch (e) {
      throw _handleError(
        e,
        fallback: 'Unable to save daily target.',
      );
    }
  }

  // Save writing progress.
  static Future<Map<String, dynamic>> saveProgress({
    required int sankalpId,
    required int count,
    required String progressDate,
  }) async {
    try {
      final response = await AppServices.api.dio.post(
        '/sankalp-progress/$sankalpId/progress',
        data: {
          'count': count,
          'progress_date': progressDate,
        },
      );

      final body = _responseMap(response.data);

      return {
        'data': body['data'],
        'daily_target_summary': body['daily_target_summary'],
      };
    } catch (e) {
      throw _handleError(
        e,
        fallback: 'Unable to save Naam progress.',
      );
    }
  }

  // Fetch all progress logs of one Sankalp.
  static Future<List<Map<String, dynamic>>> fetchProgressHistory(
    int sankalpId,
  ) async {
    try {
      final response = await AppServices.api.dio.get(
        '/sankalp-progress/$sankalpId/daily-progress',
      );

      final body = _responseMap(response.data);
      final data = body['data'];

      if (data is! List) {
        throw Exception('Invalid progress history response.');
      }

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      throw _handleError(
        e,
        fallback: 'Unable to load progress history.',
      );
    }
  }

  // Fetch progress logs for all user's Sankalps.
  static Future<List<Map<String, dynamic>>> fetchAllProgress() async {
    try {
      final response = await AppServices.api.dio.get(
        '/sankalp-progress',
      );

      final body = _responseMap(response.data);
      final data = body['data'];

      if (data is! List) {
        throw Exception('Invalid progress records response.');
      }

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      throw _handleError(
        e,
        fallback: 'Unable to load progress records.',
      );
    }
  }
}
