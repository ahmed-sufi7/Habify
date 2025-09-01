import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/category.dart';
import '../models/habit_completion.dart';
import '../services/database/habit_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  
  // State variables
  List<Habit> _habits = [];
  List<Category> _categories = [];
  Map<int, bool> _todayCompletionStatus = {};
  Map<int, int> _currentStreaks = {};
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Habit> get habits => _habits;
  List<Category> get categories => _categories;
  Map<int, bool> get todayCompletionStatus => _todayCompletionStatus;
  Map<int, int> get currentStreaks => _currentStreaks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Computed properties
  List<Habit> get todayHabits => _habits.where((habit) => habit.shouldShowToday()).toList();
  int get todayCompletedCount => _todayCompletionStatus.values.where((completed) => completed).length;
  int get todayTotalCount => todayHabits.length;
  double get todayCompletionRate => todayTotalCount > 0 ? (todayCompletedCount / todayTotalCount) * 100 : 0.0;
  
  List<Habit> get activeHabits => _habits.where((habit) => habit.isActive).toList();
  List<Habit> get inactiveHabits => _habits.where((habit) => !habit.isActive).toList();
  
  // Initialize provider
  Future<void> initialize() async {
    await Future.wait([
      loadHabits(),
      loadCategories(),
      loadTodayStatus(),
    ]);
  }
  
  // Loading states management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  // Habit management
  Future<void> loadHabits() async {
    try {
      _setLoading(true);
      _clearError();
      _habits = await _habitService.getActiveHabits();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load habits: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<int?> createHabit({
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
    try {
      _setLoading(true);
      _clearError();
      
      final habitId = await _habitService.createHabit(
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
      );
      
      // Reload habits to update the UI
      await loadHabits();
      await loadTodayStatus();
      
      return habitId;
    } catch (e) {
      _setError('Failed to create habit: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> updateHabit(Habit habit) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _habitService.updateHabit(habit);
      
      // Update local state
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update habit: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> deleteHabit(int habitId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _habitService.deleteHabit(habitId);
      
      // Remove from local state
      _habits.removeWhere((habit) => habit.id == habitId);
      _todayCompletionStatus.remove(habitId);
      _currentStreaks.remove(habitId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete habit: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> deactivateHabit(int habitId) async {
    try {
      _clearError();
      await _habitService.deactivateHabit(habitId);
      
      // Update local state
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = _habits[index].copyWith(isActive: false);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to deactivate habit: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> reactivateHabit(int habitId) async {
    try {
      _clearError();
      await _habitService.reactivateHabit(habitId);
      
      // Update local state
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = _habits[index].copyWith(isActive: true);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to reactivate habit: ${e.toString()}');
      return false;
    }
  }
  
  // Habit completion
  Future<bool> completeHabit(int habitId, {DateTime? date, String? notes}) async {
    try {
      _clearError();
      await _habitService.completeHabit(habitId, date: date, notes: notes);
      
      // Update local completion status
      _todayCompletionStatus[habitId] = true;
      
      // Update streak
      await _updateHabitStreak(habitId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to complete habit: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> markHabitMissed(int habitId, {DateTime? date, String? notes}) async {
    try {
      _clearError();
      await _habitService.markHabitMissed(habitId, date: date, notes: notes);
      
      // Update local completion status
      _todayCompletionStatus[habitId] = false;
      
      // Update streak
      await _updateHabitStreak(habitId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark habit as missed: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> undoHabitCompletion(int habitId, {DateTime? date}) async {
    try {
      _clearError();
      await _habitService.undoHabitCompletion(habitId, date: date);
      
      // Update local completion status
      _todayCompletionStatus[habitId] = false;
      
      // Update streak
      await _updateHabitStreak(habitId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to undo habit completion: ${e.toString()}');
      return false;
    }
  }
  
  // Helper method to update a single habit's streak
  Future<void> _updateHabitStreak(int habitId) async {
    try {
      final habit = _habits.firstWhere((h) => h.id == habitId);
      // We would need to add this method to HabitService or call the DAO directly
      // For now, we'll refresh the entire today status which includes streaks
      await loadTodayStatus();
    } catch (e) {
      // Handle error silently as this is a helper method
    }
  }
  
  // Load today's completion status and streaks
  Future<void> loadTodayStatus() async {
    try {
      final habitsWithStatus = await _habitService.getTodayHabitsWithStatus();
      
      _todayCompletionStatus.clear();
      _currentStreaks.clear();
      
      for (final habitData in habitsWithStatus) {
        final habit = habitData['habit'] as Habit;
        final isCompleted = habitData['is_completed'] as bool;
        final currentStreak = habitData['current_streak'] as int;
        
        _todayCompletionStatus[habit.id!] = isCompleted;
        _currentStreaks[habit.id!] = currentStreak;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load today\'s status: ${e.toString()}');
    }
  }
  
  // Category management
  Future<void> loadCategories() async {
    try {
      _clearError();
      _categories = await _habitService.getAllCategories();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: ${e.toString()}');
    }
  }
  
  Future<int?> createCustomCategory(String name, String colorHex, String iconName) async {
    try {
      _clearError();
      final categoryId = await _habitService.createCustomCategory(name, colorHex, iconName);
      await loadCategories(); // Reload categories
      return categoryId;
    } catch (e) {
      _setError('Failed to create category: ${e.toString()}');
      return null;
    }
  }
  
  Future<bool> deleteCustomCategory(int categoryId) async {
    try {
      _clearError();
      await _habitService.deleteCustomCategory(categoryId);
      await loadCategories(); // Reload categories
      return true;
    } catch (e) {
      _setError('Failed to delete category: ${e.toString()}');
      return false;
    }
  }
  
  // Search and filtering
  List<Habit> getHabitsByCategory(int categoryId) {
    return _habits.where((habit) => habit.categoryId == categoryId).toList();
  }
  
  Future<List<Habit>> searchHabits(String query) async {
    try {
      return await _habitService.searchHabits(query);
    } catch (e) {
      _setError('Failed to search habits: ${e.toString()}');
      return [];
    }
  }
  
  // Statistics
  Future<Map<String, dynamic>?> getHabitStats(int habitId) async {
    try {
      return await _habitService.getHabitStats(habitId);
    } catch (e) {
      _setError('Failed to get habit stats: ${e.toString()}');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getOverallHabitStats() async {
    try {
      return await _habitService.getOverallHabitStats();
    } catch (e) {
      _setError('Failed to get overall stats: ${e.toString()}');
      return null;
    }
  }
  
  // Completion calendar data
  Future<List<Map<String, dynamic>>?> getHabitCompletionCalendar(
    int habitId, 
    DateTime startDate, 
    DateTime endDate,
  ) async {
    try {
      return await _habitService.getHabitCompletionCalendar(habitId, startDate, endDate);
    } catch (e) {
      _setError('Failed to get completion calendar: ${e.toString()}');
      return null;
    }
  }
  
  // Weekly and monthly stats
  Future<List<Map<String, dynamic>>?> getWeeklyHabitStats(int habitId, int weeksBack) async {
    try {
      return await _habitService.getWeeklyHabitStats(habitId, weeksBack);
    } catch (e) {
      _setError('Failed to get weekly stats: ${e.toString()}');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>?> getMonthlyHabitStats(int habitId, int monthsBack) async {
    try {
      return await _habitService.getMonthlyHabitStats(habitId, monthsBack);
    } catch (e) {
      _setError('Failed to get monthly stats: ${e.toString()}');
      return null;
    }
  }
  
  // Dashboard data
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      return await _habitService.getDashboardData();
    } catch (e) {
      _setError('Failed to get dashboard data: ${e.toString()}');
      return null;
    }
  }
  
  // Batch operations
  Future<bool> moveHabitsToCategory(List<int> habitIds, int newCategoryId) async {
    try {
      _clearError();
      await _habitService.moveHabitsToCategory(habitIds, newCategoryId);
      await loadHabits(); // Reload habits
      return true;
    } catch (e) {
      _setError('Failed to move habits: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> bulkUpdateHabitStatus(List<int> habitIds, bool isActive) async {
    try {
      _clearError();
      await _habitService.bulkUpdateHabitStatus(habitIds, isActive);
      await loadHabits(); // Reload habits
      return true;
    } catch (e) {
      _setError('Failed to bulk update habits: ${e.toString()}');
      return false;
    }
  }
  
  // Data management
  Future<void> cleanupOldData({int daysToKeep = 365}) async {
    try {
      await _habitService.cleanupOldData(daysToKeep: daysToKeep);
    } catch (e) {
      _setError('Failed to cleanup old data: ${e.toString()}');
    }
  }
  
  // Export
  Future<Map<String, dynamic>?> exportHabitData(int habitId) async {
    try {
      return await _habitService.exportHabitData(habitId);
    } catch (e) {
      _setError('Failed to export habit data: ${e.toString()}');
      return null;
    }
  }
  
  // Utility methods
  Category? getCategoryById(int categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }
  
  Habit? getHabitById(int habitId) {
    try {
      return _habits.firstWhere((habit) => habit.id == habitId);
    } catch (e) {
      return null;
    }
  }
  
  bool isHabitCompletedToday(int habitId) {
    return _todayCompletionStatus[habitId] ?? false;
  }
  
  // Check if habit was completed on a specific date
  Future<bool> isHabitCompletedOnDate(int habitId, DateTime date) async {
    try {
      // Normalize date to avoid timezone issues
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      
      // If it's today, use the cached status
      if (normalizedDate.isAtSameMomentAs(normalizedToday)) {
        return _todayCompletionStatus[habitId] ?? false;
      }
      
      // For past dates, query the database
      return await _habitService.isHabitCompletedOnDate(habitId, normalizedDate);
    } catch (e) {
      return false;
    }
  }
  
  int getCurrentStreak(int habitId) {
    return _currentStreaks[habitId] ?? 0;
  }

  // Calculate habit completion rate (placeholder implementation)
  double getHabitCompletionRate(int habitId) {
    // This is a simplified calculation - in a real app you'd query the database
    // for historical completion data
    final habit = getHabitById(habitId);
    if (habit == null) return 0.0;
    
    final daysSinceStart = DateTime.now().difference(habit.startDate).inDays + 1;
    final currentStreak = getCurrentStreak(habitId);
    
    // Simple estimation: current streak / days since start
    if (daysSinceStart <= 0) return 0.0;
    return (currentStreak / daysSinceStart).clamp(0.0, 1.0);
  }

  // Get habits by category
  Map<String, List<Habit>> get habitsByCategory {
    final Map<String, List<Habit>> categorizedHabits = {};
    
    for (final habit in _habits) {
      final category = _categories.firstWhere(
        (cat) => cat.id == habit.categoryId,
        orElse: () => Category(
          name: 'Other',
          colorHex: '#607D8B',
          iconName: 'more_horiz',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      if (!categorizedHabits.containsKey(category.name)) {
        categorizedHabits[category.name] = [];
      }
      categorizedHabits[category.name]!.add(habit);
    }
    
    return categorizedHabits;
  }

  // Get longest streak across all habits
  int get longestStreak {
    if (_currentStreaks.isEmpty) return 0;
    return _currentStreaks.values.reduce((a, b) => a > b ? a : b);
  }

  // Get average streak length
  double get averageStreak {
    if (_currentStreaks.isEmpty) return 0.0;
    final total = _currentStreaks.values.reduce((a, b) => a + b);
    return total / _currentStreaks.length;
  }

  // Get habits by priority
  Map<String, List<Habit>> get habitsByPriority {
    final Map<String, List<Habit>> prioritizedHabits = {};
    
    for (final habit in _habits) {
      if (!prioritizedHabits.containsKey(habit.priority)) {
        prioritizedHabits[habit.priority] = [];
      }
      prioritizedHabits[habit.priority]!.add(habit);
    }
    
    return prioritizedHabits;
  }

  // Get most consistent habit (highest completion rate)
  Habit? get mostConsistentHabit {
    if (_habits.isEmpty) return null;
    
    Habit? bestHabit;
    double bestRate = 0.0;
    
    for (final habit in _habits) {
      final rate = getHabitCompletionRate(habit.id!);
      if (rate > bestRate) {
        bestRate = rate;
        bestHabit = habit;
      }
    }
    
    return bestHabit;
  }

  // Get total time committed to habits today (in minutes)
  int get totalDailyTimeCommitment {
    return todayHabits.fold(0, (total, habit) => total + habit.durationMinutes);
  }

  // Get completion percentage for each day of the week
  Map<String, double> get weeklyCompletionPattern {
    return getWeeklyCompletionPattern(DateTime.now());
  }

  Map<String, double> getWeeklyCompletionPattern(DateTime weekDate) {
    final Map<String, double> pattern = {};
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    // Get start of the week for the given date
    final startOfWeek = weekDate.subtract(Duration(days: weekDate.weekday - 1));
    
    for (int i = 0; i < days.length; i++) {
      final dayDate = startOfWeek.add(Duration(days: i));
      final completionRate = _calculateDayCompletionRate(dayDate);
      pattern[days[i]] = completionRate;
    }
    
    return pattern;
  }

  double _calculateDayCompletionRate(DateTime date) {
    if (_habits.isEmpty) return 0.0;
    
    // Check if date is today
    final isToday = _isSameDay(date, DateTime.now());
    
    if (isToday) {
      // For today, use current completion status
      final todayCompleted = _todayCompletionStatus.values.where((completed) => completed).length;
      return todayCompleted / _habits.length;
    } else if (date.isAfter(DateTime.now())) {
      // Future dates have no completion
      return 0.0;
    } else {
      // For past dates, estimate based on streaks and habit start dates
      int completedHabits = 0;
      
      for (final habit in _habits) {
        if (date.isBefore(habit.startDate)) continue;
        
        final currentStreak = getCurrentStreak(habit.id!);
        final daysSinceStart = DateTime.now().difference(habit.startDate).inDays;
        final daysFromDate = DateTime.now().difference(date).inDays;
        
        // If the habit's current streak is longer than days from the date,
        // it was likely completed on that date
        if (currentStreak > daysFromDate) {
          completedHabits++;
        } else {
          // Use a probability based on overall performance
          final overallRate = daysSinceStart > 0 ? (currentStreak / daysSinceStart).clamp(0.0, 1.0) : 0.5;
          if (overallRate > 0.5) {
            completedHabits++;
          }
        }
      }
      
      return completedHabits / _habits.length;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  // Calculate total missed habits (estimated based on streaks vs time since creation)
  int get totalMissedHabits {
    int totalMissed = 0;
    
    for (final habit in _habits) {
      final daysSinceStart = DateTime.now().difference(habit.startDate).inDays + 1;
      final currentStreak = getCurrentStreak(habit.id!);
      
      // Estimate missed days as (days since start - current streak)
      // This is a simplified calculation - in real app would query completion history
      final estimatedMissed = (daysSinceStart - currentStreak).clamp(0, daysSinceStart);
      totalMissed += estimatedMissed;
    }
    
    return totalMissed;
  }

  // Calculate total completed habits across all time
  int get totalCompletedHabits {
    // Sum up all current streaks as a proxy for total completions
    // In a real app, this would sum all completion records from the database
    return _currentStreaks.values.fold(0, (sum, streak) => sum + streak);
  }

  // Calculate overall consistency score (0-100)
  double get overallConsistencyScore {
    if (_habits.isEmpty) return 0.0;
    
    double totalConsistency = 0.0;
    int validHabits = 0;
    
    for (final habit in _habits) {
      final daysSinceStart = DateTime.now().difference(habit.startDate).inDays + 1;
      if (daysSinceStart > 0) {
        final currentStreak = getCurrentStreak(habit.id!);
        final consistency = (currentStreak / daysSinceStart).clamp(0.0, 1.0);
        totalConsistency += consistency;
        validHabits++;
      }
    }
    
    if (validHabits == 0) return 0.0;
    
    // Convert to percentage and add some momentum bonus based on recent performance
    final baseScore = (totalConsistency / validHabits) * 100;
    
    // Add momentum bonus based on today's completion rate (max +10 points)
    final momentumBonus = (todayCompletionRate / 100) * 10;
    
    return (baseScore + momentumBonus).clamp(0.0, 100.0);
  }
  
  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}