import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class PageRepository {
  PageRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Fetch a published CMS page using its slug.
  Future<Map<String, dynamic>> fetchPage(String slug) async {
    try {
      final response = await _apiClient.dio.get(
        '/pages/${Uri.encodeComponent(slug)}',
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid server response.');
      }

      if (responseData['success'] != true) {
        throw Exception(
          responseData['message']?.toString() ?? 'Unable to load page.',
        );
      }

      final pageData = responseData['data'];

      // Laravel ResourceCollection returns data as a List.
      if (pageData is List && pageData.isNotEmpty) {
        final page = pageData.first;

        if (page is Map) {
          return Map<String, dynamic>.from(page);
        }
      }

      // Also support a single object response.
      if (pageData is Map) {
        return Map<String, dynamic>.from(pageData);
      }

      throw Exception('Page not found.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Page not found.');
      }

      throw Exception(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                'Unable to connect to server.')
            : 'Unable to connect to server.',
      );
    }
  }

  /// Fetch all published CMS pages.
  Future<List<Map<String, dynamic>>> fetchPages() async {
    try {
      final response = await _apiClient.dio.get('/pages');

      final responseData = response.data;

      if (responseData is! Map || responseData['success'] != true) {
        throw Exception('Unable to load pages.');
      }

      final pageData = responseData['data'];

      if (pageData is! List) {
        throw Exception('Invalid pages response.');
      }

      return pageData
          .whereType<Map>()
          .map((page) => Map<String, dynamic>.from(page))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                'Unable to connect to server.')
            : 'Unable to connect to server.',
      );
    }
  }
}
