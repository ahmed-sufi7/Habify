class AppNotification {
  final int? id;
  final String type; // 'habit_reminder', 'habit_streak', 'pomodoro_start', 'pomodoro_break', 'pomodoro_complete', 'achievement'
  final String title;
  final String message;
  final DateTime scheduledTime;
  final bool isSent;
  final bool isRead;
  final int? habitId; // Foreign key to habits table (nullable)
  final int? pomodoroSessionId; // Foreign key to pomodoro_sessions table (nullable)
  final Map<String, dynamic>? data; // Additional data as JSON
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledTime,
    this.isSent = false,
    this.isRead = false,
    this.habitId,
    this.pomodoroSessionId,
    this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toInt(),
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      scheduledTime: DateTime.parse(map['scheduled_time']),
      isSent: map['is_sent'] == 1,
      isRead: map['is_read'] == 1,
      habitId: map['habit_id']?.toInt(),
      pomodoroSessionId: map['pomodoro_session_id']?.toInt(),
      data: map['data'] != null ? _parseData(map['data']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'scheduled_time': scheduledTime.toIso8601String(),
      'is_sent': isSent ? 1 : 0,
      'is_read': isRead ? 1 : 0,
      'habit_id': habitId,
      'pomodoro_session_id': pomodoroSessionId,
      'data': data != null ? _serializeData(data!) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic>? _parseData(String? dataStr) {
    if (dataStr == null || dataStr.isEmpty) return null;
    try {
      // In a real app, you would use jsonDecode here
      // For now, we'll return a simple implementation
      return {'raw': dataStr};
    } catch (e) {
      return null;
    }
  }

  static String _serializeData(Map<String, dynamic> data) {
    // In a real app, you would use jsonEncode here
    // For now, we'll return a simple implementation
    return data.toString();
  }

  AppNotification copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    DateTime? scheduledTime,
    bool? isSent,
    bool? isRead,
    int? habitId,
    int? pomodoroSessionId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isSent: isSent ?? this.isSent,
      isRead: isRead ?? this.isRead,
      habitId: habitId ?? this.habitId,
      pomodoroSessionId: pomodoroSessionId ?? this.pomodoroSessionId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, message: $message, scheduledTime: $scheduledTime, isSent: $isSent, isRead: $isRead, habitId: $habitId, pomodoroSessionId: $pomodoroSessionId, data: $data, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppNotification &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.scheduledTime == scheduledTime &&
        other.isSent == isSent &&
        other.isRead == isRead &&
        other.habitId == habitId &&
        other.pomodoroSessionId == pomodoroSessionId &&
        other.data.toString() == data.toString() &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        scheduledTime.hashCode ^
        isSent.hashCode ^
        isRead.hashCode ^
        habitId.hashCode ^
        pomodoroSessionId.hashCode ^
        data.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // Helper methods
  bool get isHabitNotification => habitId != null;
  bool get isPomodoroNotification => pomodoroSessionId != null;
  bool get isPending => !isSent && scheduledTime.isAfter(DateTime.now());
  bool get isOverdue => !isSent && scheduledTime.isBefore(DateTime.now());

  // Check if notification should be sent now
  bool get shouldSendNow {
    final now = DateTime.now();
    return !isSent && scheduledTime.isBefore(now.add(const Duration(minutes: 1)));
  }

  // Get formatted time
  String get formattedTime {
    return '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
    );

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}';
    }
  }

  // Factory methods for different notification types
  factory AppNotification.habitReminder({
    required int habitId,
    required String habitName,
    required DateTime scheduledTime,
  }) {
    final now = DateTime.now();
    return AppNotification(
      type: 'habit_reminder',
      title: 'Time for your habit!',
      message: 'Don\'t forget to complete: $habitName',
      scheduledTime: scheduledTime,
      habitId: habitId,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory AppNotification.habitStreak({
    required int habitId,
    required String habitName,
    required int streakCount,
  }) {
    final now = DateTime.now();
    return AppNotification(
      type: 'habit_streak',
      title: 'Streak Achievement! 🔥',
      message: '$streakCount days streak for $habitName! Keep it up!',
      scheduledTime: now,
      habitId: habitId,
      data: {'streak_count': streakCount},
      createdAt: now,
      updatedAt: now,
    );
  }

  factory AppNotification.pomodoroStart({
    required int pomodoroSessionId,
    required String sessionName,
    required DateTime scheduledTime,
  }) {
    final now = DateTime.now();
    return AppNotification(
      type: 'pomodoro_start',
      title: 'Pomodoro Session',
      message: 'Time to start your $sessionName session!',
      scheduledTime: scheduledTime,
      pomodoroSessionId: pomodoroSessionId,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory AppNotification.pomodoroBreak({
    required int pomodoroSessionId,
    required String sessionName,
    required bool isLongBreak,
  }) {
    final now = DateTime.now();
    return AppNotification(
      type: 'pomodoro_break',
      title: isLongBreak ? 'Long Break Time!' : 'Break Time!',
      message: 'Take a ${isLongBreak ? 'long' : 'short'} break from $sessionName',
      scheduledTime: now,
      pomodoroSessionId: pomodoroSessionId,
      data: {'is_long_break': isLongBreak},
      createdAt: now,
      updatedAt: now,
    );
  }

  factory AppNotification.pomodoroComplete({
    required int pomodoroSessionId,
    required String sessionName,
    required int completedSessions,
  }) {
    final now = DateTime.now();
    return AppNotification(
      type: 'pomodoro_complete',
      title: 'Session Complete! 🎉',
      message: 'You completed $completedSessions sessions of $sessionName!',
      scheduledTime: now,
      pomodoroSessionId: pomodoroSessionId,
      data: {'completed_sessions': completedSessions},
      createdAt: now,
      updatedAt: now,
    );
  }
}