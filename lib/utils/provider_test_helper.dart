import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

/// Test helper class to verify provider functionality
class ProviderTestHelper {
  /// Test all providers for basic functionality
  static Future<Map<String, bool>> testAllProviders(BuildContext context) async {
    final results = <String, bool>{};
    
    try {
      // Test Theme Provider
      results['ThemeProvider'] = await _testThemeProvider(context);
      
      // Test App Settings Provider  
      results['AppSettingsProvider'] = await _testAppSettingsProvider(context);
      
      // Test Category Provider
      results['CategoryProvider'] = await _testCategoryProvider(context);
      
      // Test Habit Provider
      results['HabitProvider'] = await _testHabitProvider(context);
      
      // Test Pomodoro Provider
      results['PomodoroProvider'] = await _testPomodoroProvider(context);
      
      // Test Notification Provider
      results['NotificationProvider'] = await _testNotificationProvider(context);
      
      // Test Statistics Provider
      results['StatisticsProvider'] = await _testStatisticsProvider(context);
      
    } catch (e) {
      debugPrint('Provider testing error: $e');
    }
    
    return results;
  }
  
  static Future<bool> _testThemeProvider(BuildContext context) async {
    try {
      final themeProvider = context.read<ThemeProvider>();
      
      // Test theme mode access
      final currentMode = themeProvider.themeMode;
      
      // Test theme toggle
      themeProvider.toggleTheme();
      
      // Test theme data access
      final lightTheme = themeProvider.lightTheme;
      final darkTheme = themeProvider.darkTheme;
      
      // Test utility methods
      final priorityColor = themeProvider.getPriorityColor('high');
      final streakColor = themeProvider.getStreakColor(15);
      final categoryColor = themeProvider.getCategoryColor(0);
      
      return lightTheme != null && 
             darkTheme != null && 
             priorityColor != null &&
             streakColor != null &&
             categoryColor != null;
    } catch (e) {
      debugPrint('ThemeProvider test failed: $e');
      return false;
    }
  }
  
  static Future<bool> _testAppSettingsProvider(BuildContext context) async {
    try {
      final settingsProvider = context.read<AppSettingsProvider>();
      
      // Wait for initialization if needed
      if (!settingsProvider.isInitialized) {
        await settingsProvider.initialize();
      }
      
      // Test basic properties
      final isInitialized = settingsProvider.isInitialized;
      final currentTheme = settingsProvider.themeMode;
      final language = settingsProvider.language;
      final notificationsEnabled = settingsProvider.notificationsEnabled;
      
      // Test settings modification
      await settingsProvider.setNotificationsEnabled(!notificationsEnabled);
      final updatedNotifications = settingsProvider.notificationsEnabled;
      
      return isInitialized && 
             currentTheme != null &&
             language.isNotEmpty &&
             updatedNotifications == !notificationsEnabled;
    } catch (e) {
      debugPrint('AppSettingsProvider test failed: $e');
      return false;
    }
  }
  
  static Future<bool> _testCategoryProvider(BuildContext context) async {
    try {
      final categoryProvider = context.read<CategoryProvider>();
      
      // Test initialization
      await categoryProvider.initialize();
      
      // Test category access
      final categories = categoryProvider.categories;
      final defaultCategories = categoryProvider.defaultCategories;
      final customCategories = categoryProvider.customCategories;
      
      // Test validation
      final isNameAvailable = categoryProvider.isCategoryNameAvailable('Test Category ${DateTime.now().millisecondsSinceEpoch}');
      
      // Test color/icon helpers
      final randomColor = categoryProvider.getRandomColor();
      final randomIcon = categoryProvider.getRandomIcon();
      
      return categories != null &&
             defaultCategories != null &&
             customCategories != null &&
             isNameAvailable &&
             randomColor.isNotEmpty &&
             randomIcon.isNotEmpty;
    } catch (e) {
      debugPrint('CategoryProvider test failed: $e');
      return false;
    }
  }
  
  static Future<bool> _testHabitProvider(BuildContext context) async {
    try {
      final habitProvider = context.read<HabitProvider>();
      
      // Test basic properties
      final habits = habitProvider.habits;
      final categories = habitProvider.categories;
      final todayStatus = habitProvider.todayCompletionStatus;
      final currentStreaks = habitProvider.currentStreaks;
      
      // Test computed properties
      final todayHabits = habitProvider.todayHabits;
      final todayCompletedCount = habitProvider.todayCompletedCount;
      final todayTotalCount = habitProvider.todayTotalCount;
      final todayCompletionRate = habitProvider.todayCompletionRate;
      final activeHabits = habitProvider.activeHabits;
      
      return habits != null &&
             categories != null &&
             todayStatus != null &&
             currentStreaks != null &&
             todayHabits != null &&
             todayCompletedCount >= 0 &&
             todayTotalCount >= 0 &&
             todayCompletionRate >= 0 &&
             activeHabits != null;
    } catch (e) {
      debugPrint('HabitProvider test failed: $e');
      return false;
    }
  }
  
