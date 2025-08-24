// Central database manager for easy access to all database operations
import 'database_helper.dart';

// DAOs
import 'daos/category_dao.dart';
import 'daos/habit_dao.dart';
import 'daos/habit_completion_dao.dart';
import 'daos/pomodoro_dao.dart';
import 'daos/notification_dao.dart';

// Services
import '../services/database/habit_service.dart';
import '../services/database/pomodoro_service.dart';
import '../services/database/notification_service.dart';


/// DatabaseManager provides a centralized access point to all database operations
/// for the Habify app. This class follows the singleton pattern and ensures
/// proper initialization and cleanup of database resources.
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  // Core database helper
  late final DatabaseHelper _dbHelper;
  
  // DAOs
  late final CategoryDao _categoryDao;
  late final HabitDao _habitDao;
  late final HabitCompletionDao _habitCompletionDao;
  late final PomodoroDao _pomodoroDao;
  late final NotificationDao _notificationDao;
  
  // Services
  late final HabitService _habitService;
  late final PomodoroService _pomodoroService;
  late final NotificationService _notificationService;

  bool _initialized = false;

  /// Initialize the database manager and all its components
  Future<void> initialize() async {
    if (_initialized) return;

    _dbHelper = DatabaseHelper();
    
    // Initialize DAOs
    _categoryDao = CategoryDao();
    _habitDao = HabitDao();
    _habitCompletionDao = HabitCompletionDao();
    _pomodoroDao = PomodoroDao();
    _notificationDao = NotificationDao();
    
    // Initialize Services
    _habitService = HabitService();
    _pomodoroService = PomodoroService();
    _notificationService = NotificationService();

    // Ensure database is created
    await _dbHelper.database;
    
    _initialized = true;
  }

  /// Ensure the database manager is initialized before use
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DatabaseManager not initialized. Call initialize() first.');
    }
  }

  // Getters for services (most commonly used)
  HabitService get habitService {
    _ensureInitialized();
    return _habitService;
  }

  PomodoroService get pomodoroService {
    _ensureInitialized();
    return _pomodoroService;
  }

  NotificationService get notificationService {
    _ensureInitialized();
    return _notificationService;
  }

  // Getters for DAOs (for advanced operations)
  CategoryDao get categoryDao {
    _ensureInitialized();
    return _categoryDao;
  }

  HabitDao get habitDao {
    _ensureInitialized();
    return _habitDao;
  }

  HabitCompletionDao get habitCompletionDao {
    _ensureInitialized();
    return _habitCompletionDao;
  }

  PomodoroDao get pomodoroDao {
    _ensureInitialized();
    return _pomodoroDao;
  }

  NotificationDao get notificationDao {
    _ensureInitialized();
    return _notificationDao;
  }

  // Getter for database helper (for low-level operations)
  DatabaseHelper get dbHelper {
    _ensureInitialized();
    return _dbHelper;
  }

  /// Get comprehensive dashboard data combining all services
  Future<Map<String, dynamic>> getDashboardData() async {
    _ensureInitialized();
    
    final habitDashboard = await _habitService.getDashboardData();
    final pomodoroDashboard = await _pomodoroService.getPomodorosDashboardData();
    final notificationSummary = await _notificationService.getNotificationSummary();
    
    return {
      'habits': habitDashboard,
      'pomodoro': pomodoroDashboard,
      'notifications': notificationSummary,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Perform comprehensive data cleanup
  Future<void> performMaintenance({
    int habitDataDaysToKeep = 365,
    int pomodoroDataDaysToKeep = 90,
    int notificationDaysToKeep = 30,
  }) async {
    _ensureInitialized();
    
    await Future.wait([
      _habitService.cleanupOldData(daysToKeep: habitDataDaysToKeep),
      _pomodoroService.cleanupOldData(daysToKeep: pomodoroDataDaysToKeep),
      _notificationService.cleanupOldNotifications(daysToKeep: notificationDaysToKeep),
    ]);
  }

  /// Get comprehensive app statistics
  Future<Map<String, dynamic>> getAppStatistics() async {
    _ensureInitialized();
    
    final habitStats = await _habitService.getOverallHabitStats();
    final pomodoroStats = await _pomodoroService.getOverallPomodoroStats();
    final notificationStats = await _notificationService.getNotificationStats();
    
    // Database info
    final dbInfo = {
      'version': await _dbHelper.getDatabaseVersion(),
      'path': await _dbHelper.getDatabasePath(),
      'tables': await _dbHelper.getTableNames(),
    };

    // Table row counts
    final Map<String, int> tableCounts = {};
    for (final table in dbInfo['tables'] as List<String>) {
      tableCounts[table] = await _dbHelper.getTableRowCount(table);
    }

    return {
      'habits': habitStats,
      'pomodoro': pomodoroStats,
      'notifications': notificationStats,
      'database': dbInfo,
      'table_counts': tableCounts,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Export all user data
  Future<Map<String, dynamic>> exportAllData() async {
    _ensureInitialized();
    
    // Get all data
    final categories = await _categoryDao.getAllCategories();
    final habits = await _habitDao.getAllHabits();
    final completions = await _habitCompletionDao.getAllCompletions();
    final pomodoroSessions = await _pomodoroDao.getAllSessions();
    final pomodoroCompletions = await _pomodoroDao.getAllCompletions();
    final notifications = await _notificationDao.getAllNotifications();

    return {
      'export_info': {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'app_name': 'Habify',
      },
      'categories': categories.map((c) => c.toMap()).toList(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'habit_completions': completions.map((c) => c.toMap()).toList(),
      'pomodoro_sessions': pomodoroSessions.map((s) => s.toMap()).toList(),
      'pomodoro_completions': pomodoroCompletions.map((c) => c.toMap()).toList(),
      'notifications': notifications.map((n) => n.toMap()).toList(),
      'statistics': await getAppStatistics(),
    };
  }

  /// Reset all data to initial state
  Future<void> resetAllData() async {
    _ensureInitialized();
    await _dbHelper.resetDatabase();
  }

  /// Close database connection
  Future<void> close() async {
    if (_initialized) {
      await _dbHelper.closeDatabase();
      _initialized = false;
    }
  }

  /// Delete database file completely
  Future<void> deleteDatabase() async {
    await _dbHelper.deleteDatabase();
    _initialized = false;
  }

  /// Check database health and integrity
  Future<Map<String, dynamic>> checkDatabaseHealth() async {
    _ensureInitialized();
    
    final issues = <String>[];
    final warnings = <String>[];
    
    try {
      // Check if all tables exist
      final tableNames = await _dbHelper.getTableNames();
      final expectedTables = ['categories', 'habits', 'habit_completions', 'pomodoro_sessions', 'pomodoro_completions', 'notifications'];
      
      for (final table in expectedTables) {
        if (!tableNames.contains(table)) {
          issues.add('Missing table: $table');
        }
      }

      // Check for orphaned records
      final orphanedHabits = await _dbHelper.rawQuery('''
        SELECT COUNT(*) as count FROM habits h 
        LEFT JOIN categories c ON h.category_id = c.id 
        WHERE c.id IS NULL AND h.is_active = 1
      ''');
      
      final orphanedCount = orphanedHabits.first['count'] as int;
      if (orphanedCount > 0) {
        warnings.add('$orphanedCount habits have invalid category references');
      }

      // Check for default categories
      final defaultCategoryCount = await _categoryDao.getDefaultCategoryCount();
      if (defaultCategoryCount == 0) {
        warnings.add('No default categories found');
      }

      return {
        'healthy': issues.isEmpty,
        'issues': issues,
        'warnings': warnings,
        'table_counts': {
          for (final table in tableNames)
            table: await _dbHelper.getTableRowCount(table)
        },
        'checked_at': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      issues.add('Database health check failed: $e');
      return {
        'healthy': false,
        'issues': issues,
        'warnings': warnings,
        'error': e.toString(),
        'checked_at': DateTime.now().toIso8601String(),
      };
    }
  }
}