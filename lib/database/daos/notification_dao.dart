import '../database_helper.dart';
import '../../models/notification.dart';

class NotificationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _tableName = 'notifications';

  // Create
  Future<int> insertNotification(AppNotification notification) async {
    final notificationMap = notification.toMap();
    notificationMap.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert(_tableName, notificationMap);
  }

  Future<List<int>> insertNotifications(List<AppNotification> notifications) async {
    final List<int> ids = [];
    await _dbHelper.transaction((txn) async {
      for (final notification in notifications) {
        final notificationMap = notification.toMap();
        notificationMap.remove('id');
        final id = await txn.insert(_tableName, notificationMap);
        ids.add(id);
      }
    });
    return ids;
  }

  // Read
  Future<List<AppNotification>> getAllNotifications() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<AppNotification?> getNotificationById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return AppNotification.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AppNotification>> getUnreadNotifications() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_read = ?',
      whereArgs: [0],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getReadNotifications() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_read = ?',
      whereArgs: [1],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getPendingNotifications() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_sent = ? AND scheduled_time > ?',
      whereArgs: [0, now.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getSentNotifications() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_sent = ?',
      whereArgs: [1],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getNotificationsDueNow() async {
    final now = DateTime.now();
    final nextMinute = now.add(const Duration(minutes: 1));
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_sent = ? AND scheduled_time <= ?',
      whereArgs: [0, nextMinute.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getNotificationsByType(String type) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getHabitNotifications(int habitId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getPomodoroNotifications(int pomodoroSessionId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'pomodoro_session_id = ?',
      whereArgs: [pomodoroSessionId],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getTodayNotifications() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'scheduled_time >= ? AND scheduled_time < ?',
      whereArgs: [today.toIso8601String(), tomorrow.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<List<AppNotification>> getNotificationsByDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  // Update
  Future<int> updateNotification(AppNotification notification) async {
    if (notification.id == null) {
      throw ArgumentError('Notification ID cannot be null for update');
    }

    final notificationMap = notification.toMap();
    notificationMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await _dbHelper.update(
      _tableName,
      notificationMap,
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  Future<int> markNotificationAsSent(int id) async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_sent': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markNotificationAsRead(int id) async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_read': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markNotificationAsUnread(int id) async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_read': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateNotificationScheduledTime(int id, DateTime newScheduledTime) async {
    return await _dbHelper.update(
      _tableName,
      {
        'scheduled_time': newScheduledTime.toIso8601String(),
        'is_sent': 0, // Reset sent status when rescheduling
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteNotification(int id) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotificationsByHabit(int habitId) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
  }

  Future<int> deleteNotificationsByPomodoroSession(int pomodoroSessionId) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'pomodoro_session_id = ?',
      whereArgs: [pomodoroSessionId],
    );
  }

  Future<int> deleteNotificationsByType(String type) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  Future<int> deleteReadNotifications() async {
    return await _dbHelper.delete(
      _tableName,
      where: 'is_read = ?',
      whereArgs: [1],
    );
  }

  Future<int> deleteSentNotifications() async {
    return await _dbHelper.delete(
      _tableName,
      where: 'is_sent = ?',
      whereArgs: [1],
    );
  }

  Future<int> deleteNotificationsOlderThan(DateTime date) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'created_at < ?',
      whereArgs: [date.toIso8601String()],
    );
  }

  Future<int> deleteExpiredNotifications() async {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 7)); // Keep for 7 days
    
    return await _dbHelper.delete(
      _tableName,
      where: 'is_sent = ? AND scheduled_time < ?',
      whereArgs: [1, cutoffDate.toIso8601String()],
    );
  }

  // Utility methods
  Future<int> getNotificationCount() async {
    final result = await _dbHelper.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return result.first['count'] as int;
  }

  Future<int> getUnreadNotificationCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE is_read = ?',
      [0],
    );
    return result.first['count'] as int;
  }

  Future<int> getPendingNotificationCount() async {
    final now = DateTime.now();
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE is_sent = ? AND scheduled_time > ?',
      [0, now.toIso8601String()],
    );
    return result.first['count'] as int;
  }

  Future<int> getOverdueNotificationCount() async {
    final now = DateTime.now();
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE is_sent = ? AND scheduled_time < ?',
      [0, now.toIso8601String()],
    );
    return result.first['count'] as int;
  }

  Future<bool> hasUnreadNotifications() async {
    final count = await getUnreadNotificationCount();
    return count > 0;
  }

  Future<bool> hasPendingNotifications() async {
    final count = await getPendingNotificationCount();
    return count > 0;
  }

  // Bulk operations
  Future<int> markAllNotificationsAsRead() async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_read': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'is_read = ?',
      whereArgs: [0],
    );
  }

  Future<int> markAllNotificationsAsUnread() async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_read': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'is_read = ?',
      whereArgs: [1],
    );
  }

  Future<int> markNotificationsAsSent(List<int> notificationIds) async {
    if (notificationIds.isEmpty) return 0;
    
    final placeholders = List.filled(notificationIds.length, '?').join(',');
    return await _dbHelper.rawUpdate(
      'UPDATE $_tableName SET is_sent = 1, updated_at = ? WHERE id IN ($placeholders)',
      [DateTime.now().toIso8601String(), ...notificationIds],
    );
  }

  Future<int> rescheduleNotifications(List<int> notificationIds, DateTime newScheduledTime) async {
    if (notificationIds.isEmpty) return 0;
    
    final placeholders = List.filled(notificationIds.length, '?').join(',');
    return await _dbHelper.rawUpdate(
      'UPDATE $_tableName SET scheduled_time = ?, is_sent = 0, updated_at = ? WHERE id IN ($placeholders)',
      [newScheduledTime.toIso8601String(), DateTime.now().toIso8601String(), ...notificationIds],
    );
  }

  // Statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_notifications,
        SUM(CASE WHEN is_sent = 1 THEN 1 ELSE 0 END) as sent_notifications,
        SUM(CASE WHEN is_sent = 0 THEN 1 ELSE 0 END) as pending_notifications,
        SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_notifications,
        SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_notifications,
        COUNT(DISTINCT type) as notification_types
      FROM $_tableName
    ''');

    final row = result.first;
    return {
      'total_notifications': row['total_notifications'] as int,
      'sent_notifications': row['sent_notifications'] as int,
      'pending_notifications': row['pending_notifications'] as int,
      'read_notifications': row['read_notifications'] as int,
      'unread_notifications': row['unread_notifications'] as int,
      'notification_types': row['notification_types'] as int,
    };
  }

  Future<Map<String, dynamic>> getNotificationStatsByType() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        type,
        COUNT(*) as count,
        SUM(CASE WHEN is_sent = 1 THEN 1 ELSE 0 END) as sent_count,
        SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_count
      FROM $_tableName
      GROUP BY type
      ORDER BY count DESC
    ''');

    return {
      'type_distribution': result,
      'total_types': result.length,
    };
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE scheduled_time >= ? AND scheduled_time <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      whereClause = 'WHERE scheduled_time >= ?';
      whereArgs = [startDate.toIso8601String()];
    }
    
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        n.*,
        h.name as habit_name,
        ps.name as pomodoro_session_name
      FROM $_tableName n
      LEFT JOIN habits h ON n.habit_id = h.id
      LEFT JOIN pomodoro_sessions ps ON n.pomodoro_session_id = ps.id
      $whereClause
      ORDER BY n.scheduled_time DESC
      $limitClause
    ''', whereArgs);

    return maps;
  }

  // Search and filter
  Future<List<AppNotification>> searchNotifications(String query) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'title LIKE ? OR message LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'scheduled_time DESC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  // Scheduled notification management
  Future<List<AppNotification>> getUpcomingHabitReminders(int hours) async {
    final now = DateTime.now();
    final future = now.add(Duration(hours: hours));
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'type = ? AND is_sent = ? AND scheduled_time >= ? AND scheduled_time <= ?',
      whereArgs: ['habit_reminder', 0, now.toIso8601String(), future.toIso8601String()],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  Future<void> scheduleHabitReminders(int habitId, String habitName, List<DateTime> scheduleTimes) async {
    await _dbHelper.transaction((txn) async {
      // First, delete existing habit reminders for this habit
      await txn.delete(
        _tableName,
        where: 'habit_id = ? AND type = ?',
        whereArgs: [habitId, 'habit_reminder'],
      );
      
      // Then, insert new reminders
      for (final scheduledTime in scheduleTimes) {
        final notification = AppNotification.habitReminder(
          habitId: habitId,
          habitName: habitName,
          scheduledTime: scheduledTime,
        );
        final notificationMap = notification.toMap();
        notificationMap.remove('id');
        await txn.insert(_tableName, notificationMap);
      }
    });
  }

  Future<void> scheduleStreakCelebration(int habitId, String habitName, int streakCount) async {
    final notification = AppNotification.habitStreak(
      habitId: habitId,
      habitName: habitName,
      streakCount: streakCount,
    );
    await insertNotification(notification);
  }

  // Cleanup methods
  Future<void> cleanupOldNotifications() async {
    await _dbHelper.transaction((txn) async {
      final now = DateTime.now();
      
      // Delete sent notifications older than 30 days
      final oldSentCutoff = now.subtract(const Duration(days: 30));
      await txn.delete(
        _tableName,
        where: 'is_sent = 1 AND scheduled_time < ?',
        whereArgs: [oldSentCutoff.toIso8601String()],
      );
      
      // Delete unsent notifications that are more than 7 days overdue
      final overdueCutoff = now.subtract(const Duration(days: 7));
      await txn.delete(
        _tableName,
        where: 'is_sent = 0 AND scheduled_time < ?',
        whereArgs: [overdueCutoff.toIso8601String()],
      );
    });
  }

  // Validation
  Future<List<String>> validateNotification(AppNotification notification) async {
    final errors = <String>[];
    
    if (notification.title.trim().isEmpty) {
      errors.add('Notification title cannot be empty');
    }
    
    if (notification.message.trim().isEmpty) {
      errors.add('Notification message cannot be empty');
    }
    
    if (notification.type.trim().isEmpty) {
      errors.add('Notification type cannot be empty');
    }
    
    // Validate that scheduled time is not too far in the past
    final now = DateTime.now();
    if (notification.scheduledTime.isBefore(now.subtract(const Duration(hours: 1)))) {
      errors.add('Scheduled time cannot be more than 1 hour in the past');
    }
    
    // Validate that either habitId or pomodoroSessionId is provided for relevant types
    if (notification.type.startsWith('habit_') && notification.habitId == null) {
      errors.add('Habit ID is required for habit-related notifications');
    }
    
    if (notification.type.startsWith('pomodoro_') && notification.pomodoroSessionId == null) {
      errors.add('Pomodoro session ID is required for pomodoro-related notifications');
    }
    
    return errors;
  }
}