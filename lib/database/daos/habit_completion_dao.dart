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
      final completion = HabitCompletion.forDate(
        habitId: habitId,
        date: date,
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
    // First, get the habit to understand its schedule
    final habitResult = await _dbHelper.rawQuery('''
      SELECT start_date, repetition_pattern, custom_days, notification_time
      FROM habits 
      WHERE id = ?
    ''', [habitId]);
    
    if (habitResult.isEmpty) return 0;
    
    final habitData = habitResult.first;
    final startDate = DateTime.parse(habitData['start_date'] as String);
    final repetitionPattern = habitData['repetition_pattern'] as String;
    final customDaysStr = habitData['custom_days'] as String?;
    final customDays = customDaysStr?.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e != 0).toList() ?? <int>[];
    
    // Get all completion records for this habit
    final List<Map<String, dynamic>> completions = await _dbHelper.rawQuery('''
      SELECT completion_date, status
      FROM $_tableName
      WHERE habit_id = ? AND completion_date <= ?
      ORDER BY completion_date DESC
    ''', [habitId, asOfDate.toIso8601String().split('T')[0]]);
    
    // Create a map for quick lookup of completion status by date
    final Map<String, String> completionMap = {};
    for (final completion in completions) {
      completionMap[completion['completion_date'] as String] = completion['status'] as String;
    }
    
    // Check each day backwards from asOfDate to find current streak
    int streak = 0;
    final today = DateTime(asOfDate.year, asOfDate.month, asOfDate.day);
    final now = DateTime.now();
    
    for (int i = 0; i <= 365; i++) { // Check up to 365 days back to avoid infinite loops
      final checkDate = today.subtract(Duration(days: i));
      final checkDateStr = checkDate.toIso8601String().split('T')[0];
      
      // Skip if before habit start date
      if (checkDate.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
        break;
      }
      
      // Check if habit should be active on this date
      if (!_shouldHabitBeActiveOnDate(checkDate, repetitionPattern, customDays)) {
        continue; // Skip days when habit isn't scheduled
      }
      
      // Check completion status
      final status = completionMap[checkDateStr];
      
      if (status == 'completed') {
        streak++;
      } else if (status == 'missed') {
        // Explicitly marked as missed - streak is broken
        break;
      } else {
        // No record exists for a day the habit should have been done
        // Check if this is within the 24-hour grace period
        final isToday = checkDate.isAtSameMomentAs(today);
        final isFutureDate = checkDate.isAfter(today);
        
        if (isFutureDate) {
          // Future dates don't count - skip them
          continue;
        } else if (isToday) {
          // For today, check if 24 hours have passed since the habit's scheduled time
          final habitTimeParts = (habitResult.first['notification_time'] as String? ?? '00:00').split(':');
          final habitHour = int.tryParse(habitTimeParts[0]) ?? 0;
          final habitMinute = int.tryParse(habitTimeParts[1]) ?? 0;
          
          final habitScheduledTime = DateTime(
            checkDate.year, 
            checkDate.month, 
            checkDate.day, 
            habitHour, 
            habitMinute
          );
          
          final twentyFourHoursLater = habitScheduledTime.add(const Duration(hours: 24));
          
          if (now.isBefore(twentyFourHoursLater)) {
            // Still within 24-hour grace period - don't break streak
            continue;
          } else {
            // 24 hours have passed without completion - streak is broken
            break;
          }
        } else {
          // Past date with no completion record - streak is broken
          break;
        }
      }
    }
    
    return streak;
  }
  
  // Helper method to check if habit should be active on a given date
  bool _shouldHabitBeActiveOnDate(DateTime date, String repetitionPattern, List<int> customDays) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    
    switch (repetitionPattern) {
      case 'Everyday':
        return true;
      case 'Weekdays':
        return weekday >= 1 && weekday <= 5;
      case 'Weekends':
        return weekday == 6 || weekday == 7;
      case 'Monday':
        return weekday == 1;
      case 'Tuesday':
        return weekday == 2;
      case 'Wednesday':
        return weekday == 3;
      case 'Thursday':
        return weekday == 4;
      case 'Friday':
        return weekday == 5;
      case 'Saturday':
        return weekday == 6;
      case 'Sunday':
        return weekday == 7;
      case 'Custom':
        return customDays.contains(weekday);
      default:
        return false;
    }
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

  // Calculate actual completed and missed counts based on habit schedule
  Future<Map<String, int>> getActualHabitCounts(int habitId) async {
    // Get habit details
    final habitResult = await _dbHelper.rawQuery('''
      SELECT start_date, repetition_pattern, custom_days, notification_time
      FROM habits 
      WHERE id = ?
    ''', [habitId]);
    
    if (habitResult.isEmpty) return {'completed': 0, 'missed': 0, 'scheduled': 0};
    
    final habitData = habitResult.first;
    final startDate = DateTime.parse(habitData['start_date'] as String);
    final repetitionPattern = habitData['repetition_pattern'] as String;
    final customDaysStr = habitData['custom_days'] as String?;
    final customDays = customDaysStr?.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e != 0).toList() ?? <int>[];
    
    // Get all completion records
    final completions = await _dbHelper.rawQuery('''
      SELECT completion_date, status
      FROM $_tableName
      WHERE habit_id = ?
      ORDER BY completion_date ASC
    ''', [habitId]);
    
    final Map<String, String> completionMap = {};
    for (final completion in completions) {
      completionMap[completion['completion_date'] as String] = completion['status'] as String;
    }
    
    // Count scheduled days, completed days, and missed days
    int scheduledDays = 0;
    int completedDays = 0;
    int missedDays = 0;
    
    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month, today.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    
    for (DateTime date = startDay; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
      // Check if habit should be active on this date
      if (_shouldHabitBeActiveOnDate(date, repetitionPattern, customDays)) {
        scheduledDays++;
        final dateStr = date.toIso8601String().split('T')[0];
        final status = completionMap[dateStr];
        
        if (status == 'completed') {
          completedDays++;
        } else if (status == 'missed') {
          missedDays++;
        } else {
          // No record exists but habit was scheduled - consider it missed if past due
          final isToday = date.isAtSameMomentAs(endDate);
          if (!isToday) {
            missedDays++;
          }
          // For today, don't count as missed yet (24-hour grace period)
        }
      }
    }
    
    return {
      'completed': completedDays,
      'missed': missedDays, 
      'scheduled': scheduledDays,
    };
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
    // Get actual counts based on habit schedule
    final actualCounts = await getActualHabitCounts(habitId);
    final completedCount = actualCounts['completed'] ?? 0;
    final missedCount = actualCounts['missed'] ?? 0;
    final scheduledCount = actualCounts['scheduled'] ?? 0;
    
    // Get database record counts for additional info
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_entries,
        SUM(CASE WHEN status = 'skipped' THEN 1 ELSE 0 END) as skipped_count
      FROM $_tableName
      WHERE habit_id = ?
    ''', [habitId]);

    final row = result.first;
    final totalEntries = row['total_entries'] as int;
    final skippedCount = row['skipped_count'] as int;

    return {
      'total_entries': totalEntries,
      'completed_count': completedCount,
      'missed_count': missedCount,
      'skipped_count': skippedCount,
      'scheduled_count': scheduledCount,
      'completion_rate': scheduledCount > 0 ? (completedCount / scheduledCount * 100) : 0.0,
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