import '../../database/daos/pomodoro_dao.dart';
import '../../database/daos/notification_dao.dart';
import '../../models/pomodoro_session.dart';
import '../../models/pomodoro_completion.dart';
import '../../models/notification.dart';

class PomodoroService {
  final PomodoroDao _pomodoroDao = PomodoroDao();
  final NotificationDao _notificationDao = NotificationDao();

  // Session management
  Future<int> createPomodoroSession({
    required String name,
    int workDurationMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int sessionsCount = 4,
    bool notificationEnabled = true,
    bool alarmEnabled = false,
    String? description,
  }) async {
    final now = DateTime.now();
    final session = PomodoroSession(
      name: name,
      workDurationMinutes: workDurationMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      sessionsCount: sessionsCount,
      notificationEnabled: notificationEnabled,
      alarmEnabled: alarmEnabled,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    // Validate session data
    final validationErrors = await _pomodoroDao.validateSession(session);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Validation failed: ${validationErrors.join(', ')}');
    }

    return await _pomodoroDao.insertSession(session);
  }

  Future<void> updatePomodoroSession(PomodoroSession session) async {
    if (session.id == null) {
      throw ArgumentError('Session ID cannot be null for update');
    }

    // Validate session data
    final validationErrors = await _pomodoroDao.validateSession(session);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Validation failed: ${validationErrors.join(', ')}');
    }

