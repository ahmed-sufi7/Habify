import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/habit.dart';
import '../models/category.dart';

/// Extension methods for BuildContext to make provider access easier
extension ProviderExtensions on BuildContext {
  // App Settings Provider
  AppSettingsProvider get appSettings => read<AppSettingsProvider>();
  AppSettingsProvider get watchAppSettings => watch<AppSettingsProvider>();
  
  // Category Provider
  CategoryProvider get categoryProvider => read<CategoryProvider>();
  CategoryProvider get watchCategoryProvider => watch<CategoryProvider>();
  
  // Habit Provider
  HabitProvider get habitProvider => read<HabitProvider>();
  HabitProvider get watchHabitProvider => watch<HabitProvider>();
  
  // Pomodoro Provider
  PomodoroProvider get pomodoroProvider => read<PomodoroProvider>();
  PomodoroProvider get watchPomodoroProvider => watch<PomodoroProvider>();
  
  // Note: Notification provider removed - using simple notification service instead
  
  // Statistics Provider
  StatisticsProvider get statisticsProvider => read<StatisticsProvider>();
  StatisticsProvider get watchStatisticsProvider => watch<StatisticsProvider>();
}

/// Extension methods for habit-related operations
extension HabitProviderExtensions on HabitProvider {
  /// Get habits filtered by today's schedule
  List<Habit> get todaysScheduledHabits {
    final now = DateTime.now();
    return habits.where((habit) {
      return habit.shouldShowOnDate(now);
    }).toList();
  }
  
  /// Get completion percentage for today
  double get todaysCompletionPercentage {
    final todayHabits = todaysScheduledHabits;
    if (todayHabits.isEmpty) return 0.0;
    
    final completedCount = todayHabits.where((habit) {
      return todayCompletionStatus[habit.id] == true;
    }).length;
    
    return (completedCount / todayHabits.length) * 100;
  }
  
  /// Get habits by priority
  List<Habit> getHabitsByPriority(String priority) {
    return habits.where((habit) => habit.priority == priority).toList();
  }
  
  /// Get active streak habits
  List<Habit> get activeStreakHabits {
    return habits.where((habit) {
      final streak = currentStreaks[habit.id] ?? 0;
      return streak > 0;
    }).toList();
  }
  
  /// Quick completion toggle
  Future<void> toggleHabitCompletion(int habitId) async {
    final isCompleted = isHabitCompletedToday(habitId);
    if (isCompleted) {
      await undoHabitCompletion(habitId);
    } else {
      await completeHabit(habitId);
    }
  }
}

