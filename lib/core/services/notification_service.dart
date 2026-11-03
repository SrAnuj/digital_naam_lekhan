import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 1701;
  static const String _channelId = 'daily_naam_reminder';
  static const String _channelName = 'Daily Naam Reminder';

  static const String _enabledKey = 'daily_reminder_enabled';
  static const String _hourKey = 'daily_reminder_hour';
  static const String _minuteKey = 'daily_reminder_minute';
  static const String _selectionKey = 'daily_reminder_selection';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database.
    tz_data.initializeTimeZones();

    // Current app timezone: India.
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
    );

    _initialized = true;
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

    // Android 13+ notification permission.
    await androidPlugin.requestNotificationsPermission();

    final notificationsEnabled =
        await androidPlugin.areNotificationsEnabled() ?? true;

    if (!notificationsEnabled) {
      return false;
    }

    // Exact alarm permission is optional.
    // If denied, use inexact scheduling as a fallback.
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

    // If today's selected time has passed, start tomorrow.
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
    // Save the selection only after scheduling succeeds.
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
