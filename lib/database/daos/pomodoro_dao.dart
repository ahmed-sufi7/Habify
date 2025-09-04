import '../database_helper.dart';
import '../../models/pomodoro_session.dart';
import '../../models/pomodoro_completion.dart';

class PomodoroDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _sessionsTableName = 'pomodoro_sessions';
  static const String _completionsTableName = 'pomodoro_completions';

  // Pomodoro Session CRUD operations

  // Create
  Future<int> insertSession(PomodoroSession session) async {
    final sessionMap = session.toMap();
    sessionMap.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert(_sessionsTableName, sessionMap);
  }

  Future<List<int>> insertSessions(List<PomodoroSession> sessions) async {
    final List<int> ids = [];
    await _dbHelper.transaction((txn) async {
      for (final session in sessions) {
        final sessionMap = session.toMap();
        sessionMap.remove('id');
        final id = await txn.insert(_sessionsTableName, sessionMap);
        ids.add(id);
      }
    });
    return ids;
  }

  // Read
  Future<List<PomodoroSession>> getAllSessions() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _sessionsTableName,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => PomodoroSession.fromMap(map)).toList();
  }

  Future<List<PomodoroSession>> getActiveSessions() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _sessionsTableName,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => PomodoroSession.fromMap(map)).toList();
  }

  Future<PomodoroSession?> getSessionById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _sessionsTableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return PomodoroSession.fromMap(maps.first);
    }
    return null;
  }

  Future<PomodoroSession?> getSessionByName(String name) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _sessionsTableName,
      where: 'name = ? AND is_active = ?',
      whereArgs: [name, 1],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return PomodoroSession.fromMap(maps.first);
    }
    return null;
  }

  // Update
  Future<int> updateSession(PomodoroSession session) async {
    if (session.id == null) {
      throw ArgumentError('Session ID cannot be null for update');
    }

    final sessionMap = session.toMap();
    sessionMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await _dbHelper.update(
      _sessionsTableName,
      sessionMap,
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> updateSessionStatus(int id, bool isActive) async {
    return await _dbHelper.update(
      _sessionsTableName,
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSessionName(int id, String newName) async {
    return await _dbHelper.update(
      _sessionsTableName,
      {
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteSession(int id) async {
    return await _dbHelper.delete(
      _sessionsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Pomodoro Completion CRUD operations

  // Create
  Future<int> insertCompletion(PomodoroCompletion completion) async {
    final completionMap = completion.toMap();
    completionMap.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert(_completionsTableName, completionMap);
  }

  Future<int> startWorkSession(int sessionId, int sessionNumber) async {
    final completion = PomodoroCompletion.workSession(
      sessionId: sessionId,
      sessionNumber: sessionNumber,
    );
    return await insertCompletion(completion);
  }

  Future<int> startBreakSession(int sessionId, int sessionNumber, bool isLongBreak) async {
    final completion = PomodoroCompletion.breakSession(
      sessionId: sessionId,
      sessionNumber: sessionNumber,
      isLongBreak: isLongBreak,
    );
    return await insertCompletion(completion);
  }

  // Read
  Future<List<PomodoroCompletion>> getAllCompletions() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _completionsTableName,
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => PomodoroCompletion.fromMap(map)).toList();
  }

  Future<PomodoroCompletion?> getCompletionById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _completionsTableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return PomodoroCompletion.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PomodoroCompletion>> getCompletionsBySession(int sessionId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _completionsTableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => PomodoroCompletion.fromMap(map)).toList();
  }

  Future<List<PomodoroCompletion>> getTodayCompletions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = today.toIso8601String();
    final tomorrowStr = today.add(const Duration(days: 1)).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _completionsTableName,
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [todayStr, tomorrowStr],
      orderBy: 'start_time ASC',
    );
    return maps.map((map) => PomodoroCompletion.fromMap(map)).toList();
  }

  Future<PomodoroCompletion?> getActiveCompletion() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _completionsTableName,
      where: 'end_time IS NULL AND completed = ?',
      whereArgs: [0],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return PomodoroCompletion.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PomodoroCompletion>> getCompletionsByDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _completionsTableName,
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'start_time ASC',
    );
    return maps.map((map) => PomodoroCompletion.fromMap(map)).toList();
  }

  // Update
  Future<int> updateCompletion(PomodoroCompletion completion) async {
    if (completion.id == null) {
      throw ArgumentError('Completion ID cannot be null for update');
    }

    final completionMap = completion.toMap();
    completionMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await _dbHelper.update(
      _completionsTableName,
      completionMap,
      where: 'id = ?',
      whereArgs: [completion.id],
    );
  }

  Future<int> completeSession(int completionId) async {
    final now = DateTime.now();
    
    // Get the completion to calculate actual duration
    final completion = await getCompletionById(completionId);
    if (completion == null) {
      throw ArgumentError('Completion not found');
    }
    
    final actualDuration = now.difference(completion.startTime).inMinutes;
    
    return await _dbHelper.update(
      _completionsTableName,
      {
        'end_time': now.toIso8601String(),
        'completed': 1,
        'actual_duration_minutes': actualDuration,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [completionId],
    );
  }

  Future<int> cancelSession(int completionId, {String? notes}) async {
    final now = DateTime.now();
    
    // Get the completion to calculate actual duration
    final completion = await getCompletionById(completionId);
    if (completion == null) {
      throw ArgumentError('Completion not found');
    }
    
    final actualDuration = now.difference(completion.startTime).inMinutes;
    
    return await _dbHelper.update(
      _completionsTableName,
      {
        'end_time': now.toIso8601String(),
        'completed': 0,
        'actual_duration_minutes': actualDuration,
        'notes': notes,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [completionId],
    );
  }

  Future<int> updateCompletionNotes(int id, String? notes) async {
    return await _dbHelper.update(
      _completionsTableName,
      {
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteCompletion(int id) async {
    return await _dbHelper.delete(
      _completionsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCompletionsBySession(int sessionId) async {
    return await _dbHelper.delete(
      _completionsTableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<int> deleteCompletionsOlderThan(DateTime date) async {
    final dateStr = date.toIso8601String();
    return await _dbHelper.delete(
      _completionsTableName,
      where: 'start_time < ?',
      whereArgs: [dateStr],
    );
  }

  // Utility methods
  Future<bool> sessionExists(String name) async {
    final session = await getSessionByName(name);
    return session != null;
  }

  Future<bool> sessionExistsById(int id) async {
    final session = await getSessionById(id);
    return session != null;
  }

  Future<int> getSessionCount() async {
    final result = await _dbHelper.rawQuery('SELECT COUNT(*) as count FROM $_sessionsTableName');
    return result.first['count'] as int;
  }

  Future<int> getActiveSessionCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_sessionsTableName WHERE is_active = ?',
      [1],
    );
    return result.first['count'] as int;
  }

  Future<int> getCompletionCount() async {
    final result = await _dbHelper.rawQuery('SELECT COUNT(*) as count FROM $_completionsTableName');
    return result.first['count'] as int;
  }

  Future<bool> hasActiveSession() async {
    final activeCompletion = await getActiveCompletion();
    return activeCompletion != null;
  }

  // Statistics and analytics
  Future<Map<String, dynamic>> getSessionStats(int sessionId) async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed_sessions,
        SUM(CASE WHEN completed = 0 AND end_time IS NOT NULL THEN 1 ELSE 0 END) as cancelled_sessions,
        SUM(CASE WHEN session_type = 'work' AND completed = 1 THEN 1 ELSE 0 END) as completed_work_sessions,
        SUM(CASE WHEN session_type = 'work' AND completed = 1 THEN actual_duration_minutes ELSE 0 END) as total_work_minutes,
        AVG(CASE WHEN session_type = 'work' AND completed = 1 THEN actual_duration_minutes ELSE NULL END) as avg_work_duration
      FROM $_completionsTableName
      WHERE session_id = ?
    ''', [sessionId]);

    final row = result.first;
    return {
      'total_sessions': row['total_sessions'] as int,
      'completed_sessions': row['completed_sessions'] as int,
      'cancelled_sessions': row['cancelled_sessions'] as int,
      'completed_work_sessions': row['completed_work_sessions'] as int,
      'total_work_minutes': row['total_work_minutes'] as int,
      'avg_work_duration': row['avg_work_duration'] as double? ?? 0.0,
      'completion_rate': (row['total_sessions'] as int) > 0 
          ? ((row['completed_sessions'] as int) / (row['total_sessions'] as int) * 100)
          : 0.0,
    };
  }

  Future<Map<String, dynamic>> getOverallStats() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_completions,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed_sessions,
        SUM(CASE WHEN session_type = 'work' AND completed = 1 THEN 1 ELSE 0 END) as completed_work_sessions,
        SUM(CASE WHEN session_type = 'work' AND completed = 1 THEN actual_duration_minutes ELSE 0 END) as total_work_minutes,
        COUNT(DISTINCT session_id) as sessions_used
      FROM $_completionsTableName
    ''');

    final row = result.first;
    final totalWorkMinutes = row['total_work_minutes'] as int;
    
    return {
      'total_completions': row['total_completions'] as int,
      'completed_sessions': row['completed_sessions'] as int,
      'completed_work_sessions': row['completed_work_sessions'] as int,
      'total_work_minutes': totalWorkMinutes,
      'total_work_hours': (totalWorkMinutes / 60).round(),
      'sessions_used': row['sessions_used'] as int,
      'completion_rate': (row['total_completions'] as int) > 0 
          ? ((row['completed_sessions'] as int) / (row['total_completions'] as int) * 100)
          : 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getDailyStats(int daysBack) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: daysBack));
    final startDateStr = startDate.toIso8601String();

    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        DATE(start_time) as date,
        COUNT(*) as total_sessions,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed_sessions,
        SUM(CASE WHEN session_type = 'work' AND completed = 1 THEN actual_duration_minutes ELSE 0 END) as work_minutes
      FROM $_completionsTableName
      WHERE start_time >= ?
      GROUP BY DATE(start_time)
      ORDER BY date DESC
    ''', [startDateStr]);

    return maps;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats(int weeksBack) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeksBack * 7));
    final startDateStr = startDate.toIso8601String();

    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        strftime('%Y-%W', start_time) as week,
        COUNT(*) as total_sessions,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed_sessions,
        SUM(CASE WHEN session_type = 'work' AND completed = 1 THEN actual_duration_minutes ELSE 0 END) as work_minutes
      FROM $_completionsTableName
      WHERE start_time >= ?
      GROUP BY strftime('%Y-%W', start_time)
      ORDER BY week DESC
    ''', [startDateStr]);

    return maps;
  }

  Future<List<Map<String, dynamic>>> getSessionUsageStats() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        ps.id,
        ps.name,
        ps.work_duration_minutes,
        ps.sessions_count,
        COUNT(pc.id) as times_used,
        SUM(CASE WHEN pc.completed = 1 THEN 1 ELSE 0 END) as completed_count,
        SUM(CASE WHEN pc.session_type = 'work' AND pc.completed = 1 THEN pc.actual_duration_minutes ELSE 0 END) as total_work_minutes
      FROM $_sessionsTableName ps
      LEFT JOIN $_completionsTableName pc ON ps.id = pc.session_id
      WHERE ps.is_active = 1
      GROUP BY ps.id, ps.name, ps.work_duration_minutes, ps.sessions_count
      ORDER BY times_used DESC, ps.name ASC
    ''');

    return maps;
  }

  // Search and filter
  Future<List<PomodoroSession>> searchSessions(String query) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _sessionsTableName,
      where: '(name LIKE ? OR description LIKE ?) AND is_active = ?',
      whereArgs: ['%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => PomodoroSession.fromMap(map)).toList();
  }

  Future<List<PomodoroCompletion>> getCompletionsBySessionType(String sessionType) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _completionsTableName,
      where: 'session_type = ?',
      whereArgs: [sessionType],
      orderBy: 'start_time DESC',
    );
    return maps.map((map) => PomodoroCompletion.fromMap(map)).toList();
  }

  // Bulk operations
  Future<int> deactivateAllSessions() async {
    return await _dbHelper.update(
      _sessionsTableName,
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> activateAllSessions() async {
    return await _dbHelper.update(
      _sessionsTableName,
      {
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // Validation
  Future<List<String>> validateSession(PomodoroSession session) async {
    final errors = <String>[];
    
    if (session.name.trim().isEmpty) {
      errors.add('Session name cannot be empty');
    }
    
    if (session.workDurationMinutes <= 0) {
      errors.add('Work duration must be greater than 0');
    }
    
    if (session.shortBreakMinutes < 0) {
      errors.add('Short break duration cannot be negative');
    }
    
    if (session.longBreakMinutes < 0) {
      errors.add('Long break duration cannot be negative');
    }
    
    if (session.sessionsCount <= 0) {
      errors.add('Sessions count must be greater than 0');
    }
    
    // Note: Allowing duplicate session names as users may want multiple sessions
    // with the same name (e.g., multiple "Study Session" or "Work Session")
    
    return errors;
  }

  // Activity history
  Future<List<Map<String, dynamic>>> getActivityHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE pc.start_time >= ? AND pc.start_time <= ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      whereClause = 'WHERE pc.start_time >= ?';
      whereArgs = [startDate.toIso8601String()];
    }
    
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        pc.*,
        ps.name as session_name,
        ps.work_duration_minutes,
        ps.short_break_minutes,
        ps.long_break_minutes
      FROM $_completionsTableName pc
      JOIN $_sessionsTableName ps ON pc.session_id = ps.id
      $whereClause
      ORDER BY pc.start_time DESC
      $limitClause
    ''', whereArgs);

    return maps;
  }
}