/// Extension methods for category-related operations
extension CategoryProviderExtensions on CategoryProvider {
  /// Get category by color
  Category? getCategoryByColor(String colorHex) {
    try {
      return categories.firstWhere(
        (category) => category.colorHex == colorHex,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get most used categories
  List<Category> getMostUsedCategories(HabitProvider habitProvider, {int limit = 5}) {
    final categoryUsage = <int, int>{};
    
    for (final habit in habitProvider.habits) {
      categoryUsage[habit.categoryId] = (categoryUsage[habit.categoryId] ?? 0) + 1;
    }
    
    final sortedCategories = categories.where((cat) => categoryUsage.containsKey(cat.id)).toList();
    sortedCategories.sort((a, b) => 
      (categoryUsage[b.id] ?? 0).compareTo(categoryUsage[a.id] ?? 0)
    );
    
    return sortedCategories.take(limit).toList();
  }
  
  /// Create quick category with validation
  Future<Category?> createQuickCategory(String name) async {
    if (!isCategoryNameAvailable(name)) return null;
    
    final colorHex = getRandomColor();
    final iconName = getRandomIcon();
    
    final categoryId = await createCategory(
      name: name,
      colorHex: colorHex,
      iconName: iconName,
    );
    
    if (categoryId != null) {
      return getCategoryById(categoryId);
    }
    
    return null;
  }
}

/// Extension methods for pomodoro-related operations
extension PomodoroProviderExtensions on PomodoroProvider {
  /// Get formatted session info
  String get sessionInfo {
    if (activeSession == null) return 'No active session';
    
    return '${activeSession!.name} - $currentSessionDescription';
  }
  
  /// Get completion percentage of current session
  double get sessionCompletionPercentage {
    if (totalSeconds == 0) return 0.0;
    return (elapsedSeconds / totalSeconds) * 100;
  }
  
  /// Quick start with default session
  Future<bool> quickStart({int minutes = 25}) async {
    return await startQuickSession(minutes: minutes);
  }
  
  /// Get next recommended session duration
  int getRecommendedSessionDuration() {
    final templates = getSessionTemplates();
    
    // Default to classic Pomodoro if no history
    if (overallStats == null) {
      return templates['Classic Pomodoro']!['work'] as int;
    }
    
    // Recommend based on recent performance
    final totalMinutes = overallStats!['total_work_minutes'] as int? ?? 0;
    final avgSessionLength = totalMinutes / (overallStats!['total_sessions'] as int? ?? 1);
    
    if (avgSessionLength > 45) return 60;
    if (avgSessionLength > 30) return 45;
    return 25;
  }
}

// Note: Notification extension methods removed since NotificationProvider was simplified

/// Extension methods for statistics-related operations
extension StatisticsProviderExtensions on StatisticsProvider {
  /// Get habit performance rating
  String get habitPerformanceRating {
    final completionRate = todayCompletionRate;
    
    if (completionRate >= 90) return 'Excellent';
    if (completionRate >= 75) return 'Good';
    if (completionRate >= 50) return 'Fair';
    if (completionRate >= 25) return 'Poor';
    return 'Needs Improvement';
  }
  
  /// Get productivity level based on Pomodoro stats
  String get productivityLevel {
    if (overallPomodoroStats == null) return 'No data';
    
    final dailyAvgMinutes = totalFocusMinutes / 
      (overallPomodoroStats!['days_active'] as int? ?? 1);
    
    if (dailyAvgMinutes >= 240) return 'Highly Productive'; // 4+ hours
    if (dailyAvgMinutes >= 120) return 'Productive';       // 2+ hours
    if (dailyAvgMinutes >= 60) return 'Moderately Active'; // 1+ hour
    return 'Getting Started';
  }
  
  /// Get weekly improvement percentage
  double get weeklyImprovementPercentage {
    final habitTrends = calculateHabitTrends();
    return habitTrends['change_percentage']?.toDouble() ?? 0.0;
  }
  
  /// Get monthly summary
  Map<String, dynamic> getMonthlySummary() {
    return {
      'total_habits': totalActiveHabits,
      'completed_habits': totalCompletedHabits,
      'completion_rate': todayCompletionRate,
      'average_streak': averageStreakLength,
      'focus_minutes': totalFocusMinutes,
      'performance_rating': habitPerformanceRating,
      'productivity_level': productivityLevel,
    };
  }
}

/// Extension methods for app settings
extension AppSettingsProviderExtensions on AppSettingsProvider {
  /// Quick theme toggle
  Future<void> quickToggleTheme() async {
    await toggleTheme();
  }
  
  /// Check if it's user's preferred notification time
  bool isPreferredNotificationTime() {
    final now = TimeOfDay.now();
    final preferred = reminderTimeOfDay;
    
    // Within 1 hour of preferred time
    final nowMinutes = now.hour * 60 + now.minute;
    final preferredMinutes = preferred.hour * 60 + preferred.minute;
    
    return (nowMinutes - preferredMinutes).abs() <= 60;
  }
  
  /// Get app usage duration
  Duration? getAppUsageDuration() {
    if (appVersion == null) return null;
    // This would need to be implemented with actual usage tracking
    return null;
  }
  
  /// Quick settings validation
  bool get hasValidSettings {
    return isInitialized && 
           AppSettingsProvider.availableLanguages.contains(language) &&
           AppSettingsProvider.backupFrequencyOptions.contains(backupFrequency);
  }
}