import 'package:flutter/material.dart';
import '../services/database/habit_service.dart';
import '../services/database/pomodoro_service.dart';
import '../services/database/notification_service.dart';
import '../models/habit.dart';
import '../models/category.dart';

enum StatsPeriod {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  all,
}

enum StatsChartType {
  line,
  bar,
  pie,
  heatmap,
}

class StatisticsProvider extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  final PomodoroService _pomodoroService = PomodoroService();
  final NotificationService _notificationService = NotificationService();
  
  // State variables
  Map<String, dynamic>? _overallHabitStats;
  Map<String, dynamic>? _overallPomodoroStats;
  Map<String, dynamic>? _notificationStats;
  Map<String, dynamic>? _dashboardData;
  
  List<Map<String, dynamic>>? _habitWeeklyStats;
  List<Map<String, dynamic>>? _habitMonthlyStats;
  List<Map<String, dynamic>>? _pomodoroWeeklyStats;
  List<Map<String, dynamic>>? _pomodoroMonthlyStats;
  
  StatsPeriod _selectedPeriod = StatsPeriod.thisWeek;
  bool _isLoading = false;
  String? _error;
  
  // Cache for expensive calculations
  Map<String, dynamic> _statsCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 15);
  
  // Getters
  Map<String, dynamic>? get overallHabitStats => _overallHabitStats;
  Map<String, dynamic>? get overallPomodoroStats => _overallPomodoroStats;
  Map<String, dynamic>? get notificationStats => _notificationStats;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  
  List<Map<String, dynamic>>? get habitWeeklyStats => _habitWeeklyStats;
  List<Map<String, dynamic>>? get habitMonthlyStats => _habitMonthlyStats;
  List<Map<String, dynamic>>? get pomodoroWeeklyStats => _pomodoroWeeklyStats;
  List<Map<String, dynamic>>? get pomodoroMonthlyStats => _pomodoroMonthlyStats;
  
  StatsPeriod get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Computed properties
  double get todayCompletionRate {
    if (_overallHabitStats == null) return 0.0;
    return _overallHabitStats!['today_completion_rate']?.toDouble() ?? 0.0;
  }
  
  int get totalActiveHabits {
    if (_overallHabitStats == null) return 0;
    return _overallHabitStats!['habit_stats']?['active_count'] ?? 0;
  }
  
  int get totalCompletedHabits {
    if (_overallHabitStats == null) return 0;
    return _overallHabitStats!['completion_stats']?['total_completed'] ?? 0;
  }

  int get totalMissedHabits {
    if (_overallHabitStats == null) return 0;
    return _overallHabitStats!['completion_stats']?['total_missed'] ?? 0;
  }

  Map<String, int> get weeklyCompletionData {
    if (_pomodoroWeeklyStats == null) return {};
    
    final Map<String, int> weeklyData = {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Initialize with 0 values
    for (String day in days) {
      weeklyData[day] = 0;
    }
    
    // Fill with actual data if available
    for (final dayData in _pomodoroWeeklyStats!) {
      final dayName = dayData['day_name'] as String?;
      final completions = dayData['completions'] as int? ?? 0;
      if (dayName != null && days.contains(dayName)) {
        weeklyData[dayName] = completions;
      }
    }
    
    return weeklyData;
  }
  
  int get totalPomodoroSessions {
    if (_overallPomodoroStats == null) return 0;
    return _overallPomodoroStats!['total_sessions'] ?? 0;
  }
  
  int get totalFocusMinutes {
    if (_overallPomodoroStats == null) return 0;
    return _overallPomodoroStats!['total_work_minutes'] ?? 0;
  }
  
  double get averageStreakLength {
    if (_overallHabitStats == null) return 0.0;
    return _overallHabitStats!['completion_stats']?['average_streak']?.toDouble() ?? 0.0;
  }
  
  // Initialize provider
  Future<void> initialize() async {
    await Future.wait([
      loadOverallStats(),
      loadWeeklyStats(),
      loadMonthlyStats(),
      loadDashboardData(),
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
  
  // Cache management
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).compareTo(_cacheValidDuration) < 0;
  }
  
  void _updateCache(String key, dynamic data) {
    _statsCache[key] = data;
    _lastCacheUpdate = DateTime.now();
  }
  
  T? _getFromCache<T>(String key) {
    if (!_isCacheValid()) return null;
    return _statsCache[key] as T?;
  }
  
  // Statistics loading
  Future<void> loadOverallStats() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Check cache first
      final cachedHabitStats = _getFromCache<Map<String, dynamic>>('habit_stats');
      final cachedPomodoroStats = _getFromCache<Map<String, dynamic>>('pomodoro_stats');
      final cachedNotificationStats = _getFromCache<Map<String, dynamic>>('notification_stats');
      
      if (cachedHabitStats != null && cachedPomodoroStats != null && cachedNotificationStats != null) {
        _overallHabitStats = cachedHabitStats;
        _overallPomodoroStats = cachedPomodoroStats;
        _notificationStats = cachedNotificationStats;
        notifyListeners();
        return;
      }
      
      // Load fresh data
      final results = await Future.wait([
        _habitService.getOverallHabitStats(),
        _pomodoroService.getOverallPomodoroStats(),
        _notificationService.getNotificationStats(),
      ]);
      
      _overallHabitStats = results[0];
      _overallPomodoroStats = results[1];
      _notificationStats = results[2];
      
      // Update cache
      _updateCache('habit_stats', _overallHabitStats);
      _updateCache('pomodoro_stats', _overallPomodoroStats);
      _updateCache('notification_stats', _notificationStats);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load overall statistics: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadWeeklyStats() async {
    try {
      _clearError();
      
      final results = await Future.wait([
        _pomodoroService.getDailyStats(7), // Last 7 days for Pomodoro
      ]);
      
      _pomodoroWeeklyStats = results[0];
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load weekly statistics: ${e.toString()}');
    }
  }
  
  Future<void> loadMonthlyStats() async {
    try {
      _clearError();
      
      final results = await Future.wait([
        _pomodoroService.getDailyStats(30), // Last 30 days for Pomodoro
      ]);
      
      _pomodoroMonthlyStats = results[0];
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load monthly statistics: ${e.toString()}');
    }
  }
  
  Future<void> loadDashboardData() async {
    try {
      _clearError();
      
      // Check cache first
      final cachedDashboard = _getFromCache<Map<String, dynamic>>('dashboard_data');
      if (cachedDashboard != null) {
        _dashboardData = cachedDashboard;
        notifyListeners();
        return;
      }
      
      _dashboardData = await _habitService.getDashboardData();
      
      // Update cache
      _updateCache('dashboard_data', _dashboardData);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load dashboard data: ${e.toString()}');
    }
  }
  
  // Period selection
  void selectPeriod(StatsPeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
      // Optionally reload stats for the new period
      _loadStatsForPeriod(period);
    }
  }
  
  Future<void> _loadStatsForPeriod(StatsPeriod period) async {
    switch (period) {
      case StatsPeriod.today:
        // Today's stats are already in overall stats
        break;
      case StatsPeriod.thisWeek:
        await loadWeeklyStats();
        break;
      case StatsPeriod.thisMonth:
        await loadMonthlyStats();
        break;
      case StatsPeriod.thisYear:
        // Load yearly stats
        break;
      case StatsPeriod.all:
        await loadOverallStats();
        break;
    }
  }
  
  // Habit-specific statistics
  Future<Map<String, dynamic>?> getHabitStats(int habitId) async {
    try {
      return await _habitService.getHabitStats(habitId);
    } catch (e) {
      _setError('Failed to get habit statistics: ${e.toString()}');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>?> getHabitWeeklyStats(int habitId, int weeksBack) async {
    try {
      return await _habitService.getWeeklyHabitStats(habitId, weeksBack);
    } catch (e) {
      _setError('Failed to get habit weekly stats: ${e.toString()}');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>?> getHabitMonthlyStats(int habitId, int monthsBack) async {
    try {
      return await _habitService.getMonthlyHabitStats(habitId, monthsBack);
    } catch (e) {
      _setError('Failed to get habit monthly stats: ${e.toString()}');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>?> getHabitCompletionCalendar(
    int habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _habitService.getHabitCompletionCalendar(habitId, startDate, endDate);
    } catch (e) {
      _setError('Failed to get habit completion calendar: ${e.toString()}');
      return null;
    }
  }
  
  // Pomodoro-specific statistics
  Future<Map<String, dynamic>?> getPomodoroSessionStats(int sessionId) async {
    try {
      return await _pomodoroService.getSessionStats(sessionId);
    } catch (e) {
      _setError('Failed to get Pomodoro session stats: ${e.toString()}');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getPomodoroProductivityInsights(int daysBack) async {
    try {
      return await _pomodoroService.getProductivityInsights(daysBack);
    } catch (e) {
      _setError('Failed to get productivity insights: ${e.toString()}');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>?> getPomodoroSessionUsageStats() async {
    try {
      return await _pomodoroService.getSessionUsageStats();
    } catch (e) {
      _setError('Failed to get session usage stats: ${e.toString()}');
      return null;
    }
  }
  
  // Advanced analytics
  Map<String, dynamic> calculateHabitTrends() {
    if (_habitWeeklyStats == null || _habitWeeklyStats!.isEmpty) {
      return {'trend': 'neutral', 'change_percentage': 0.0};
    }
    
    final recentWeek = _habitWeeklyStats!.last;
    final previousWeek = _habitWeeklyStats!.length > 1 ? _habitWeeklyStats![_habitWeeklyStats!.length - 2] : null;
    
    if (previousWeek == null) {
      return {'trend': 'neutral', 'change_percentage': 0.0};
    }
    
    final recentRate = recentWeek['completion_rate']?.toDouble() ?? 0.0;
    final previousRate = previousWeek['completion_rate']?.toDouble() ?? 0.0;
    
    if (previousRate == 0) {
      return {'trend': recentRate > 0 ? 'up' : 'neutral', 'change_percentage': 0.0};
    }
    
    final changePercentage = ((recentRate - previousRate) / previousRate) * 100;
    
    String trend = 'neutral';
    if (changePercentage > 5) {
      trend = 'up';
    } else if (changePercentage < -5) {
      trend = 'down';
    }
    
    return {
      'trend': trend,
      'change_percentage': changePercentage.abs(),
      'recent_rate': recentRate,
      'previous_rate': previousRate,
    };
  }
  
  Map<String, dynamic> calculatePomodoroTrends() {
    if (_pomodoroWeeklyStats == null || _pomodoroWeeklyStats!.isEmpty) {
      return {'trend': 'neutral', 'change_percentage': 0.0};
    }
    
    final recentWeek = _pomodoroWeeklyStats!.last;
    final previousWeek = _pomodoroWeeklyStats!.length > 1 ? _pomodoroWeeklyStats![_pomodoroWeeklyStats!.length - 2] : null;
    
    if (previousWeek == null) {
      return {'trend': 'neutral', 'change_percentage': 0.0};
    }
    
    final recentMinutes = recentWeek['work_minutes']?.toDouble() ?? 0.0;
    final previousMinutes = previousWeek['work_minutes']?.toDouble() ?? 0.0;
    
    if (previousMinutes == 0) {
      return {'trend': recentMinutes > 0 ? 'up' : 'neutral', 'change_percentage': 0.0};
    }
    
    final changePercentage = ((recentMinutes - previousMinutes) / previousMinutes) * 100;
    
    String trend = 'neutral';
    if (changePercentage > 10) {
      trend = 'up';
    } else if (changePercentage < -10) {
      trend = 'down';
    }
    
    return {
      'trend': trend,
      'change_percentage': changePercentage.abs(),
      'recent_minutes': recentMinutes,
      'previous_minutes': previousMinutes,
    };
  }
  
  // Category analytics
  Map<String, int> getHabitsByCategory() {
    if (_dashboardData == null) return {};
    
    final categories = _dashboardData!['categories'] as List<dynamic>? ?? [];
    final habits = _dashboardData!['today_habits'] as List<dynamic>? ?? [];
    
    final Map<String, int> categoryCount = {};
    
    // Initialize categories with 0 count
    for (final category in categories) {
      final cat = category as Map<String, dynamic>;
      categoryCount[cat['name']] = 0;
    }
    
    // Count habits in each category
    for (final habitData in habits) {
      final habit = habitData['habit'] as Map<String, dynamic>? ?? {};
      final categoryId = habit['category_id'] as int?;
      
      if (categoryId != null) {
        final category = categories.firstWhere(
          (cat) => (cat as Map<String, dynamic>)['id'] == categoryId,
          orElse: () => null,
        );
        
        if (category != null) {
          final categoryName = (category as Map<String, dynamic>)['name'];
          categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
        }
      }
    }
    
    return categoryCount;
  }
  
  List<Map<String, dynamic>> getTopPerformingHabits({int limit = 5}) {
    if (_dashboardData == null) return [];
    
    final habits = _dashboardData!['today_habits'] as List<dynamic>? ?? [];
    final currentStreaks = _dashboardData!['current_streaks'] as Map<String, dynamic>? ?? {};
    
    final List<Map<String, dynamic>> habitPerformance = [];
    
    for (final habitData in habits) {
      final habit = habitData['habit'] as Map<String, dynamic>;
      final habitId = habit['id'].toString();
      final currentStreak = currentStreaks[habitId] as int? ?? 0;
      
      habitPerformance.add({
        'habit': habit,
        'current_streak': currentStreak,
        'is_completed': habitData['is_completed'] as bool? ?? false,
      });
    }
    
    // Sort by current streak descending
    habitPerformance.sort((a, b) => (b['current_streak'] as int).compareTo(a['current_streak'] as int));
    
    return habitPerformance.take(limit).toList();
  }
  
  // Achievement calculations
  List<Map<String, dynamic>> getAchievements() {
    final achievements = <Map<String, dynamic>>[];
    
    // Habit achievements
    if (_overallHabitStats != null) {
      final completionStats = _overallHabitStats!['completion_stats'] as Map<String, dynamic>? ?? {};
      final totalCompleted = completionStats['total_completed'] as int? ?? 0;
      final longestStreak = completionStats['longest_streak'] as int? ?? 0;
      
      // Completion milestones
      if (totalCompleted >= 100) {
        achievements.add({
          'title': 'Century Club',
          'description': 'Completed 100 habits!',
          'type': 'habit_completion',
          'icon': 'military_tech',
          'color': '#FFD700', // Gold
        });
      } else if (totalCompleted >= 50) {
        achievements.add({
          'title': 'Half Century',
          'description': 'Completed 50 habits!',
          'type': 'habit_completion',
          'icon': 'grade',
          'color': '#C0C0C0', // Silver
        });
      } else if (totalCompleted >= 10) {
        achievements.add({
          'title': 'Getting Started',
          'description': 'Completed 10 habits!',
          'type': 'habit_completion',
          'icon': 'emoji_events',
          'color': '#CD7F32', // Bronze
        });
      }
      
      // Streak achievements
      if (longestStreak >= 30) {
        achievements.add({
          'title': 'Consistency Master',
          'description': '30-day streak achieved!',
          'type': 'streak',
          'icon': 'local_fire_department',
          'color': '#FF4500', // Orange Red
        });
      } else if (longestStreak >= 7) {
        achievements.add({
          'title': 'Week Warrior',
          'description': '7-day streak achieved!',
          'type': 'streak',
          'icon': 'whatshot',
          'color': '#FF6B35', // Orange
        });
      }
    }
    
    // Pomodoro achievements
    if (_overallPomodoroStats != null) {
      final totalSessions = _overallPomodoroStats!['total_sessions'] as int? ?? 0;
      final totalMinutes = _overallPomodoroStats!['total_work_minutes'] as int? ?? 0;
      
      // Session milestones
      if (totalSessions >= 100) {
        achievements.add({
          'title': 'Focus Master',
          'description': 'Completed 100 Pomodoro sessions!',
          'type': 'pomodoro_sessions',
          'icon': 'psychology',
          'color': '#4CAF50', // Green
        });
      } else if (totalSessions >= 25) {
        achievements.add({
          'title': 'Focused Mind',
          'description': 'Completed 25 Pomodoro sessions!',
          'type': 'pomodoro_sessions',
          'icon': 'timer',
          'color': '#2196F3', // Blue
        });
      }
      
      // Time milestones (in hours)
      final totalHours = totalMinutes ~/ 60;
      if (totalHours >= 100) {
        achievements.add({
          'title': 'Time Investor',
          'description': '100 hours of focused work!',
          'type': 'focus_time',
          'icon': 'access_time',
          'color': '#9C27B0', // Purple
        });
      } else if (totalHours >= 25) {
        achievements.add({
          'title': 'Dedicated Worker',
          'description': '25 hours of focused work!',
          'type': 'focus_time',
          'icon': 'schedule',
          'color': '#607D8B', // Blue Grey
        });
      }
    }
    
    return achievements;
  }
  
  // Export statistics
  Map<String, dynamic> exportAllStats() {
    return {
      'export_date': DateTime.now().toIso8601String(),
      'overall_habit_stats': _overallHabitStats,
      'overall_pomodoro_stats': _overallPomodoroStats,
      'notification_stats': _notificationStats,
      'habit_weekly_stats': _habitWeeklyStats,
      'habit_monthly_stats': _habitMonthlyStats,
      'pomodoro_weekly_stats': _pomodoroWeeklyStats,
      'pomodoro_monthly_stats': _pomodoroMonthlyStats,
      'dashboard_data': _dashboardData,
      'achievements': getAchievements(),
      'habit_trends': calculateHabitTrends(),
      'pomodoro_trends': calculatePomodoroTrends(),
      'habits_by_category': getHabitsByCategory(),
      'top_performing_habits': getTopPerformingHabits(),
    };
  }
  
  // Chart data preparation
  List<Map<String, dynamic>> getChartData(StatsChartType chartType, String dataType) {
    switch (dataType) {
      case 'habit_completion':
        return _prepareHabitCompletionChartData(chartType);
      case 'pomodoro_focus':
        return _preparePomodoroFocusChartData(chartType);
      case 'category_distribution':
        return _prepareCategoryDistributionChartData(chartType);
      default:
        return [];
    }
  }
  
  List<Map<String, dynamic>> _prepareHabitCompletionChartData(StatsChartType chartType) {
    if (_habitWeeklyStats == null) return [];
    
    return _habitWeeklyStats!.map((weekData) {
      return {
        'x': weekData['week'] ?? '',
        'y': weekData['completion_rate'] ?? 0.0,
        'label': 'Completion Rate',
      };
    }).toList();
  }
  
  List<Map<String, dynamic>> _preparePomodoroFocusChartData(StatsChartType chartType) {
    if (_pomodoroWeeklyStats == null) return [];
    
    return _pomodoroWeeklyStats!.map((dayData) {
      return {
        'x': dayData['date'] ?? '',
        'y': (dayData['work_minutes'] ?? 0) / 60.0, // Convert to hours
        'label': 'Focus Hours',
      };
    }).toList();
  }
  
  List<Map<String, dynamic>> _prepareCategoryDistributionChartData(StatsChartType chartType) {
    final habitsByCategory = getHabitsByCategory();
    
    return habitsByCategory.entries.map((entry) {
      return {
        'x': entry.key,
        'y': entry.value,
        'label': entry.key,
      };
    }).toList();
  }
  
  // Refresh data
  Future<void> refresh() async {
    _statsCache.clear();
    _lastCacheUpdate = null;
    await initialize();
  }
  
  // Clear cache
  void clearCache() {
    _statsCache.clear();
    _lastCacheUpdate = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}