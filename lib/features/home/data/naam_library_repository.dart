import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_services.dart';
import '../../../data.dart';

class NaamLibraryRepository {
  NaamLibraryRepository._();

  static Map<String, dynamic> _responseMap(dynamic body) {
    if (body is! Map) {
      throw Exception('Invalid API response.');
    }

    return Map<String, dynamic>.from(body);
  }

  static List<Map<String, dynamic>> _extractItems(dynamic body) {
    final response = _responseMap(body);
    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      final items = map['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      // ResourceCollection may return a single item in data.
      if (map.containsKey('id')) {
        return [map];
      }
    }

    throw Exception('Invalid API data format.');
  }

  static Future<List<Deity>> fetchDeities() async {
    try {
      final response = await AppServices.api.dio.get('/deities');
      final items = _extractItems(response.data);

      final result = <Deity>[];

      for (final item in items) {
        final status = item['status']?.toString().toLowerCase();

        if (status != null && status.isNotEmpty && status != 'active') {
          continue;
        }

        final deity = _toDeity(item);

        if (deity.id.isNotEmpty && deity.en.isNotEmpty) {
          result.add(deity);
        }
      }

      debugPrint('Naam Library records parsed: ${result.length}');
      return result;
    } on DioException catch (e) {
      debugPrint('Naam Library request failed: ${e.message}');
      debugPrint('Naam Library error body: ${e.response?.data}');

      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;

      throw Exception(
        message ?? 'Unable to load Naam Library. Please try again.',
      );
    }
  }

  // Fetch one selected deity using its numeric database ID.
  static Future<Map<String, dynamic>> fetchDeityDetails(
    String deityId,
  ) async {
    try {
      final response = await AppServices.api.dio.get('/deities/$deityId');

      final items = _extractItems(response.data);

      if (items.isEmpty) {
        throw Exception('Naam details not found.');
      }

      return items.first;
    } on DioException catch (e) {
      debugPrint('Deity detail API error: ${e.response?.data}');

      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;

      throw Exception(
        message ?? 'Unable to load Naam details. Please try again.',
      );
    }
  }

  // Fetch active Sankalp targets.
  static Future<List<Map<String, dynamic>>> fetchSankalpTargets() async {
    try {
      final response = await AppServices.api.dio.get('/sankalp-targets');

      final items = _extractItems(response.data);

      return items.where((item) {
        final status = item['status'];

        if (status == null) return true;
        if (status is bool) return status;

        final value = status.toString().toLowerCase();
        return value == 'active' || value == '1' || value == 'true';
      }).toList();
    } on DioException catch (e) {
      debugPrint('Sankalp targets API error: ${e.response?.data}');

      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;

      throw Exception(
        message ?? 'Unable to load Sankalp targets. Please try again.',
      );
    }
  }

  static Deity _toDeity(Map<String, dynamic> item) {
    // IMPORTANT: Keep numeric database ID here, not slug.
    final id = item['id']?.toString() ?? '';

    final name = item['name']?.toString().trim() ?? '';
    final hindiValue = item['name_hindi']?.toString().trim();
    final punjabiValue = item['name_punjabi']?.toString().trim();

    final hindi =
        hindiValue != null && hindiValue.isNotEmpty ? hindiValue : name;

    final icon = item['icon']?.toString().trim() ?? '';
    final imageUrl = _resolveImageUrl(icon);

    final symbol = imageUrl == null ? (icon.isNotEmpty ? icon : '🙏') : '🙏';

    return Deity(
      id,
      hindi,
      name,
      symbol,
      const Color(0xFFFFE2A8),
      const Color(0xFFE8A53C),
      imageUrl: imageUrl,
      pa: (punjabiValue != null && punjabiValue.isNotEmpty)
          ? punjabiValue
          : null,
    );
  }

  static String? _resolveImageUrl(String icon) {
    if (icon.isEmpty) return null;

    final uri = Uri.tryParse(icon);

    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return icon;
    }

    return null;
  }

  // Fetch active Sankalp members.
  static Future<List<Map<String, dynamic>>> fetchSankalpMembers() async {
    try {
      final response = await AppServices.api.dio.get('/sankalp-members');

      final items = _extractItems(response.data);

      final members = items.where((item) {
        final status = item['status'];

        if (status == null) return false;
        if (status is bool) return status;

        final value = status.toString().toLowerCase();
        return value == '1' || value == 'true' || value == 'active';
      }).toList();

      members.sort((a, b) {
        final orderA = int.tryParse(a['sort_order']?.toString() ?? '') ?? 0;
        final orderB = int.tryParse(b['sort_order']?.toString() ?? '') ?? 0;

        return orderA.compareTo(orderB);
      });

      return members;
    } on DioException catch (e) {
      debugPrint(
        'Sankalp members API error: ${e.response?.data}',
      );

      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;

      throw Exception(
        message ?? 'Unable to load Sankalp members. Please try again.',
      );
    }
  }

  // Fetch active writing designs from existing Admin Design API.
  static Future<List<Map<String, dynamic>>> fetchDesigns() async {
    try {
      final response = await AppServices.api.dio.get('/admin/designs');

      final items = _extractItems(response.data);

      final designs = items.where((item) {
        final status = item['status'];

        if (status == null) return false;
        if (status is bool) return status;

        final value = status.toString().toLowerCase();

        return value == 'active' || value == '1' || value == 'true';
      }).toList();

      designs.sort((a, b) {
        final orderA = int.tryParse(a['sort_order']?.toString() ?? '') ?? 0;
        final orderB = int.tryParse(b['sort_order']?.toString() ?? '') ?? 0;

        return orderA.compareTo(orderB);
      });

      return designs;
    } on DioException catch (e) {
      debugPrint('Design API error: ${e.response?.data}');

      final data = e.response?.data;
      final message = data is Map ? data['message']?.toString() : null;

      throw Exception(
        message ?? 'Unable to load writing designs. Please try again.',
      );
    }
  }

  
static Future<Map<String, dynamic>> createSankalp({
    required int naamLibraryId,
    required int sankalpTargetId,
    required int sankalpMemberId,
    String? recipientName,
    String? intention,
  }) async {
    try {
      final response = await AppServices.api.dio.post(
        '/user-sankalps',
        data: {
          'naam_library_id': naamLibraryId,
          'sankalp_target_id': sankalpTargetId,
          'sankalp_member_id': sankalpMemberId,
          'recipient_name': recipientName,
          'intention': intention,
        },
      );

      final body = response.data;

      if (body is! Map) {
        throw Exception('Invalid server response.');
      }

      if (body['status'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to create Sankalp.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw Exception('Sankalp was created but response data is missing.');
      }

      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      final responseData = e.response?.data;

      String message = 'Unable to create Sankalp. Please try again.';

      if (responseData is Map) {
        message = responseData['message']?.toString() ?? message;

        final errors = responseData['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }

      throw Exception(message);
    }
  }

}
