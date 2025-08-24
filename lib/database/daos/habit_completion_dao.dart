import '../database_helper.dart';
import '../../models/habit_completion.dart';

class HabitCompletionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _tableName = 'habit_completions';

  // Create
  Future<int> insertCompletion(HabitCompletion completion) async {
    final completionMap = completion.toMap();
    completionMap.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert(_tableName, completionMap);
  }

  Future<List<int>> insertCompletions(List<HabitCompletion> completions) async {
    final List<int> ids = [];
    await _dbHelper.transaction((txn) async {
      for (final completion in completions) {
        final completionMap = completion.toMap();
        completionMap.remove('id');
        final id = await txn.insert(_tableName, completionMap);
        ids.add(id);
      }
    });
    return ids;
  }

  // Read
  Future<List<HabitCompletion>> getAllCompletions() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      orderBy: 'completion_date DESC, created_at DESC',
    );
    return maps.map((map) => HabitCompletion.fromMap(map)).toList();
  }

  Future<HabitCompletion?> getCompletionById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return HabitCompletion.fromMap(maps.first);
    }
    return null;
  }

  Future<List<HabitCompletion>> getCompletionsByHabit(int habitId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'completion_date DESC',
    );
    return maps.map((map) => HabitCompletion.fromMap(map)).toList();
  }

  Future<HabitCompletion?> getCompletionByHabitAndDate(int habitId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'habit_id = ? AND completion_date = ?',
      whereArgs: [habitId, dateStr],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return HabitCompletion.fromMap(maps.first);
    }
    return null;
  }

  Future<List<HabitCompletion>> getCompletionsByDateRange(
    int habitId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'habit_id = ? AND completion_date >= ? AND completion_date <= ?',
      whereArgs: [habitId, startDateStr, endDateStr],
      orderBy: 'completion_date ASC',
    );
    return maps.map((map) => HabitCompletion.fromMap(map)).toList();
  }

  Future<List<HabitCompletion>> getTodayCompletions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = today.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'completion_date = ?',
      whereArgs: [todayStr],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => HabitCompletion.fromMap(map)).toList();
  }

  Future<List<HabitCompletion>> getCompletedHabitsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'completion_date = ? AND status = ?',
      whereArgs: [dateStr, 'completed'],
      orderBy: 'completed_at ASC',
    );
    return maps.map((map) => HabitCompletion.fromMap(map)).toList();
  }

  Future<List<HabitCompletion>> getMissedHabitsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'completion_date = ? AND status = ?',
      whereArgs: [dateStr, 'missed'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => HabitCompletion.fromMap(map)).toList();
  }

  // Update
  Future<int> updateCompletion(HabitCompletion completion) async {
    if (completion.id == null) {
      throw ArgumentError('Completion ID cannot be null for update');
    }

    final completionMap = completion.toMap();
    completionMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await _dbHelper.update(
      _tableName,
      completionMap,
      where: 'id = ?',
      whereArgs: [completion.id],
    );
  }

  Future<int> markHabitCompleted(int habitId, DateTime date, {String? notes}) async {
    final now = DateTime.now();
    
    // Check if completion already exists
    final existing = await getCompletionByHabitAndDate(habitId, date);
    if (existing != null) {
      // Update existing completion
      return await _dbHelper.update(
        _tableName,
        {
          'completed_at': now.toIso8601String(),
          'status': 'completed',
          'notes': notes,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Create new completion
      final streakCount = await calculateCurrentStreak(habitId, date);
      final completion = HabitCompletion.forToday(
        habitId: habitId,
        status: 'completed',
        notes: notes,
        streakCount: streakCount,
      );
      return await insertCompletion(completion);
    }
  }

  Future<int> markHabitMissed(int habitId, DateTime date, {String? notes}) async {
    final now = DateTime.now();
    
    // Check if completion already exists
    final existing = await getCompletionByHabitAndDate(habitId, date);
    if (existing != null) {
      // Update existing completion
      return await _dbHelper.update(
        _tableName,
        {
          'completed_at': null,
          'status': 'missed',
          'streak_count': 0,
          'notes': notes,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Create new missed completion
      final completion = HabitCompletion.missed(
        habitId: habitId,
        date: date,
        notes: notes,
      );
      return await insertCompletion(completion);
    }
  }

  Future<int> updateCompletionStatus(int id, String status) async {
    final now = DateTime.now();
    final updates = {
      'status': status,
      'updated_at': now.toIso8601String(),
    };
    
    if (status == 'completed') {
      updates['completed_at'] = now.toIso8601String();
    } else {
      updates['completed_at'] = '';
      updates['streak_count'] = '0';
    }
    
    return await _dbHelper.update(
      _tableName,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCompletionNotes(int id, String? notes) async {
    return await _dbHelper.update(
      _tableName,
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
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCompletionsByHabit(int habitId) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
  }

  Future<int> deleteCompletionsOlderThan(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await _dbHelper.delete(
      _tableName,
      where: 'completion_date < ?',
      whereArgs: [dateStr],
    );
  }

  // Utility methods
  Future<bool> isHabitCompletedForDate(int habitId, DateTime date) async {
    final completion = await getCompletionByHabitAndDate(habitId, date);
    return completion?.isCompleted ?? false;
  }

  Future<bool> isHabitMissedForDate(int habitId, DateTime date) async {
    final completion = await getCompletionByHabitAndDate(habitId, date);
    return completion?.isMissed ?? false;
  }

  Future<int> getCompletionCount() async {
    final result = await _dbHelper.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return result.first['count'] as int;
  }

  Future<int> getCompletedCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE status = ?',
      ['completed'],
    );
    return result.first['count'] as int;
  }

  Future<int> getMissedCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE status = ?',
      ['missed'],
    );
    return result.first['count'] as int;
  }

  // Streak calculations
  Future<int> calculateCurrentStreak(int habitId, DateTime asOfDate) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT completion_date, status
      FROM $_tableName
      WHERE habit_id = ? AND completion_date <= ?
      ORDER BY completion_date DESC
    ''', [habitId, asOfDate.toIso8601String().split('T')[0]]);

    int streak = 0;
    for (final map in maps) {
      if (map['status'] == 'completed') {
        streak++;
      } else if (map['status'] == 'missed') {
        break; // Streak broken
      }
      // Skip 'skipped' entries - they don't break the streak
    }

    return streak;
  }

  Future<int> getLongestStreak(int habitId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT completion_date, status
      FROM $_tableName
      WHERE habit_id = ?
      ORDER BY completion_date ASC
    ''', [habitId]);

    int maxStreak = 0;
    int currentStreak = 0;

    for (final map in maps) {
      if (map['status'] == 'completed') {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else if (map['status'] == 'missed') {
        currentStreak = 0;
      }
      // Skip 'skipped' entries - they don't reset the streak
    }

    return maxStreak;
  }

  Future<Map<int, int>> getCurrentStreaksForAllHabits() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT DISTINCT habit_id FROM $_tableName
    ''');

    final Map<int, int> streaks = {};
    for (final map in maps) {
      final habitId = map['habit_id'] as int;
      streaks[habitId] = await calculateCurrentStreak(habitId, today);
    }

    return streaks;
  }

  // Statistics and analytics
  Future<Map<String, dynamic>> getHabitCompletionStats(int habitId) async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_count,
        SUM(CASE WHEN status = 'missed' THEN 1 ELSE 0 END) as missed_count,
        SUM(CASE WHEN status = 'skipped' THEN 1 ELSE 0 END) as skipped_count
      FROM $_tableName
      WHERE habit_id = ?
    ''', [habitId]);

    final row = result.first;
    final totalEntries = row['total_entries'] as int;
    final completedCount = row['completed_count'] as int;
    final missedCount = row['missed_count'] as int;
    final skippedCount = row['skipped_count'] as int;

    return {
      'total_entries': totalEntries,
      'completed_count': completedCount,
      'missed_count': missedCount,
      'skipped_count': skippedCount,
      'completion_rate': totalEntries > 0 ? (completedCount / totalEntries * 100) : 0.0,
      'current_streak': await calculateCurrentStreak(habitId, DateTime.now()),
      'longest_streak': await getLongestStreak(habitId),
    };
  }

  Future<Map<String, dynamic>> getOverallStats() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_count,
        SUM(CASE WHEN status = 'missed' THEN 1 ELSE 0 END) as missed_count,
        SUM(CASE WHEN status = 'skipped' THEN 1 ELSE 0 END) as skipped_count,
        COUNT(DISTINCT habit_id) as habits_tracked
      FROM $_tableName
    ''');

    final row = result.first;
    final totalEntries = row['total_entries'] as int;
    final completedCount = row['completed_count'] as int;

    return {
      'total_entries': totalEntries,
      'completed_count': completedCount,
      'missed_count': row['missed_count'] as int,
      'skipped_count': row['skipped_count'] as int,
      'habits_tracked': row['habits_tracked'] as int,
      'overall_completion_rate': totalEntries > 0 ? (completedCount / totalEntries * 100) : 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getCompletionCalendar(
    int habitId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT completion_date, status, streak_count, notes
      FROM $_tableName
      WHERE habit_id = ? AND completion_date >= ? AND completion_date <= ?
      ORDER BY completion_date ASC
    ''', [habitId, startDateStr, endDateStr]);

    return maps;
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats(int habitId, int weeksBack) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeksBack * 7));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        strftime('%Y-%W', completion_date) as week,
        COUNT(*) as total_days,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_days
      FROM $_tableName
      WHERE habit_id = ? AND completion_date >= ?
      GROUP BY strftime('%Y-%W', completion_date)
      ORDER BY week DESC
    ''', [habitId, startDateStr]);

    return maps;
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats(int habitId, int monthsBack) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - monthsBack, 1);
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        strftime('%Y-%m', completion_date) as month,
        COUNT(*) as total_days,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_days
      FROM $_tableName
      WHERE habit_id = ? AND completion_date >= ?
      GROUP BY strftime('%Y-%m', completion_date)
      ORDER BY month DESC
    ''', [habitId, startDateStr]);

    return maps;
  }

  // Bulk operations
  Future<void> recalculateAllStreaks() async {
    await _dbHelper.transaction((txn) async {
      // Get all habit IDs
      final habitIds = await txn.rawQuery('SELECT DISTINCT habit_id FROM $_tableName');
      
      for (final row in habitIds) {
        final habitId = row['habit_id'] as int;
        
        // Get all completions for this habit
        final completions = await txn.rawQuery('''
          SELECT id, completion_date, status
          FROM $_tableName
          WHERE habit_id = ?
          ORDER BY completion_date ASC
        ''', [habitId]);

        // Recalculate streaks
        int currentStreak = 0;
        for (final completion in completions) {
          if (completion['status'] == 'completed') {
            currentStreak++;
          } else if (completion['status'] == 'missed') {
            currentStreak = 0;
          }
          
          // Update the streak count
          await txn.update(
            _tableName,
            {'streak_count': currentStreak},
            where: 'id = ?',
            whereArgs: [completion['id']],
          );
        }
      }
    });
  }
}