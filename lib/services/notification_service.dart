import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../config/navigation_key.dart';
import '../screens/cards/scenario_cards_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Keys for SharedPreferences
  static const String _reminderEnabledKey = 'daily_reminder_enabled';
  static const String _reminderTimesKey = 'daily_reminder_times';
  static const List<int> _notificationIds = [0, 1, 2];

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');

    // Check if navigator key is attached
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const ScenarioCardsScreen()),
      );
    } else {
      debugPrint('Navigator state is null, cannot navigate');
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Save reminder settings
  Future<void> saveReminderSettings({
    required bool enabled,
    required List<TimeOfDay> times,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, enabled);
      final timeStrings = times.map((t) => '${t.hour}:${t.minute}').toList();
      await prefs.setStringList(_reminderTimesKey, timeStrings);
    } catch (e) {
      debugPrint('Error saving reminder settings: $e');
    }
  }

  /// Get reminder enabled status
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  /// Get reminder times
  Future<List<TimeOfDay>> getReminderTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStrings = prefs.getStringList(_reminderTimesKey);

    if (timeStrings == null || timeStrings.isEmpty) {
      // Default to 9:00 AM if none set
      return [const TimeOfDay(hour: 9, minute: 0)];
    }

    return timeStrings.map((s) {
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  /// Schedule daily reminders
  Future<void> scheduleDailyReminders(List<TimeOfDay> times) async {
    try {
      // 1. Cancel all existing notifications first
      await cancelAllReminders();

      if (times.isEmpty) return;

      // 2. Schedule each time up to our limit
      for (int i = 0; i < times.length && i < _notificationIds.length; i++) {
        final time = times[i];
        final notificationId = _notificationIds[i];

        // Get the next instance of the specified time
        final now = DateTime.now();
        var scheduledDate = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // If the time has already passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        // Convert to TZDateTime
        final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
          scheduledDate,
          tz.local,
        );

        // Android notification details
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
              'daily_reminder_channel_v2', // New channel ID to avoid conflicts
              'Daily Reminders',
              channelDescription: 'Daily practice reminders for social skills',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );

        // Schedule the notification - using inexact for better reliability if exact fails
        await _flutterLocalNotificationsPlugin
            .zonedSchedule(
              notificationId,
              'Practice Time! 🎯',
              'Ready to level up your social skills? Just 5 minutes can make a difference!',
              scheduledTZDate,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode
                  .inexactAllowWhileIdle, // Change to inexact for better compatibility
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
            )
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint('⏰ Timeout scheduling notification $i');
              },
            );

        debugPrint(
          'Scheduled daily reminder $i for ${time.hour}:${time.minute}',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
      // Don't rethrow, just log, so the app doesn't crash/hang
    }
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    try {
      for (final id in _notificationIds) {
        await _flutterLocalNotificationsPlugin.cancel(id);
      }
      debugPrint('Cancelled all daily reminders');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  /// Disable reminders
  Future<void> disableReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, false);
    await cancelAllReminders();
  }

  /// Show immediate test notification
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      999,
      'Test Notification 🔔',
      'Your notifications are working perfectly!',
      notificationDetails,
    );
  }
}
