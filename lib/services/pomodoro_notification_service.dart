import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/pomodoro_provider.dart';

class PomodoroNotificationService {
  static final PomodoroNotificationService _instance = PomodoroNotificationService._internal();
  factory PomodoroNotificationService() => _instance;
  PomodoroNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'pomodoro_timer_channel';
  static const String _channelName = 'Pomodoro Timer';
  static const String _channelDescription = 'Notifications for running Pomodoro timer sessions';
  static const int _notificationId = 1001;
  
  Timer? _progressUpdateTimer;
  bool _isInitialized = false;

  // Navigation callback to handle notification taps
  Function(String)? onNotificationTapped;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    _isInitialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low, // Low importance to avoid sound/vibration during focus
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap - navigate to timer screen
    final payload = notificationResponse.payload;
    if (payload != null && onNotificationTapped != null) {
      onNotificationTapped!(payload);
    }
  }

  Future<void> showPomodoroTimerNotification({
    required PomodoroProvider pomodoroProvider,
    required int sessionId,
    required String sessionName,
  }) async {
    if (!_isInitialized) await initialize();

    final progress = pomodoroProvider.progress;
    final remainingTime = pomodoroProvider.formattedTime;
    final sessionType = _getSessionTypeText(pomodoroProvider.currentSessionType);
    final sessionNumber = pomodoroProvider.currentSessionNumber;
    final totalSessions = pomodoroProvider.activeSession?.sessionsCount ?? 4;

    // Notification title and content
    final title = '$sessionName - $sessionType';
    final content = '$remainingTime remaining • Session $sessionNumber/$totalSessions';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes it non-dismissible during timer
      autoCancel: false,
      showWhen: false,
      enableVibration: false,
      playSound: false,
      silent: true,
      // Progress bar configuration
      showProgress: true,
      maxProgress: 100,
      progress: (progress * 100).round(),
      indeterminate: false,
      // Color and style
      color: _getNotificationColor(pomodoroProvider.currentSessionType),
      colorized: true,
      category: AndroidNotificationCategory.stopwatch,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Payload contains session info for navigation
    final payload = 'pomodoro_timer:$sessionId:$sessionName';

    await _notificationsPlugin.show(
      _notificationId,
      title,
      content,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> startProgressNotifications({
    required PomodoroProvider pomodoroProvider,
    required int sessionId,
    required String sessionName,
  }) async {
    // Cancel any existing timer
    _progressUpdateTimer?.cancel();

    // Show initial notification
    await showPomodoroTimerNotification(
      pomodoroProvider: pomodoroProvider,
      sessionId: sessionId,
      sessionName: sessionName,
    );

    // Start periodic updates (every second for real-time progress)
    _progressUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (pomodoroProvider.isRunning) {
        await showPomodoroTimerNotification(
          pomodoroProvider: pomodoroProvider,
          sessionId: sessionId,
          sessionName: sessionName,
        );
      } else {
        // Timer is not running, stop updates
        timer.cancel();
        _progressUpdateTimer = null;
      }
    });
  }

  Future<void> stopProgressNotifications() async {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = null;
    await _notificationsPlugin.cancel(_notificationId);
  }

  Future<void> showSessionCompleteNotification({
    required String sessionName,
    required SessionType completedSessionType,
    required String nextSessionType,
    required int sessionId,
  }) async {
    if (!_isInitialized) await initialize();

    final completedTypeText = _getSessionTypeText(completedSessionType);
    final title = '$completedTypeText Complete!';
    final content = 'Time for $nextSessionType. Tap to continue.';

    final androidDetails = AndroidNotificationDetails(
      '${_channelId}_complete',
      'Session Complete',
      channelDescription: 'Notifications when Pomodoro sessions complete',
      importance: Importance.high, // High importance for completion
      priority: Priority.high,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
      color: const Color(0xFF4CAF50),
      colorized: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = 'pomodoro_complete:$sessionId:$sessionName';

    await _notificationsPlugin.show(
      _notificationId + 1, // Different ID for completion notification
      title,
      content,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showAllSessionsCompleteNotification({
    required String sessionName,
    required int totalSessions,
    required int sessionId,
  }) async {
    if (!_isInitialized) await initialize();

    const title = '🎉 All Sessions Complete!';
    final content = 'Completed all $totalSessions sessions of $sessionName. Great work!';

    final androidDetails = AndroidNotificationDetails(
      '${_channelId}_all_complete',
      'All Sessions Complete',
      channelDescription: 'Notifications when all Pomodoro sessions are complete',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
      color: const Color(0xFF4CAF50),
      colorized: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = 'pomodoro_finished:$sessionId:$sessionName';

    await _notificationsPlugin.show(
      _notificationId + 2,
      title,
      content,
      notificationDetails,
      payload: payload,
    );
  }

  // Utility methods
  String _getSessionTypeText(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.work:
        return 'Work Session';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  Color _getNotificationColor(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.work:
        return const Color(0xFF2C2C2C); // Dark for work
      case SessionType.shortBreak:
        return const Color(0xFF4CAF50); // Green for short break
      case SessionType.longBreak:
        return const Color(0xFFFF6B35); // Orange for long break
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final result = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return false;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void dispose() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = null;
  }
}