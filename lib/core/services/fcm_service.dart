import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class FcmService {
  FcmService(this._api);

  final ApiClient _api;

  static const String _deviceIdKey = 'fcm_registered_device_id';

  StreamSubscription<String>? _tokenSubscription;
  bool _initialized = false;

  String? get _platform {
    if (kIsWeb) return null;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return null;
    }
  }

  String? get _deviceName {
    switch (_platform) {
      case 'android':
        return 'Android device';
      case 'ios':
        return 'Apple device';
      default:
        return null;
    }
  }

  Future<void> initialize() async {
    if (_platform == null) return;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM notification permission denied.');
        return;
      }

      final token = await messaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }

      if (!_initialized) {
        _tokenSubscription = messaging.onTokenRefresh.listen((newToken) {
          _registerToken(newToken).catchError((error) {
            debugPrint('FCM token refresh error: $error');
          });
        });

        _initialized = true;
      }

      debugPrint('FCM initialization completed.');
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    final platform = _platform;

    if (platform == null) return;

    try {
      final response = await _api.dio.post(
        '/devices',
        data: {
          'token': token,
          'platform': platform,
          'device_name': _deviceName,
        },
      );

      final body = Map<String, dynamic>.from(response.data as Map);

      if (body['success'] != true) {
        throw Exception('Device registration failed.');
      }

      final devices = body['data'] as List;

      if (devices.isEmpty) {
        throw Exception('Device registration returned no device.');
      }

      final device = Map<String, dynamic>.from(devices.first as Map);
      final deviceId = device['id'];

      if (deviceId == null) {
        throw Exception('Device ID missing in API response.');
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(
        _deviceIdKey,
        int.parse(deviceId.toString()),
      );

      debugPrint('FCM device registered. ID: $deviceId');
    } on DioException catch (e) {
      debugPrint(
        'FCM registration API error: ${e.response?.data ?? e.message}',
      );
      rethrow;
    }
  }

  Future<void> deactivateDevice() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _initialized = false;

    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getInt(_deviceIdKey);

    if (deviceId == null) return;

    await _api.dio.delete('/devices/$deviceId');

    await prefs.remove(_deviceIdKey);

    debugPrint('FCM device deactivated.');
  }
}
