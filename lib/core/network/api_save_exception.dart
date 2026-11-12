import 'package:dio/dio.dart';

class ApiSaveException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRetryable;

  const ApiSaveException({
    required this.message,
    required this.statusCode,
    required this.isRetryable,
  });

  factory ApiSaveException.fromDio(
    DioException error, {
    required String fallback,
  }) {
    final statusCode = error.response?.statusCode;

    final responseData = error.response?.data;
    var message = fallback;

    if (responseData is Map) {
      final errors = responseData['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          message = firstError.first.toString();
        }
      }

      if (message == fallback) {
        final serverMessage = responseData['message']?.toString();

        if (serverMessage != null && serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      }
    }

    final retryable = statusCode == null
        ? error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.unknown
        : statusCode >= 500;

    return ApiSaveException(
      message: message,
      statusCode: statusCode,
      isRetryable: retryable,
    );
  }

  @override
  String toString() => message;
}
