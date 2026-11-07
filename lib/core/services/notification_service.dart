import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_navigation_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 1701;
  static const String _channelId = 'daily_naam_reminder';
  static const String _channelName = 'Daily Naam Reminder';

  // Separate channel for Laravel FCM notifications.
  static const String _fcmChannelId = 'fcm_notifications';
  static const String _fcmChannelName = 'Sankalp Notifications';

  static const String _enabledKey = 'daily_reminder_enabled';
  static const String _hourKey = 'daily_reminder_hour';
  static const String _minuteKey = 'daily_reminder_minute';
  static const String _selectionKey = 'daily_reminder_selection';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload == null || payload.isEmpty) return;

        try {
          final decoded = jsonDecode(payload);

          if (decoded is Map) {
            NotificationNavigationService.instance.handleNotificationPayload(
              Map<String, dynamic>.from(decoded),
            );
          }
        } catch (e) {
          debugPrint('Notification payload error: $e');
        }
      },
    );

    _initialized = true;

    // Check whether app was launched by tapping a local notification.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    final payload = launchDetails?.notificationResponse?.payload;

    if (launchDetails?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);

        if (decoded is Map) {
          await NotificationNavigationService.instance
              .handleNotificationPayload(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (e) {
        debugPrint('Notification launch payload error: $e');
      }
    }
  }

  // Display a notification received from Laravel FCM while app is foreground.
  Future<void> showFcmNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _fcmChannelId,
        _fcmChannelName,
        channelDescription: 'Notifications about your daily Sankalp.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      ),
    );

    final notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(payload),
    );
  }

  Future<bool> saveDailyReminder({
    required int selection,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return false;
    }

    await androidPlugin.requestNotificationsPermission();

    final notificationsEnabled =
        await androidPlugin.areNotificationsEnabled() ?? true;

    if (!notificationsEnabled) {
      return false;
    }

    final exactPermission =
        await androidPlugin.requestExactAlarmsPermission() ?? false;

    final scheduleMode = exactPermission
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.cancel(id: _notificationId);

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily reminder to write your Naam.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Daily Naam Reminder 🙏',
      body: 'It is time to write your Naam. Complete your daily Sankalp.',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_enabledKey, true);
    await prefs.setInt(_selectionKey, selection);
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);

    return true;
  }

  Future<Map<String, dynamic>> getSavedReminder() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'enabled': prefs.getBool(_enabledKey) ?? false,
      'selection': prefs.getInt(_selectionKey) ?? 0,
      'hour': prefs.getInt(_hourKey) ?? 7,
      'minute': prefs.getInt(_minuteKey) ?? 0,
    };
  }

  Future<void> cancelDailyReminder() async {
    await initialize();

    await _plugin.cancel(id: _notificationId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }
}