  static Future<bool> _testPomodoroProvider(BuildContext context) async {
    try {
      final pomodoroProvider = context.read<PomodoroProvider>();
      
      // Test basic properties
      final sessions = pomodoroProvider.sessions;
      final activeSessions = pomodoroProvider.activeSessions;
      final timerState = pomodoroProvider.timerState;
      final currentSessionType = pomodoroProvider.currentSessionType;
      final remainingSeconds = pomodoroProvider.remainingSeconds;
      final totalSeconds = pomodoroProvider.totalSeconds;
      
      // Test computed properties
      final isRunning = pomodoroProvider.isRunning;
      final isPaused = pomodoroProvider.isPaused;
      final isIdle = pomodoroProvider.isIdle;
      final progress = pomodoroProvider.progress;
      final formattedTime = pomodoroProvider.formattedTime;
      
      // Test templates
      final templates = pomodoroProvider.getSessionTemplates();
      
      return sessions != null &&
             activeSessions != null &&
             timerState != null &&
             currentSessionType != null &&
             remainingSeconds >= 0 &&
             totalSeconds >= 0 &&
             progress >= 0 &&
             formattedTime.isNotEmpty &&
             templates.isNotEmpty;
    } catch (e) {
      debugPrint('PomodoroProvider test failed: $e');
      return false;
    }
  }
  
  static Future<bool> _testNotificationProvider(BuildContext context) async {
    try {
      final notificationProvider = context.read<NotificationProvider>();
      
      // Test basic properties
      final notifications = notificationProvider.notifications;
      final unreadNotifications = notificationProvider.unreadNotifications;
      final pendingNotifications = notificationProvider.pendingNotifications;
      final settings = notificationProvider.settings;
      
      // Test computed properties
      final unreadCount = notificationProvider.unreadCount;
      final pendingCount = notificationProvider.pendingCount;
      final hasUnreadNotifications = notificationProvider.hasUnreadNotifications;
      final hasPendingNotifications = notificationProvider.hasPendingNotifications;
      final todayNotifications = notificationProvider.todayNotifications;
      final habitNotifications = notificationProvider.habitNotifications;
      final pomodoroNotifications = notificationProvider.pomodoroNotifications;
      
      // Test utility methods
      final isQuietHours = notificationProvider.isQuietHours();
      
      return notifications != null &&
             unreadNotifications != null &&
             pendingNotifications != null &&
             settings != null &&
             unreadCount >= 0 &&
             pendingCount >= 0 &&
             todayNotifications != null &&
             habitNotifications != null &&
             pomodoroNotifications != null;
    } catch (e) {
      debugPrint('NotificationProvider test failed: $e');
      return false;
    }
  }
  
  static Future<bool> _testStatisticsProvider(BuildContext context) async {
    try {
      final statisticsProvider = context.read<StatisticsProvider>();
      
      // Test basic properties
      final overallHabitStats = statisticsProvider.overallHabitStats;
      final overallPomodoroStats = statisticsProvider.overallPomodoroStats;
      final notificationStats = statisticsProvider.notificationStats;
      final selectedPeriod = statisticsProvider.selectedPeriod;
      
      // Test computed properties
      final todayCompletionRate = statisticsProvider.todayCompletionRate;
      final totalActiveHabits = statisticsProvider.totalActiveHabits;
      final totalCompletedHabits = statisticsProvider.totalCompletedHabits;
      final totalPomodoroSessions = statisticsProvider.totalPomodoroSessions;
      final totalFocusMinutes = statisticsProvider.totalFocusMinutes;
      final averageStreakLength = statisticsProvider.averageStreakLength;
      
      // Test analytics methods
      final habitTrends = statisticsProvider.calculateHabitTrends();
      final pomodoroTrends = statisticsProvider.calculatePomodoroTrends();
      final habitsByCategory = statisticsProvider.getHabitsByCategory();
      final topPerformingHabits = statisticsProvider.getTopPerformingHabits();
      final achievements = statisticsProvider.getAchievements();
      
      return selectedPeriod != null &&
             todayCompletionRate >= 0 &&
             totalActiveHabits >= 0 &&
             totalCompletedHabits >= 0 &&
             totalPomodoroSessions >= 0 &&
             totalFocusMinutes >= 0 &&
             averageStreakLength >= 0 &&
             habitTrends != null &&
             pomodoroTrends != null &&
             habitsByCategory != null &&
             topPerformingHabits != null &&
             achievements != null;
    } catch (e) {
      debugPrint('StatisticsProvider test failed: $e');
      return false;
    }
  }
  
  /// Print test results in a formatted way
  static void printTestResults(Map<String, bool> results) {
    debugPrint('\n=== Provider Test Results ===');
    
    int passed = 0;
    int total = results.length;
    
    results.forEach((providerName, success) {
      final status = success ? '✅ PASS' : '❌ FAIL';
      debugPrint('$providerName: $status');
      if (success) passed++;
    });
    
    debugPrint('\nSummary: $passed/$total providers passed tests');
    debugPrint('Success Rate: ${((passed / total) * 100).toStringAsFixed(1)}%');
    debugPrint('==============================\n');
  }
  
  /// Quick test runner for development
  static Future<void> runQuickTest(BuildContext context) async {
    debugPrint('Starting provider functionality tests...');
    final results = await testAllProviders(context);
    printTestResults(results);
  }
}