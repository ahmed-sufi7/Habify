import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap if needed
    final payload = response.payload;
    if (payload != null) {
      try {
        jsonDecode(payload);
        // Handle navigation based on payload if needed
      } catch (e) {
        // Handle error
      }
    }
  }

  static Future<void> scheduleHabitReminder({
    required int habitId,
    required String habitName,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      habitId, // Use habit ID as notification ID
      'Time for your habit! 🎯',
      'Don\'t forget to complete: $habitName',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Notifications to remind you about your habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/noti_logo', // Your actual provided PNG logo
          color: Colors.black, // Black background
          largeIcon: DrawableResourceAndroidBitmap('@drawable/noti_logo'), // Also use as large icon for more prominence
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'habit_reminder', 'habitId': habitId}),
    );
  }

  static Future<void> scheduleRepeatingHabitReminder({
    required int habitId,
    required String habitName,
    required List<int> weekdays, // 1=Monday, 7=Sunday
    required int hour,
    required int minute,
  }) async {
    // Cancel existing notifications for this habit
    await cancelHabitNotifications(habitId);

    // Schedule for each selected day
    for (int weekday in weekdays) {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      
      // Adjust to the correct weekday
      while (scheduledDate.weekday != weekday) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // If the time has passed today, schedule for next week
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _notifications.zonedSchedule(
        habitId * 10 + weekday, // Unique ID for each day
        'Time for your habit! 🎯',
        'Don\'t forget to complete: $habitName',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Notifications to remind you about your habits',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/noti_logo', // Your actual provided PNG logo
            color: Colors.black, // Black background
            largeIcon: DrawableResourceAndroidBitmap('@drawable/noti_logo'), // Also use as large icon for more prominence
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: jsonEncode({'type': 'habit_reminder', 'habitId': habitId}),
      );
    }
  }

  static Future<void> cancelHabitNotifications(int habitId) async {
    // Cancel base notification
    await _notifications.cancel(habitId);
    
    // Cancel all weekday variations
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _notifications.cancel(habitId * 10 + weekday);
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<bool> requestPermissions() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission() ?? false;
    }
    
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      return await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    
    return true;
  }
}