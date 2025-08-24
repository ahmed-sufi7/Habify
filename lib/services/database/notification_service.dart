import '../../database/daos/notification_dao.dart';
import '../../models/notification.dart';

class NotificationService {
  final NotificationDao _notificationDao = NotificationDao();

  // Notification management
  Future<int> createNotification({
    required String type,
    required String title,
    required String message,
    required DateTime scheduledTime,
    int? habitId,
    int? pomodoroSessionId,
    Map<String, dynamic>? data,
  }) async {
    final now = DateTime.now();
    final notification = AppNotification(
      type: type,
      title: title,
      message: message,
      scheduledTime: scheduledTime,
      habitId: habitId,
      pomodoroSessionId: pomodoroSessionId,
      data: data,
      createdAt: now,
      updatedAt: now,
    );

    // Validate notification data
    final validationErrors = await _notificationDao.validateNotification(notification);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Validation failed: ${validationErrors.join(', ')}');
    }

    return await _notificationDao.insertNotification(notification);
  }

  Future<void> updateNotification(AppNotification notification) async {
    if (notification.id == null) {
      throw ArgumentError('Notification ID cannot be null for update');
    }

    // Validate notification data
    final validationErrors = await _notificationDao.validateNotification(notification);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Validation failed: ${validationErrors.join(', ')}');
    }

    await _notificationDao.updateNotification(notification);
  }

  Future<void> deleteNotification(int id) async {
    await _notificationDao.deleteNotification(id);
  }

  Future<void> markAsRead(int id) async {
    await _notificationDao.markNotificationAsRead(id);
  }

  Future<void> markAsUnread(int id) async {
    await _notificationDao.markNotificationAsUnread(id);
  }

  Future<void> markAllAsRead() async {
    await _notificationDao.markAllNotificationsAsRead();
  }

  // Notification queries
  Future<List<AppNotification>> getAllNotifications() async {
    return await _notificationDao.getAllNotifications();
  }

  Future<List<AppNotification>> getUnreadNotifications() async {
    return await _notificationDao.getUnreadNotifications();
  }

  Future<List<AppNotification>> getNotificationsByType(String type) async {
    return await _notificationDao.getNotificationsByType(type);
  }

  Future<List<AppNotification>> getTodayNotifications() async {
    return await _notificationDao.getTodayNotifications();
  }

  Future<List<AppNotification>> getPendingNotifications() async {
    return await _notificationDao.getPendingNotifications();
  }

  Future<List<AppNotification>> getNotificationsDueNow() async {
    return await _notificationDao.getNotificationsDueNow();
  }

  Future<AppNotification?> getNotificationById(int id) async {
    return await _notificationDao.getNotificationById(id);
  }

  Future<List<AppNotification>> searchNotifications(String query) async {
    return await _notificationDao.searchNotifications(query);
  }

  // Notification processing
  Future<List<AppNotification>> processNotificationQueue() async {
    final dueNotifications = await getNotificationsDueNow();
    final sentNotifications = <AppNotification>[];

    for (final notification in dueNotifications) {
      try {
        // Here you would integrate with the actual notification system
        // For now, we'll just mark as sent
        await _notificationDao.markNotificationAsSent(notification.id!);
        sentNotifications.add(notification);
        
        // Log or trigger actual notification here
        print('Notification sent: ${notification.title} - ${notification.message}');
        
      } catch (e) {
        print('Failed to send notification ${notification.id}: $e');
      }
    }

    return sentNotifications;
  }

  Future<void> rescheduleNotification(int id, DateTime newScheduledTime) async {
    await _notificationDao.updateNotificationScheduledTime(id, newScheduledTime);
  }

  Future<void> snoozeNotification(int id, Duration snoozeDuration) async {
    final notification = await _notificationDao.getNotificationById(id);
    if (notification == null) {
      throw ArgumentError('Notification not found');
    }

    final newScheduledTime = DateTime.now().add(snoozeDuration);
    await rescheduleNotification(id, newScheduledTime);
  }

  // Habit notifications
  Future<void> scheduleHabitReminder({
    required int habitId,
    required String habitName,
    required DateTime scheduledTime,
  }) async {
    final notification = AppNotification.habitReminder(
      habitId: habitId,
      habitName: habitName,
      scheduledTime: scheduledTime,
    );

    await _notificationDao.insertNotification(notification);
  }

  Future<void> scheduleStreakCelebration({
    required int habitId,
    required String habitName,
    required int streakCount,
  }) async {
    final notification = AppNotification.habitStreak(
      habitId: habitId,
      habitName: habitName,
      streakCount: streakCount,
    );

    await _notificationDao.insertNotification(notification);
  }

  Future<List<AppNotification>> getHabitNotifications(int habitId) async {
    return await _notificationDao.getHabitNotifications(habitId);
  }

  Future<void> deleteHabitNotifications(int habitId) async {
    await _notificationDao.deleteNotificationsByHabit(habitId);
  }

  // Pomodoro notifications
  Future<void> schedulePomodoroStart({
    required int pomodoroSessionId,
    required String sessionName,
    required DateTime scheduledTime,
  }) async {
    final notification = AppNotification.pomodoroStart(
      pomodoroSessionId: pomodoroSessionId,
      sessionName: sessionName,
      scheduledTime: scheduledTime,
    );

    await _notificationDao.insertNotification(notification);
  }

  Future<void> schedulePomodoroBreak({
    required int pomodoroSessionId,
    required String sessionName,
    required bool isLongBreak,
  }) async {
    final notification = AppNotification.pomodoroBreak(
      pomodoroSessionId: pomodoroSessionId,
      sessionName: sessionName,
      isLongBreak: isLongBreak,
    );

    await _notificationDao.insertNotification(notification);
  }

  Future<void> schedulePomodoroComplete({
    required int pomodoroSessionId,
    required String sessionName,
    required int completedSessions,
  }) async {
    final notification = AppNotification.pomodoroComplete(
      pomodoroSessionId: pomodoroSessionId,
      sessionName: sessionName,
      completedSessions: completedSessions,
    );

    await _notificationDao.insertNotification(notification);
  }

  Future<List<AppNotification>> getPomodoroNotifications(int pomodoroSessionId) async {
    return await _notificationDao.getPomodoroNotifications(pomodoroSessionId);
  }

  Future<void> deletePomodoroNotifications(int pomodoroSessionId) async {
    await _notificationDao.deleteNotificationsByPomodoroSession(pomodoroSessionId);
  }

  // Bulk operations
  Future<void> deleteReadNotifications() async {
    await _notificationDao.deleteReadNotifications();
  }

  Future<void> deleteExpiredNotifications() async {
    await _notificationDao.deleteExpiredNotifications();
  }

  Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    await _notificationDao.deleteNotificationsOlderThan(cutoffDate);
  }

  // Statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    return await _notificationDao.getNotificationStats();
  }

  Future<Map<String, dynamic>> getNotificationStatsByType() async {
    return await _notificationDao.getNotificationStatsByType();
  }

  Future<int> getUnreadCount() async {
    return await _notificationDao.getUnreadNotificationCount();
  }

  Future<int> getPendingCount() async {
    return await _notificationDao.getPendingNotificationCount();
  }

  Future<bool> hasUnreadNotifications() async {
    return await _notificationDao.hasUnreadNotifications();
  }

  Future<bool> hasPendingNotifications() async {
    return await _notificationDao.hasPendingNotifications();
  }

  // Advanced notification management
  Future<Map<String, dynamic>> getNotificationSummary() async {
    final unreadCount = await getUnreadCount();
    final pendingCount = await getPendingCount();
    final todayNotifications = await getTodayNotifications();
    final stats = await getNotificationStats();

    // Group today's notifications by type
    final Map<String, int> todayByType = {};
    for (final notification in todayNotifications) {
      todayByType[notification.type] = (todayByType[notification.type] ?? 0) + 1;
    }

    return {
      'unread_count': unreadCount,
      'pending_count': pendingCount,
      'today_count': todayNotifications.length,
      'today_by_type': todayByType,
      'overall_stats': stats,
      'has_unread': unreadCount > 0,
      'has_pending': pendingCount > 0,
    };
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _notificationDao.getNotificationHistory(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<AppNotification>> getUpcomingNotifications({int hours = 24}) async {
    final now = DateTime.now();
    final future = now.add(Duration(hours: hours));
    
    return await _notificationDao.getNotificationsByDateRange(now, future);
  }

  // Notification scheduling helpers
  Future<void> scheduleDaily({
    required String type,
    required String title,
    required String message,
    required String time, // Format: "HH:mm"
    int? habitId,
    int? pomodoroSessionId,
    int daysToSchedule = 30,
  }) async {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the time has passed today, start from tomorrow
    final firstScheduleDate = startDate.isBefore(now) 
        ? startDate.add(const Duration(days: 1))
        : startDate;

    final notifications = <AppNotification>[];
    
    for (int i = 0; i < daysToSchedule; i++) {
      final scheduledTime = firstScheduleDate.add(Duration(days: i));
      
      notifications.add(AppNotification(
        type: type,
        title: title,
        message: message,
        scheduledTime: scheduledTime,
        habitId: habitId,
        pomodoroSessionId: pomodoroSessionId,
        createdAt: now,
        updatedAt: now,
      ));
    }

    await _notificationDao.insertNotifications(notifications);
  }

  Future<void> scheduleWeekly({
    required String type,
    required String title,
    required String message,
    required String time, // Format: "HH:mm"
    required List<int> weekdays, // 1=Monday, 7=Sunday
    int? habitId,
    int? pomodoroSessionId,
    int weeksToSchedule = 8,
  }) async {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    final notifications = <AppNotification>[];
    
    for (int week = 0; week < weeksToSchedule; week++) {
      for (final weekday in weekdays) {
        // Calculate the date for this weekday
        final startOfWeek = now.add(Duration(days: week * 7 - now.weekday + 1));
        final targetDate = startOfWeek.add(Duration(days: weekday - 1));
        final scheduledTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );
        
        // Skip if the time has already passed
        if (scheduledTime.isAfter(now)) {
          notifications.add(AppNotification(
            type: type,
            title: title,
            message: message,
            scheduledTime: scheduledTime,
            habitId: habitId,
            pomodoroSessionId: pomodoroSessionId,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }
    }

    await _notificationDao.insertNotifications(notifications);
  }

  // Smart notification features
  Future<List<String>> getSmartNotificationSuggestions() async {
    final suggestions = <String>[];
    
    // Check for habits without recent completions
    // Check for missed habits
    // Check for streak milestones
    // This would integrate with habit and pomodoro services
    
    suggestions.add('Set up daily habit reminders');
    suggestions.add('Enable Pomodoro session notifications');
    suggestions.add('Celebrate your streaks with milestone notifications');
    
    return suggestions;
  }

  Future<void> enableSmartNotifications() async {
    // This would analyze user patterns and schedule intelligent notifications
    // For now, we'll just schedule some basic ones
    
    await scheduleDaily(
      type: 'daily_summary',
      title: 'Daily Progress',
      message: 'Check your habit progress for today!',
      time: '20:00', // 8 PM
      daysToSchedule: 7,
    );
    
    await scheduleWeekly(
      type: 'weekly_review',
      title: 'Weekly Review',
      message: 'Time to review your weekly progress!',
      time: '10:00', // 10 AM
      weekdays: [7], // Sunday
      weeksToSchedule: 4,
    );
  }

  // Integration helpers
  Future<void> handleNotificationTap(int notificationId) async {
    final notification = await getNotificationById(notificationId);
    if (notification == null) return;

    // Mark as read
    await markAsRead(notificationId);

    // Handle different notification types
    switch (notification.type) {
      case 'habit_reminder':
        // Navigate to habit detail or mark as complete
        break;
      case 'habit_streak':
        // Show streak celebration
        break;
      case 'pomodoro_start':
        // Navigate to Pomodoro timer
        break;
      case 'pomodoro_break':
        // Show break screen
        break;
      case 'pomodoro_complete':
        // Show completion celebration
        break;
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    // This would return user's notification preferences
    // For now, return default settings
    return {
      'habit_reminders_enabled': true,
      'streak_celebrations_enabled': true,
      'pomodoro_notifications_enabled': true,
      'daily_summary_enabled': false,
      'weekly_review_enabled': false,
      'quiet_hours_enabled': false,
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '08:00',
    };
  }

  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    // This would update user's notification preferences
    // Implementation would depend on settings storage strategy
  }

  // Debug and testing helpers
  Future<void> createTestNotification() async {
    await createNotification(
      type: 'test',
      title: 'Test Notification',
      message: 'This is a test notification',
      scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  Future<void> triggerNotificationProcessing() async {
    await processNotificationQueue();
  }
}