import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/category.dart';

class DatabaseHelper {
  static const String _databaseName = 'habify.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: _onDowngrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < newVersion) {
      // Add migration logic as needed
      // For example, if adding new columns or tables
    }
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    // Handle downgrade if needed (usually drop and recreate)
    await _dropTables(db);
    await _createTables(db);
    await _insertDefaultData(db);
  }

  Future<void> _createTables(Database db) async {
    // Create categories table first (referenced by habits)
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color_hex TEXT NOT NULL DEFAULT '#2C2C2C',
        icon_name TEXT NOT NULL DEFAULT 'category',
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create habits table
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category_id INTEGER NOT NULL,
        priority TEXT NOT NULL DEFAULT 'Do First',
        duration_minutes INTEGER NOT NULL DEFAULT 10,
        notification_time TEXT NOT NULL DEFAULT '07:30',
        alarm_time TEXT,
        repetition_pattern TEXT NOT NULL DEFAULT 'Everyday',
        custom_days TEXT DEFAULT '',
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    // Create habit_completions table
    await db.execute('''
      CREATE TABLE habit_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        completion_date TEXT NOT NULL,
        completed_at TEXT,
        streak_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
        UNIQUE (habit_id, completion_date)
      )
    ''');

    // Create pomodoro_sessions table
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        work_duration_minutes INTEGER NOT NULL DEFAULT 25,
        short_break_minutes INTEGER NOT NULL DEFAULT 5,
        long_break_minutes INTEGER NOT NULL DEFAULT 15,
        sessions_count INTEGER NOT NULL DEFAULT 4,
        notification_enabled INTEGER NOT NULL DEFAULT 1,
        alarm_enabled INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create pomodoro_completions table
    await db.execute('''
      CREATE TABLE pomodoro_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        session_number INTEGER NOT NULL DEFAULT 1,
        session_type TEXT NOT NULL DEFAULT 'work',
        actual_duration_minutes INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES pomodoro_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Create notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        scheduled_time TEXT NOT NULL,
        is_sent INTEGER NOT NULL DEFAULT 0,
        is_read INTEGER NOT NULL DEFAULT 0,
        habit_id INTEGER,
        pomodoro_session_id INTEGER,
        data TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
        FOREIGN KEY (pomodoro_session_id) REFERENCES pomodoro_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Indexes for better query performance
    await db.execute('CREATE INDEX idx_habits_category_id ON habits (category_id)');
    await db.execute('CREATE INDEX idx_habits_is_active ON habits (is_active)');
    await db.execute('CREATE INDEX idx_habits_start_date ON habits (start_date)');
    await db.execute('CREATE INDEX idx_habit_completions_habit_id ON habit_completions (habit_id)');
    await db.execute('CREATE INDEX idx_habit_completions_completion_date ON habit_completions (completion_date)');
    await db.execute('CREATE INDEX idx_habit_completions_status ON habit_completions (status)');
    await db.execute('CREATE INDEX idx_pomodoro_completions_session_id ON pomodoro_completions (session_id)');
    await db.execute('CREATE INDEX idx_pomodoro_completions_start_time ON pomodoro_completions (start_time)');
    await db.execute('CREATE INDEX idx_notifications_scheduled_time ON notifications (scheduled_time)');
    await db.execute('CREATE INDEX idx_notifications_is_sent ON notifications (is_sent)');
    await db.execute('CREATE INDEX idx_notifications_is_read ON notifications (is_read)');
  }

  Future<void> _dropTables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS notifications');
    await db.execute('DROP TABLE IF EXISTS pomodoro_completions');
    await db.execute('DROP TABLE IF EXISTS pomodoro_sessions');
    await db.execute('DROP TABLE IF EXISTS habit_completions');
    await db.execute('DROP TABLE IF EXISTS habits');
    await db.execute('DROP TABLE IF EXISTS categories');
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default categories
    final defaultCategories = Category.getDefaultCategories();
    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // Database maintenance methods
  Future<void> resetDatabase() async {
    final db = await database;
    await _dropTables(db);
    await _createTables(db);
    await _insertDefaultData(db);
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  // Database info methods
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }

  Future<int> getDatabaseVersion() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA user_version');
    return result.isNotEmpty ? result.first['user_version'] as int : 0;
  }

  Future<List<String>> getTableNames() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  Future<int> getTableRowCount(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return result.first['count'] as int;
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Batch operations
  Future<List<dynamic>> batch(Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    return await batch.commit();
  }
}