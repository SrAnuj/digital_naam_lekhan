import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data.dart';
import '../../theme.dart';
import '../../features/home/data/user_sankalp_repository.dart';
import 'app_services.dart';

class NotificationNavigationService {
  NotificationNavigationService._();

  static final NotificationNavigationService instance =
      NotificationNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String _pendingSankalpIdKey = 'pending_notification_sankalp_id';

  bool _initialized = false;
  bool _processing = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    try {
      // App opened by tapping notification after being terminated.
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        await _savePendingNotification(initialMessage.data);
      }

      // App opened by tapping notification from background.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        handleNotificationPayload(message.data);
      });
    } catch (e) {
      debugPrint('Notification tap initialization error: $e');
    }
  }

  // Handle notification tap from local notification.
  Future<void> handleNotificationPayload(
    Map<String, dynamic> payload,
  ) async {
    await _handleNotification(payload);
  }

  Future<void> _handleNotification(
    Map<String, dynamic> payload,
  ) async {
    await _savePendingNotification(payload);
    await processPendingNotification();
  }

  Future<void> _savePendingNotification(
    Map<String, dynamic> payload,
  ) async {
    final sankalpId = int.tryParse(
      payload['sankalp_id']?.toString() ?? '',
    );

    if (sankalpId == null || sankalpId <= 0) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_pendingSankalpIdKey, sankalpId);
  }

  Future<void> processPendingNotification() async {
    if (_processing) return;

    final prefs = await SharedPreferences.getInstance();
    final sankalpId = prefs.getInt(_pendingSankalpIdKey);

    if (sankalpId == null || sankalpId <= 0) return;

    // Do not navigate until the user is authenticated.
    if (!await AppServices.auth.hasSession()) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    _processing = true;

    try {
      final sankalps = await UserSankalpRepository.fetchMySankalps();

      final matchingSankalp = sankalps.firstWhere(
        (item) => int.tryParse(item['id']?.toString() ?? '') == sankalpId,
        orElse: () => <String, dynamic>{},
      );

      if (matchingSankalp.isEmpty) {
        await prefs.remove(_pendingSankalpIdKey);
        debugPrint('Notification Sankalp not found: $sankalpId');
        return;
      }

      final naam = matchingSankalp['naam'] is Map
          ? Map<String, dynamic>.from(matchingSankalp['naam'])
          : <String, dynamic>{};

      int readInt(dynamic value) {
        if (value is int) return value;
        if (value is num) return value.toInt();
        return int.tryParse(value?.toString() ?? '') ?? 0;
      }

      final icon = naam['icon']?.toString().trim();
      String? imageUrl;

      if (icon != null && icon.isNotEmpty) {
        if (icon.startsWith('http://') || icon.startsWith('https://')) {
          imageUrl = icon;
        } else {
          final imagePath = icon.startsWith('/') ? icon.substring(1) : icon;

          imageUrl =
              'https://sankalp.premierwebtechservices.com/storage/$imagePath';
        }
      }

      final total = readInt(matchingSankalp['target_count']);
      final completed = readInt(matchingSankalp['completed_count']);

      final safeTotal = total > 0 ? total : 0;
      final safeCompleted = completed.clamp(0, safeTotal).toInt();

      final deity = Deity(
        readInt(naam['id']).toString(),
        naam['name_hindi']?.toString() ?? '',
        naam['name']?.toString() ?? 'Naam',
        'ॐ',
        AppColors.maroon,
        AppColors.gold,
        imageUrl: imageUrl,
      );

      // Set the selected Sankalp data before opening its screen.
      AppState.createdSankalpId = sankalpId;
      AppState.target = safeTotal;
      AppState.written = safeCompleted;
      AppState.deity = deity;

      final status = matchingSankalp['status']?.toString().trim().toLowerCase();

      final route = status == 'completed' ? '/completion' : '/progress';

      await prefs.remove(_pendingSankalpIdKey);

      navigator.pushNamed(route);
    } catch (e) {
      debugPrint('Notification navigation error: $e');
    } finally {
      _processing = false;
    }
  }
}
