import '../../database/daos/habit_dao.dart';
import '../../database/daos/category_dao.dart';
import '../../database/daos/habit_completion_dao.dart';
import '../../models/habit.dart';
import '../../models/category.dart';

class HabitService {
  final HabitDao _habitDao = HabitDao();
  final CategoryDao _categoryDao = CategoryDao();
  final HabitCompletionDao _completionDao = HabitCompletionDao();

  // Habit management
  Future<int> createHabit({
    required String name,
    required String description,
    required int categoryId,
    required String priority,
    required int durationMinutes,
    required String notificationTime,
    String? alarmTime,
    required String repetitionPattern,
    List<int> customDays = const [],
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    // Validate category exists
    final category = await _categoryDao.getCategoryById(categoryId);
    if (category == null) {
      throw ArgumentError('Category does not exist');
    }

    final now = DateTime.now();
    final habit = Habit(
      name: name,
      description: description,
      categoryId: categoryId,
      priority: priority,
      durationMinutes: durationMinutes,
      notificationTime: notificationTime,
      alarmTime: alarmTime,
      repetitionPattern: repetitionPattern,
      customDays: customDays,
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
      updatedAt: now,
    );

    // Validate habit data
    final validationErrors = await _habitDao.validateHabit(habit);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Validation failed: ${validationErrors.join(', ')}');
    }

    final habitId = await _habitDao.insertHabit(habit);

    // Schedule habit reminders
    await _scheduleHabitReminders(habitId, name, notificationTime, alarmTime, repetitionPattern, customDays, startDate, endDate);

    return habitId;
  }

  Future<void> updateHabit(Habit habit) async {
    if (habit.id == null) {
      throw ArgumentError('Habit ID cannot be null for update');
    }

    // Validate habit data
    final validationErrors = await _habitDao.validateHabit(habit);
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Validation failed: ${validationErrors.join(', ')}');
    }

    await _habitDao.updateHabit(habit);

