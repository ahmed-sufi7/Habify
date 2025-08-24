import '../database_helper.dart';
import '../../models/habit.dart';
import 'category_dao.dart';

class HabitDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _tableName = 'habits';

  // Create
  Future<int> insertHabit(Habit habit) async {
    final habitMap = habit.toMap();
    habitMap.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert(_tableName, habitMap);
  }

  Future<List<int>> insertHabits(List<Habit> habits) async {
    final List<int> ids = [];
    await _dbHelper.transaction((txn) async {
      for (final habit in habits) {
        final habitMap = habit.toMap();
        habitMap.remove('id');
        final id = await txn.insert(_tableName, habitMap);
        ids.add(id);
      }
    });
    return ids;
  }

  // Read
  Future<List<Habit>> getAllHabits() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getActiveHabits() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getInactiveHabits() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_active = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<Habit?> getHabitById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Habit>> getHabitsByCategory(int categoryId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getActiveHabitsByCategory(int categoryId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'category_id = ? AND is_active = ?',
      whereArgs: [categoryId, 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getHabitsByPriority(String priority) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'priority = ? AND is_active = ?',
      whereArgs: [priority, 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getTodayHabits() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_active = ? AND start_date <= ? AND (end_date IS NULL OR end_date >= ?)',
      whereArgs: [1, today.toIso8601String(), today.toIso8601String()],
      orderBy: 'notification_time ASC',
    );
    
    final habits = maps.map((map) => Habit.fromMap(map)).toList();
    
    // Filter based on repetition pattern
    return habits.where((habit) => habit.shouldShowToday()).toList();
  }

  Future<List<Map<String, dynamic>>> getHabitsWithCategories() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.rawQuery('''
      SELECT 
        h.*,
        c.name as category_name,
        c.color_hex as category_color,
        c.icon_name as category_icon
      FROM $_tableName h
      LEFT JOIN categories c ON h.category_id = c.id
      WHERE h.is_active = 1
      ORDER BY h.name ASC
    ''');
    return maps;
  }

  // Update
  Future<int> updateHabit(Habit habit) async {
    if (habit.id == null) {
      throw ArgumentError('Habit ID cannot be null for update');
    }

    final habitMap = habit.toMap();
    habitMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await _dbHelper.update(
      _tableName,
      habitMap,
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> updateHabitStatus(int id, bool isActive) async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateHabitName(int id, String newName) async {
    return await _dbHelper.update(
      _tableName,
      {
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateHabitDescription(int id, String newDescription) async {
    return await _dbHelper.update(
      _tableName,
      {
        'description': newDescription,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateHabitCategory(int id, int newCategoryId) async {
    return await _dbHelper.update(
      _tableName,
      {
        'category_id': newCategoryId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateHabitNotificationTime(int id, String notificationTime) async {
    return await _dbHelper.update(
      _tableName,
      {
        'notification_time': notificationTime,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateHabitRepetition(int id, String repetitionPattern, List<int> customDays) async {
    return await _dbHelper.update(
      _tableName,
      {
        'repetition_pattern': repetitionPattern,
        'custom_days': customDays.join(','),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteHabit(int id) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHabitsByCategory(int categoryId) async {
    return await _dbHelper.delete(
      _tableName,
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<int> deleteInactiveHabits() async {
    return await _dbHelper.delete(
      _tableName,
      where: 'is_active = ?',
      whereArgs: [0],
    );
  }

  // Utility methods
  Future<bool> habitExists(String name) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<bool> habitExistsById(int id) async {
    final habit = await getHabitById(id);
    return habit != null;
  }

  Future<int> getHabitCount() async {
    final result = await _dbHelper.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return result.first['count'] as int;
  }

  Future<int> getActiveHabitCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE is_active = ?',
      [1],
    );
    return result.first['count'] as int;
  }

  Future<int> getTodayHabitCount() async {
    final todayHabits = await getTodayHabits();
    return todayHabits.length;
  }

  // Search and filter
  Future<List<Habit>> searchHabits(String query) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: '(name LIKE ? OR description LIKE ?) AND is_active = ?',
      whereArgs: ['%$query%', '%$query%', 1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getHabitsByDateRange(DateTime startDate, DateTime endDate) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'start_date >= ? AND start_date <= ? AND is_active = ?',
      whereArgs: [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
        1,
      ],
      orderBy: 'start_date ASC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getExpiredHabits() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'end_date IS NOT NULL AND end_date < ? AND is_active = ?',
      whereArgs: [today.toIso8601String(), 1],
      orderBy: 'end_date DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<List<Habit>> getUpcomingHabits() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'start_date > ? AND is_active = ?',
      whereArgs: [today.toIso8601String(), 1],
      orderBy: 'start_date ASC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  // Statistics and analytics
  Future<Map<String, dynamic>> getHabitStats() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        COUNT(*) as total_habits,
        SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active_habits,
        SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) as inactive_habits,
        COUNT(DISTINCT category_id) as categories_used
      FROM $_tableName
    ''');

    final row = result.first;
    return {
      'total_habits': row['total_habits'] as int,
      'active_habits': row['active_habits'] as int,
      'inactive_habits': row['inactive_habits'] as int,
      'categories_used': row['categories_used'] as int,
    };
  }

  Future<Map<String, dynamic>> getHabitsByPriorityStats() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        priority,
        COUNT(*) as count
      FROM $_tableName
      WHERE is_active = 1
      GROUP BY priority
      ORDER BY 
        CASE priority
          WHEN 'Do First' THEN 1
          WHEN 'Schedule' THEN 2
          WHEN 'Delegate' THEN 3
          WHEN 'Eliminate' THEN 4
          ELSE 5
        END
    ''');

    return {
      'priority_distribution': result,
      'total_active_habits': result.fold<int>(0, (sum, row) => sum + (row['count'] as int)),
    };
  }

  Future<Map<String, dynamic>> getHabitsByCategoryStats() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        c.name as category_name,
        c.color_hex as category_color,
        COUNT(h.id) as habit_count
      FROM categories c
      LEFT JOIN $_tableName h ON c.id = h.category_id AND h.is_active = 1
      GROUP BY c.id, c.name, c.color_hex
      HAVING habit_count > 0
      ORDER BY habit_count DESC
    ''');

    return {
      'category_distribution': result,
      'categories_with_habits': result.length,
    };
  }

  // Bulk operations
  Future<int> deactivateAllHabits() async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> activateAllHabits() async {
    return await _dbHelper.update(
      _tableName,
      {
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<int> moveHabitsToCategory(List<int> habitIds, int newCategoryId) async {
    if (habitIds.isEmpty) return 0;
    
    final placeholders = List.filled(habitIds.length, '?').join(',');
    return await _dbHelper.rawUpdate(
      'UPDATE $_tableName SET category_id = ?, updated_at = ? WHERE id IN ($placeholders)',
      [newCategoryId, DateTime.now().toIso8601String(), ...habitIds],
    );
  }

  // Validation
  Future<bool> canUpdateHabit(int id, Map<String, dynamic> updates) async {
    final habit = await getHabitById(id);
    if (habit == null) return false;
    
    // Add any business logic validation here
    // For example, check if new category exists
    if (updates.containsKey('category_id')) {
      final categoryDao = CategoryDao();
      final categoryExists = await categoryDao.categoryExistsById(updates['category_id']);
      if (!categoryExists) return false;
    }
    
    return true;
  }

  Future<List<String>> validateHabit(Habit habit) async {
    final errors = <String>[];
    
    if (habit.name.trim().isEmpty) {
      errors.add('Habit name cannot be empty');
    }
    
    if (habit.durationMinutes <= 0) {
      errors.add('Duration must be greater than 0');
    }
    
    if (habit.startDate.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      errors.add('Start date cannot be more than a year in the future');
    }
    
    if (habit.endDate != null && habit.endDate!.isBefore(habit.startDate)) {
      errors.add('End date cannot be before start date');
    }
    
    // Check if category exists
    final categoryDao = CategoryDao();
    final categoryExists = await categoryDao.categoryExistsById(habit.categoryId);
    if (!categoryExists) {
      errors.add('Selected category does not exist');
    }
    
    return errors;
  }
}