    await _pomodoroDao.updateSession(session);
  }

  Future<void> deletePomodoroSession(int sessionId) async {
    // Check if session has active completions
    final activeCompletion = await _pomodoroDao.getActiveCompletion();
    if (activeCompletion != null && activeCompletion.sessionId == sessionId) {
      throw ArgumentError('Cannot delete session with active timer');
    }

    // Delete associated data
    await _pomodoroDao.deleteCompletionsBySession(sessionId);
    await _notificationDao.deleteNotificationsByPomodoroSession(sessionId);
    await _pomodoroDao.deleteSession(sessionId);
  }

  Future<void> deactivatePomodoroSession(int sessionId) async {
    await _pomodoroDao.updateSessionStatus(sessionId, false);
  }

  Future<void> reactivatePomodoroSession(int sessionId) async {
    await _pomodoroDao.updateSessionStatus(sessionId, true);
  }

  // Timer operations
  Future<Map<String, dynamic>> startWorkSession(int sessionId, {int sessionNumber = 1}) async {
    // Check if there's already an active session
    final activeCompletion = await _pomodoroDao.getActiveCompletion();
    if (activeCompletion != null) {
      throw ArgumentError('Another session is already active. Please complete or cancel it first.');
    }

    final session = await _pomodoroDao.getSessionById(sessionId);
    if (session == null || !session.isActive) {
      throw ArgumentError('Session not found or inactive');
    }

    final completionId = await _pomodoroDao.startWorkSession(sessionId, sessionNumber);

    // Schedule notification for session end
    if (session.notificationEnabled) {
      final endTime = DateTime.now().add(Duration(minutes: session.workDurationMinutes));
      final notification = AppNotification.pomodoroBreak(
        pomodoroSessionId: sessionId,
        sessionName: session.name,
        isLongBreak: sessionNumber % 4 == 0, // Long break every 4 sessions
      );
      
      await _notificationDao.insertNotification(notification.copyWith(scheduledTime: endTime));
    }

    return {
      'completion_id': completionId,
      'session': session,
      'duration_minutes': session.workDurationMinutes,
      'session_number': sessionNumber,
    };
  }

  Future<Map<String, dynamic>> startBreakSession(int sessionId, int sessionNumber, bool isLongBreak) async {
    // Check if there's already an active session
    final activeCompletion = await _pomodoroDao.getActiveCompletion();
    if (activeCompletion != null) {
      throw ArgumentError('Another session is already active. Please complete or cancel it first.');
    }

    final session = await _pomodoroDao.getSessionById(sessionId);
    if (session == null || !session.isActive) {
      throw ArgumentError('Session not found or inactive');
    }

    final completionId = await _pomodoroDao.startBreakSession(sessionId, sessionNumber, isLongBreak);
    final breakDuration = isLongBreak ? session.longBreakMinutes : session.shortBreakMinutes;

    // Schedule notification for break end
    if (session.notificationEnabled) {
      final endTime = DateTime.now().add(Duration(minutes: breakDuration));
      final notification = AppNotification.pomodoroStart(
        pomodoroSessionId: sessionId,
        sessionName: session.name,
        scheduledTime: endTime,
      );
      
      await _notificationDao.insertNotification(notification);
    }

    return {
      'completion_id': completionId,
      'session': session,
      'duration_minutes': breakDuration,
      'session_number': sessionNumber,
      'is_long_break': isLongBreak,
    };
  }

  Future<void> completeCurrentSession() async {
    final activeCompletion = await _pomodoroDao.getActiveCompletion();
    if (activeCompletion == null) {
      throw ArgumentError('No active session to complete');
    }

    await _pomodoroDao.completeSession(activeCompletion.id!);

    // Create completion notification
    final session = await _pomodoroDao.getSessionById(activeCompletion.sessionId);
    if (session != null && session.notificationEnabled) {
      final notification = AppNotification.pomodoroComplete(
        pomodoroSessionId: activeCompletion.sessionId,
        sessionName: session.name,
        completedSessions: 1,
      );
      await _notificationDao.insertNotification(notification);
    }
  }

  Future<void> cancelCurrentSession({String? notes}) async {
    final activeCompletion = await _pomodoroDao.getActiveCompletion();
    if (activeCompletion == null) {
      throw ArgumentError('No active session to cancel');
    }

    await _pomodoroDao.cancelSession(activeCompletion.id!, notes: notes);
  }

  Future<Map<String, dynamic>?> getCurrentSession() async {
    final activeCompletion = await _pomodoroDao.getActiveCompletion();
    if (activeCompletion == null) return null;

    final session = await _pomodoroDao.getSessionById(activeCompletion.sessionId);
    if (session == null) return null;

    final now = DateTime.now();
    final elapsed = now.difference(activeCompletion.startTime);
    final totalDuration = Duration(
      minutes: activeCompletion.isWorkSession 
          ? session.workDurationMinutes 
          : (activeCompletion.isLongBreak ? session.longBreakMinutes : session.shortBreakMinutes),
    );
    final remaining = totalDuration - elapsed;

    return {
      'completion': activeCompletion,
      'session': session,
      'elapsed_seconds': elapsed.inSeconds,
      'remaining_seconds': remaining.inSeconds > 0 ? remaining.inSeconds : 0,
      'total_seconds': totalDuration.inSeconds,
      'is_overtime': remaining.inSeconds <= 0,
    };
  }

  // Session queries
  Future<List<PomodoroSession>> getActiveSessions() async {
    return await _pomodoroDao.getActiveSessions();
  }

  Future<PomodoroSession?> getSessionById(int sessionId) async {
    return await _pomodoroDao.getSessionById(sessionId);
  }

  Future<List<PomodoroSession>> getAllSessions() async {
    return await _pomodoroDao.getAllSessions();
  }

  Future<PomodoroSession?> getSessionByName(String name) async {
    return await _pomodoroDao.getSessionByName(name);
  }

  Future<List<PomodoroSession>> searchSessions(String query) async {
    return await _pomodoroDao.searchSessions(query);
  }

  // Completion queries
  Future<List<PomodoroCompletion>> getTodayCompletions() async {
    return await _pomodoroDao.getTodayCompletions();
  }

  Future<List<PomodoroCompletion>> getCompletionsBySession(int sessionId) async {
    return await _pomodoroDao.getCompletionsBySession(sessionId);
  }

  Future<List<PomodoroCompletion>> getCompletionsByDateRange(DateTime startDate, DateTime endDate) async {
    return await _pomodoroDao.getCompletionsByDateRange(startDate, endDate);
  }

  Future<bool> hasActiveSession() async {
    return await _pomodoroDao.hasActiveSession();
  }

  // Statistics
  Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
    return await _pomodoroDao.getSessionStats(sessionId);
  }

  Future<Map<String, dynamic>> getOverallPomodoroStats() async {
    return await _pomodoroDao.getOverallStats();
  }

  Future<List<Map<String, dynamic>>> getDailyStats(int daysBack) async {
    return await _pomodoroDao.getDailyStats(daysBack);
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats(int weeksBack) async {
    return await _pomodoroDao.getWeeklyStats(weeksBack);
  }

  Future<List<Map<String, dynamic>>> getSessionUsageStats() async {
    return await _pomodoroDao.getSessionUsageStats();
  }

  // Advanced timer operations
  Future<Map<String, dynamic>> runFullPomodoroSequence(int sessionId) async {
    final session = await _pomodoroDao.getSessionById(sessionId);
    if (session == null || !session.isActive) {
      throw ArgumentError('Session not found or inactive');
    }

    final List<Map<String, dynamic>> sessionHistory = [];
    
    for (int i = 1; i <= session.sessionsCount; i++) {
      // Work session
      final workResult = await startWorkSession(sessionId, sessionNumber: i);
      sessionHistory.add({
        'type': 'work',
        'session_number': i,
        'completion_id': workResult['completion_id'],
        'duration_minutes': session.workDurationMinutes,
      });

      // Break session (if not the last session)
      if (i < session.sessionsCount) {
        final isLongBreak = i % 4 == 0;
        final breakResult = await startBreakSession(sessionId, i, isLongBreak);
        sessionHistory.add({
          'type': isLongBreak ? 'long_break' : 'short_break',
          'session_number': i,
          'completion_id': breakResult['completion_id'],
          'duration_minutes': isLongBreak ? session.longBreakMinutes : session.shortBreakMinutes,
          'is_long_break': isLongBreak,
        });
      }
    }

    return {
      'session': session,
      'total_sessions': session.sessionsCount,
      'total_duration_minutes': session.totalMinutes,
      'session_history': sessionHistory,
    };
  }

  Future<Map<String, dynamic>> getNextRecommendedAction(int sessionId) async {
    final session = await _pomodoroDao.getSessionById(sessionId);
    if (session == null || !session.isActive) {
      throw ArgumentError('Session not found or inactive');
    }

    // Get today's completions for this session
    final todayCompletions = await _pomodoroDao.getTodayCompletions();
    final sessionCompletions = todayCompletions
        .where((c) => c.sessionId == sessionId && c.completed)
        .toList();

    final completedWorkSessions = sessionCompletions
        .where((c) => c.isWorkSession)
        .length;

    if (completedWorkSessions == 0) {
      return {
        'action': 'start_work',
        'session_number': 1,
        'message': 'Ready to start your first work session!',
      };
    }

    if (completedWorkSessions >= session.sessionsCount) {
      return {
        'action': 'completed',
        'message': 'You\'ve completed all sessions for today! Well done!',
        'completed_sessions': completedWorkSessions,
      };
    }

    final nextSessionNumber = completedWorkSessions + 1;
    final isLongBreakNext = completedWorkSessions % 4 == 0;

    // Check if we need a break
    final lastCompletion = sessionCompletions.isNotEmpty 
        ? sessionCompletions.last 
        : null;

    if (lastCompletion != null && lastCompletion.isWorkSession) {
      return {
        'action': 'start_break',
        'session_number': completedWorkSessions,
        'is_long_break': isLongBreakNext,
        'message': isLongBreakNext 
            ? 'Time for a long break!' 
            : 'Time for a short break!',
      };
    }

    return {
      'action': 'start_work',
      'session_number': nextSessionNumber,
      'message': 'Ready for work session $nextSessionNumber!',
    };
  }

  // Activity history
  Future<List<Map<String, dynamic>>> getActivityHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _pomodoroDao.getActivityHistory(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Productivity insights
  Future<Map<String, dynamic>> getProductivityInsights(int daysBack) async {
    final dailyStats = await getDailyStats(daysBack);
    
    if (dailyStats.isEmpty) {
      return {
        'total_work_minutes': 0,
        'total_sessions': 0,
        'average_daily_minutes': 0.0,
        'most_productive_day': null,
        'completion_rate': 0.0,
        'insights': ['Start your first Pomodoro session to see insights!'],
      };
    }

    final totalWorkMinutes = dailyStats.fold<int>(0, (sum, day) => sum + (day['work_minutes'] as int));
    final totalSessions = dailyStats.fold<int>(0, (sum, day) => sum + (day['total_sessions'] as int));
    final completedSessions = dailyStats.fold<int>(0, (sum, day) => sum + (day['completed_sessions'] as int));
    
    final averageDailyMinutes = totalWorkMinutes / daysBack;
    final completionRate = totalSessions > 0 ? (completedSessions / totalSessions * 100) : 0.0;
    
    // Find most productive day
    final mostProductiveDay = dailyStats.reduce((a, b) => 
        (a['work_minutes'] as int) > (b['work_minutes'] as int) ? a : b);

    // Generate insights
    final insights = <String>[];
    
    if (completionRate >= 80) {
      insights.add('Excellent focus! You complete most of your Pomodoro sessions.');
    } else if (completionRate >= 60) {
      insights.add('Good consistency! Try to complete more sessions for better focus.');
    } else {
      insights.add('Consider shorter work sessions to improve completion rate.');
    }

    if (averageDailyMinutes >= 120) {
      insights.add('You\'re very productive with ${averageDailyMinutes.round()} minutes of focused work daily.');
    } else if (averageDailyMinutes >= 60) {
      insights.add('Good daily focus time! Consider adding more sessions.');
    } else {
      insights.add('Try to increase your daily focused work time for better productivity.');
    }

    return {
      'total_work_minutes': totalWorkMinutes,
      'total_work_hours': (totalWorkMinutes / 60).round(),
      'total_sessions': totalSessions,
      'completed_sessions': completedSessions,
      'average_daily_minutes': averageDailyMinutes,
      'most_productive_day': mostProductiveDay,
      'completion_rate': completionRate,
      'insights': insights,
    };
  }

  // Data cleanup
  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    // Clean up old completions
    await _pomodoroDao.deleteCompletionsOlderThan(cutoffDate);
    
    // Clean up old pomodoro notifications
    await _notificationDao.deleteNotificationsOlderThan(cutoffDate);
  }

  // Export data
  Future<Map<String, dynamic>> exportSessionData(int sessionId) async {
    final session = await _pomodoroDao.getSessionById(sessionId);
    if (session == null) {
      throw ArgumentError('Session not found');
    }

    final completions = await _pomodoroDao.getCompletionsBySession(sessionId);
    final stats = await _pomodoroDao.getSessionStats(sessionId);

    return {
      'session': session.toMap(),
      'completions': completions.map((c) => c.toMap()).toList(),
      'statistics': stats,
    };
  }

  // Dashboard data
  Future<Map<String, dynamic>> getPomodorosDashboardData() async {
    final activeSessions = await getActiveSessions();
    final currentSession = await getCurrentSession();
    final todayCompletions = await getTodayCompletions();
    final overallStats = await getOverallPomodoroStats();
    final dailyStats = await getDailyStats(7); // Last 7 days

    // Today's stats
    final todayWorkSessions = todayCompletions.where((c) => c.isWorkSession && c.completed).length;
    final todayWorkMinutes = todayCompletions
        .where((c) => c.isWorkSession && c.completed)
        .fold<int>(0, (sum, c) => sum + c.actualDurationMinutes);

    return {
      'active_sessions': activeSessions,
      'current_session': currentSession,
      'today_completions': todayCompletions,
      'today_work_sessions': todayWorkSessions,
      'today_work_minutes': todayWorkMinutes,
      'overall_stats': overallStats,
      'weekly_stats': dailyStats,
      'has_active_timer': currentSession != null,
    };
  }

  // Templates and presets
  Future<List<PomodoroSession>> getPresetSessions() async {
    final presets = [
      PomodoroSession.defaultSession(name: 'Classic Pomodoro'),
      PomodoroSession(
        name: 'Extended Focus',
        workDurationMinutes: 45,
        shortBreakMinutes: 10,
        longBreakMinutes: 30,
        sessionsCount: 4,
        notificationEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PomodoroSession(
        name: 'Short Bursts',
        workDurationMinutes: 15,
        shortBreakMinutes: 5,
        longBreakMinutes: 15,
        sessionsCount: 6,
        notificationEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PomodoroSession(
        name: 'Deep Work',
        workDurationMinutes: 90,
        shortBreakMinutes: 20,
        longBreakMinutes: 60,
        sessionsCount: 3,
        notificationEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    return presets;
  }

  Future<int> createSessionFromPreset(String presetName) async {
    final presets = await getPresetSessions();
    final preset = presets.firstWhere(
      (p) => p.name == presetName,
      orElse: () => throw ArgumentError('Preset not found: $presetName'),
    );

    return await createPomodoroSession(
      name: preset.name,
      workDurationMinutes: preset.workDurationMinutes,
      shortBreakMinutes: preset.shortBreakMinutes,
      longBreakMinutes: preset.longBreakMinutes,
      sessionsCount: preset.sessionsCount,
      notificationEnabled: preset.notificationEnabled,
      alarmEnabled: preset.alarmEnabled,
      description: preset.description,
    );
  }
}