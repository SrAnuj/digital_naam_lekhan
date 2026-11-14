import 'package:dio/dio.dart';

import '../../../core/services/app_services.dart';
import '../../../core/network/api_save_exception.dart';
import 'models/jap_session_model.dart';
import 'models/jap_session_summary_model.dart';

class JapSessionSaveResult {
  final JapSessionModel session;
  final Map<String, dynamic> sankalpSummary;
  final bool sankalpCompleted;

  const JapSessionSaveResult({
    required this.session,
    required this.sankalpSummary,
    required this.sankalpCompleted,
  });
}

class JapSessionRepository {
  JapSessionRepository._();

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw Exception('Invalid server response.');
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

  static void _validateSankalpId(int sankalpId) {
    if (sankalpId <= 0) {
      throw Exception('Invalid Sankalp ID.');
    }
  }

  /// Save one Jap session.
  /// POST /jap-sessions
  ///
  /// Returns session data and Sankalp completion status.
  static Future<JapSessionSaveResult> saveSession({
    required int sankalpId,
    required int count,
    required String requestId,
    required String activityDate,
    int malaSize = 108,
    DateTime? startedAt,
    DateTime? completedAt,
    int durationSeconds = 0,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _validateSankalpId(sankalpId);

      if (count <= 0) {
        throw Exception('Naam count must be greater than zero.');
      }

      if (malaSize <= 0) {
        throw Exception('Mala size must be greater than zero.');
      }

      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(activityDate)) {
        throw Exception('Invalid activity date. Use YYYY-MM-DD.');
      }

      if (requestId.trim().isEmpty) {
        throw Exception('Request ID is required.');
      }

      if (durationSeconds < 0) {
        throw Exception('Duration cannot be negative.');
      }

      final response = await AppServices.api.dio.post(
        '/jap-sessions',
        data: {
          'sankalp_id': sankalpId,
          'count': count,
          'request_id': requestId,
          'activity_date': activityDate,
          'mala_size': malaSize,
          'completed_malas': count ~/ malaSize,
          'extra_naam': count % malaSize,
          'started_at': startedAt?.toIso8601String(),
          'completed_at': completedAt?.toIso8601String(),
          'duration_seconds': durationSeconds,
          'metadata': metadata,
        },
      );

      final body = _responseMap(response.data);
      final data = _toMap(body['data']);
      final summaryData = body['sankalp_summary'];

      return JapSessionSaveResult(
        session: JapSessionModel.fromJson(data),
        sankalpSummary: summaryData is Map
            ? Map<String, dynamic>.from(summaryData)
            : <String, dynamic>{},
        sankalpCompleted: body['sankalp_completed'] == true,
      );
    } catch (error) {
      if (error is DioException) {
        throw ApiSaveException.fromDio(
          error,
          fallback: 'Unable to save Jap session.',
        );
      }

      throw _handleError(
        error,
        fallback: 'Unable to save Jap session.',
      );
    }
  }

  /// Fetch Jap session history.
  /// GET /jap-sessions
  static Future<List<JapSessionModel>> fetchHistory({
    int? sankalpId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      if (sankalpId != null) {
        _validateSankalpId(sankalpId);
      }

      if (page <= 0 || perPage <= 0 || perPage > 100) {
        throw Exception('Invalid pagination values.');
      }

      final response = await AppServices.api.dio.get(
        '/jap-sessions',
        queryParameters: {
          if (sankalpId != null) 'sankalp_id': sankalpId,
          'page': page,
          'per_page': perPage,
        },
      );

      final body = _responseMap(response.data);
      final data = body['data'];

      if (data is! List) {
        throw Exception('Invalid Jap history response.');
      }

      return data
          .whereType<Map>()
          .map(
            (item) => JapSessionModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (error) {
      throw _handleError(
        error,
        fallback: 'Unable to load Jap session history.',
      );
    }
  }

  /// Fetch Jap summary.
  /// GET /jap-sessions/summary
  static Future<List<JapSessionSummaryModel>> fetchSummary({
    int? sankalpId,
  }) async {
    try {
      if (sankalpId != null) {
        _validateSankalpId(sankalpId);
      }

      final response = await AppServices.api.dio.get(
        '/jap-sessions/summary',
        queryParameters: {
          if (sankalpId != null) 'sankalp_id': sankalpId,
        },
      );

      final body = _responseMap(response.data);
      final data = body['data'];

      if (data is! List) {
        throw Exception('Invalid Jap summary response.');
      }

      return data
          .whereType<Map>()
          .map(
            (item) => JapSessionSummaryModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (error) {
      throw _handleError(
        error,
        fallback: 'Unable to load Jap summary.',
      );
    }
  }
}