    // Update habit reminders
    await _scheduleHabitReminders(
      habit.id!,
      habit.name,
      habit.notificationTime,
      habit.alarmTime,
      habit.repetitionPattern,
      habit.customDays,
      habit.startDate,
      habit.endDate,
    );
  }

  Future<void> deleteHabit(int habitId) async {
    // Delete associated data
    await _completionDao.deleteCompletionsByHabit(habitId);
    await _habitDao.deleteHabit(habitId);
  }

  Future<void> deactivateHabit(int habitId) async {
    await _habitDao.updateHabitStatus(habitId, false);
  }

  Future<void> reactivateHabit(int habitId) async {
    final habit = await _habitDao.getHabitById(habitId);
    if (habit == null) {
      throw ArgumentError('Habit not found');
    }

    await _habitDao.updateHabitStatus(habitId, true);
    
    // Reschedule notifications
    await _scheduleHabitReminders(
      habitId,
      habit.name,
      habit.notificationTime,
      habit.alarmTime,
      habit.repetitionPattern,
      habit.customDays,
      habit.startDate,
      habit.endDate,
    );
  }

  // Habit completion
  Future<void> completeHabit(int habitId, {DateTime? date, String? notes}) async {
    final completionDate = date ?? DateTime.now();
    
    // Check if habit exists and is active
    final habit = await _habitDao.getHabitById(habitId);
    if (habit == null || !habit.isActive) {
      throw ArgumentError('Habit not found or inactive');
    }

    // Check if habit should be shown today
    if (!habit.shouldShowToday()) {
      throw ArgumentError('Habit is not scheduled for today');
    }

    await _completionDao.markHabitCompleted(habitId, completionDate, notes: notes);

    // Note: Streak celebrations are now handled by the simple notification service
  }

  Future<void> markHabitMissed(int habitId, {DateTime? date, String? notes}) async {
    final completionDate = date ?? DateTime.now();
    await _completionDao.markHabitMissed(habitId, completionDate, notes: notes);
  }

  Future<void> undoHabitCompletion(int habitId, {DateTime? date}) async {
    final completionDate = date ?? DateTime.now();
    final completion = await _completionDao.getCompletionByHabitAndDate(habitId, completionDate);
    
    if (completion != null) {
      await _completionDao.deleteCompletion(completion.id!);
    }
  }

  // Check if habit was completed on a specific date
  Future<bool> isHabitCompletedOnDate(int habitId, DateTime date) async {
    return await _completionDao.isHabitCompletedForDate(habitId, date);
  }

  // Habit queries
  Future<List<Habit>> getTodayHabits() async {
    return await _habitDao.getTodayHabits();
  }

  Future<List<Map<String, dynamic>>> getTodayHabitsWithStatus() async {
    final habits = await getTodayHabits();
    final habitsWithStatus = <Map<String, dynamic>>[];
    
    for (final habit in habits) {
      final isCompleted = await _completionDao.isHabitCompletedForDate(habit.id!, DateTime.now());
      final currentStreak = await _completionDao.calculateCurrentStreak(habit.id!, DateTime.now());
      
      habitsWithStatus.add({
        'habit': habit,
        'is_completed': isCompleted,
        'current_streak': currentStreak,
      });
    }
    
    return habitsWithStatus;
  }

  Future<List<Habit>> getActiveHabits() async {
    return await _habitDao.getActiveHabits();
  }

  Future<Habit?> getHabitById(int id) async {
    return await _habitDao.getHabitById(id);
  }

  Future<List<Habit>> getHabitsByCategory(int categoryId) async {
    return await _habitDao.getActiveHabitsByCategory(categoryId);
  }

  Future<List<Habit>> searchHabits(String query) async {
    return await _habitDao.searchHabits(query);
  }

  // Habit statistics
  Future<Map<String, dynamic>> getHabitStats(int habitId) async {
    final habit = await _habitDao.getHabitById(habitId);
    if (habit == null) {
      throw ArgumentError('Habit not found');
    }

    final completionStats = await _completionDao.getHabitCompletionStats(habitId);
    final category = await _categoryDao.getCategoryById(habit.categoryId);
    
    return {
      'habit': habit,
      'category': category,
      'completion_stats': completionStats,
    };
  }

  Future<Map<String, dynamic>> getOverallHabitStats() async {
    final habitStats = await _habitDao.getHabitStats();
    final completionStats = await _completionDao.getOverallStats();
    final todayHabits = await getTodayHabits();
    
    // Calculate today's completion rate
    int todayCompleted = 0;
    for (final habit in todayHabits) {
      if (await _completionDao.isHabitCompletedForDate(habit.id!, DateTime.now())) {
        todayCompleted++;
      }
    }
    
    final todayCompletionRate = todayHabits.isNotEmpty ? (todayCompleted / todayHabits.length * 100) : 0.0;
    
    return {
      'habit_stats': habitStats,
      'completion_stats': completionStats,
      'today_habits_count': todayHabits.length,
      'today_completed_count': todayCompleted,
      'today_completion_rate': todayCompletionRate,
    };
  }

  Future<List<Map<String, dynamic>>> getHabitCompletionCalendar(int habitId, DateTime startDate, DateTime endDate) async {
    return await _completionDao.getCompletionCalendar(habitId, startDate, endDate);
  }

  Future<List<Map<String, dynamic>>> getWeeklyHabitStats(int habitId, int weeksBack) async {
    return await _completionDao.getWeeklyStats(habitId, weeksBack);
  }

  Future<List<Map<String, dynamic>>> getMonthlyHabitStats(int habitId, int monthsBack) async {
    return await _completionDao.getMonthlyStats(habitId, monthsBack);
  }

  // Category management
  Future<List<Category>> getAllCategories() async {
    return await _categoryDao.getAllCategories();
  }

  Future<int> createCustomCategory(String name, String colorHex, String iconName) async {
    if (await _categoryDao.categoryExists(name)) {
      throw ArgumentError('Category with this name already exists');
    }

    final now = DateTime.now();
    final category = Category(
      name: name,
      colorHex: colorHex,
      iconName: iconName,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
    );

    return await _categoryDao.insertCategory(category);
  }

  Future<void> deleteCustomCategory(int categoryId) async {
    final category = await _categoryDao.getCategoryById(categoryId);
    if (category == null) {
      throw ArgumentError('Category not found');
    }

    if (category.isDefault) {
      throw ArgumentError('Cannot delete default category');
    }

    // Check if category has habits
    if (!await _categoryDao.canDeleteCategory(categoryId)) {
      throw ArgumentError('Cannot delete category with existing habits');
    }

    await _categoryDao.deleteCategory(categoryId);
  }

  // Helper methods for scheduling notifications
  Future<void> _scheduleHabitReminders(
    int habitId,
    String habitName,
    String notificationTime,
    String? alarmTime,
    String repetitionPattern,
    List<int> customDays,
    DateTime startDate,
    DateTime? endDate,
  ) async {
    // Note: Notification management is now handled by NotificationService

    // Note: Notifications are now handled by the simple notification service in AddHabitScreen
  }


  // Data export/import
  Future<Map<String, dynamic>> exportHabitData(int habitId) async {
    final habit = await _habitDao.getHabitById(habitId);
    if (habit == null) {
      throw ArgumentError('Habit not found');
    }

    final category = await _categoryDao.getCategoryById(habit.categoryId);
    final completions = await _completionDao.getCompletionsByHabit(habitId);

    return {
      'habit': habit.toMap(),
      'category': category?.toMap(),
      'completions': completions.map((c) => c.toMap()).toList(),
    };
  }

  Future<void> cleanupOldData({int daysToKeep = 365}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    // Clean up old completions
    await _completionDao.deleteCompletionsOlderThan(cutoffDate);
    
    // Note: No notification cleanup needed with simple notification system
  }

  // Batch operations
  Future<void> moveHabitsToCategory(List<int> habitIds, int newCategoryId) async {
    // Validate category exists
    final category = await _categoryDao.getCategoryById(newCategoryId);
    if (category == null) {
      throw ArgumentError('Target category does not exist');
    }

    await _habitDao.moveHabitsToCategory(habitIds, newCategoryId);
  }

  Future<void> bulkUpdateHabitStatus(List<int> habitIds, bool isActive) async {
    for (final habitId in habitIds) {
      if (isActive) {
        await reactivateHabit(habitId);
      } else {
        await deactivateHabit(habitId);
      }
    }
  }

  // Dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    final todayHabitsWithStatus = await getTodayHabitsWithStatus();
    final overallStats = await getOverallHabitStats();
    final categories = await getAllCategories();
    final unreadNotificationCount = 0; // Simplified notification system doesn't track unread count

    // Get current streaks
    final streaks = await _completionDao.getCurrentStreaksForAllHabits();
    final maxStreak = streaks.values.isNotEmpty ? streaks.values.reduce((a, b) => a > b ? a : b) : 0;

    return {
      'today_habits': todayHabitsWithStatus,
      'overall_stats': overallStats,
      'categories': categories,
      'unread_notifications': unreadNotificationCount,
      'current_streaks': streaks,
      'max_current_streak': maxStreak,
    };
  }
}