import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/database/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  Timer? _notificationTimer;
  
  // State variables
  List<AppNotification> _notifications = [];
  List<AppNotification> _unreadNotifications = [];
  List<AppNotification> _pendingNotifications = [];
  Map<String, dynamic>? _notificationStats;
  
  bool _isLoading = false;
  String? _error;
  
  // Settings
  Map<String, dynamic> _settings = {
    'habit_reminders_enabled': true,
    'streak_celebrations_enabled': true,
    'pomodoro_notifications_enabled': true,
    'daily_summary_enabled': false,
    'weekly_review_enabled': false,
    'quiet_hours_enabled': false,
    'quiet_hours_start': '22:00',
    'quiet_hours_end': '08:00',
  };
  
  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => _unreadNotifications;
  List<AppNotification> get pendingNotifications => _pendingNotifications;
  Map<String, dynamic>? get notificationStats => _notificationStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get settings => _settings;
  
  // Computed properties
  int get unreadCount => _unreadNotifications.length;
  int get pendingCount => _pendingNotifications.length;
  bool get hasUnreadNotifications => unreadCount > 0;
  bool get hasPendingNotifications => pendingCount > 0;
  
  List<AppNotification> get todayNotifications {
    final today = DateTime.now();
    return _notifications.where((notification) {
      final notificationDate = notification.createdAt;
      return notificationDate.day == today.day &&
             notificationDate.month == today.month &&
             notificationDate.year == today.year;
    }).toList();
  }
  
  List<AppNotification> get habitNotifications => 
      _notifications.where((n) => n.habitId != null).toList();
      
  List<AppNotification> get pomodoroNotifications =>
      _notifications.where((n) => n.pomodoroSessionId != null).toList();
  
  // Initialize provider
  Future<void> initialize() async {
    await Future.wait([
      loadNotifications(),
      loadUnreadNotifications(),
      loadPendingNotifications(),
      loadNotificationStats(),
      loadSettings(),
    ]);
    
    // Start periodic notification processing
    _startNotificationProcessing();
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
  
  // Notification management
  Future<void> loadNotifications() async {
    try {
      _setLoading(true);
      _clearError();
      _notifications = await _notificationService.getAllNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notifications: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadUnreadNotifications() async {
    try {
      _clearError();
      _unreadNotifications = await _notificationService.getUnreadNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load unread notifications: ${e.toString()}');
    }
  }
  
  Future<void> loadPendingNotifications() async {
    try {
      _clearError();
      _pendingNotifications = await _notificationService.getPendingNotifications();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load pending notifications: ${e.toString()}');
    }
  }
  
  Future<int?> createNotification({
    required String type,
    required String title,
    required String message,
    required DateTime scheduledTime,
    int? habitId,
    int? pomodoroSessionId,
    Map<String, dynamic>? data,
  }) async {
    try {
      _clearError();
      
      final notificationId = await _notificationService.createNotification(
        type: type,
        title: title,
        message: message,
        scheduledTime: scheduledTime,
        habitId: habitId,
        pomodoroSessionId: pomodoroSessionId,
        data: data,
      );
      
      // Reload notifications
      await loadNotifications();
      await loadPendingNotifications();
      
      return notificationId;
    } catch (e) {
      _setError('Failed to create notification: ${e.toString()}');
      return null;
    }
  }
  
  Future<bool> updateNotification(AppNotification notification) async {
    try {
      _clearError();
      await _notificationService.updateNotification(notification);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update notification: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> deleteNotification(int id) async {
    try {
      _clearError();
      await _notificationService.deleteNotification(id);
      
      // Remove from local state
      _notifications.removeWhere((n) => n.id == id);
      _unreadNotifications.removeWhere((n) => n.id == id);
      _pendingNotifications.removeWhere((n) => n.id == id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete notification: ${e.toString()}');
      return false;
    }
  }
  
  // Read/Unread management
  Future<bool> markAsRead(int id) async {
    try {
      _clearError();
      await _notificationService.markAsRead(id);
      
      // Update local state
      final notification = _notifications.firstWhere((n) => n.id == id);
      final updatedNotification = notification.copyWith(isRead: true);
      
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = updatedNotification;
      }
      
      _unreadNotifications.removeWhere((n) => n.id == id);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark notification as read: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> markAsUnread(int id) async {
    try {
      _clearError();
      await _notificationService.markAsUnread(id);
      
      // Update local state
      final notification = _notifications.firstWhere((n) => n.id == id);
      final updatedNotification = notification.copyWith(isRead: false);
      
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = updatedNotification;
      }
      
      if (!_unreadNotifications.any((n) => n.id == id)) {
        _unreadNotifications.add(updatedNotification);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark notification as unread: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> markAllAsRead() async {
    try {
      _clearError();
      await _notificationService.markAllAsRead();
      
      // Update local state
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      
      _unreadNotifications.clear();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to mark all as read: ${e.toString()}');
      return false;
    }
  }
  
  // Habit notifications
  Future<bool> scheduleHabitReminder({
    required int habitId,
    required String habitName,
    required DateTime scheduledTime,
  }) async {
    if (!_settings['habit_reminders_enabled']) {
      return false; // Skip if disabled
    }
    
    try {
      _clearError();
      await _notificationService.scheduleHabitReminder(
        habitId: habitId,
        habitName: habitName,
        scheduledTime: scheduledTime,
      );
      
      await loadPendingNotifications();
      return true;
    } catch (e) {
      _setError('Failed to schedule habit reminder: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> scheduleStreakCelebration({
    required int habitId,
    required String habitName,
    required int streakCount,
  }) async {
    if (!_settings['streak_celebrations_enabled']) {
      return false; // Skip if disabled
    }
    
    try {
      _clearError();
      await _notificationService.scheduleStreakCelebration(
        habitId: habitId,
        habitName: habitName,
        streakCount: streakCount,
      );
      
      await loadNotifications();
      return true;
    } catch (e) {
      _setError('Failed to schedule streak celebration: ${e.toString()}');
      return false;
    }
  }
  
  Future<List<AppNotification>?> getHabitNotifications(int habitId) async {
    try {
      return await _notificationService.getHabitNotifications(habitId);
    } catch (e) {
      _setError('Failed to get habit notifications: ${e.toString()}');
      return null;
    }
  }
  
  Future<bool> deleteHabitNotifications(int habitId) async {
    try {
      _clearError();
      await _notificationService.deleteHabitNotifications(habitId);
      
      // Remove from local state
      _notifications.removeWhere((n) => n.habitId == habitId);
      _unreadNotifications.removeWhere((n) => n.habitId == habitId);
      _pendingNotifications.removeWhere((n) => n.habitId == habitId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete habit notifications: ${e.toString()}');
      return false;
    }
  }
  
  // Pomodoro notifications
  Future<bool> schedulePomodoroStart({
    required int pomodoroSessionId,
    required String sessionName,
    required DateTime scheduledTime,
  }) async {
    if (!_settings['pomodoro_notifications_enabled']) {
      return false; // Skip if disabled
    }
    
    try {
      _clearError();
      await _notificationService.schedulePomodoroStart(
        pomodoroSessionId: pomodoroSessionId,
        sessionName: sessionName,
        scheduledTime: scheduledTime,
      );
      
      await loadPendingNotifications();
      return true;
    } catch (e) {
      _setError('Failed to schedule Pomodoro start: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> schedulePomodoroBreak({
    required int pomodoroSessionId,
    required String sessionName,
    required bool isLongBreak,
  }) async {
    if (!_settings['pomodoro_notifications_enabled']) {
      return false; // Skip if disabled
    }
    
    try {
      _clearError();
      await _notificationService.schedulePomodoroBreak(
        pomodoroSessionId: pomodoroSessionId,
        sessionName: sessionName,
        isLongBreak: isLongBreak,
      );
      
      await loadNotifications();
      return true;
    } catch (e) {
      _setError('Failed to schedule Pomodoro break: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> schedulePomodoroComplete({
    required int pomodoroSessionId,
    required String sessionName,
    required int completedSessions,
  }) async {
    if (!_settings['pomodoro_notifications_enabled']) {
      return false; // Skip if disabled
    }
    
    try {
      _clearError();
      await _notificationService.schedulePomodoroComplete(
        pomodoroSessionId: pomodoroSessionId,
        sessionName: sessionName,
        completedSessions: completedSessions,
      );
      
      await loadNotifications();
      return true;
    } catch (e) {
      _setError('Failed to schedule Pomodoro completion: ${e.toString()}');
      return false;
    }
  }
  
  Future<List<AppNotification>?> getPomodoroNotifications(int pomodoroSessionId) async {
    try {
      return await _notificationService.getPomodoroNotifications(pomodoroSessionId);
    } catch (e) {
      _setError('Failed to get Pomodoro notifications: ${e.toString()}');
      return null;
    }
  }
  
  Future<bool> deletePomodoroNotifications(int pomodoroSessionId) async {
    try {
      _clearError();
      await _notificationService.deletePomodoroNotifications(pomodoroSessionId);
      
      // Remove from local state
      _notifications.removeWhere((n) => n.pomodoroSessionId == pomodoroSessionId);
      _unreadNotifications.removeWhere((n) => n.pomodoroSessionId == pomodoroSessionId);
      _pendingNotifications.removeWhere((n) => n.pomodoroSessionId == pomodoroSessionId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete Pomodoro notifications: ${e.toString()}');
      return false;
    }
  }
  
  // Notification processing
  void _startNotificationProcessing() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _processNotifications();
    });
  }
  
  void _stopNotificationProcessing() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }
  
  Future<void> _processNotifications() async {
    try {
      await _notificationService.processNotificationQueue();
      
      // Reload notifications after processing
      await loadNotifications();
      await loadPendingNotifications();
    } catch (e) {
      // Handle error silently for background processing
    }
  }
  
  Future<void> processNotificationQueue() async {
    await _processNotifications();
  }
  
  // Notification scheduling
  Future<bool> rescheduleNotification(int id, DateTime newScheduledTime) async {
    try {
      _clearError();
      await _notificationService.rescheduleNotification(id, newScheduledTime);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(scheduledTime: newScheduledTime);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to reschedule notification: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> snoozeNotification(int id, Duration snoozeDuration) async {
    try {
      _clearError();
      await _notificationService.snoozeNotification(id, snoozeDuration);
      
      final newScheduledTime = DateTime.now().add(snoozeDuration);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(scheduledTime: newScheduledTime);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to snooze notification: ${e.toString()}');
      return false;
    }
  }
  
  // Bulk operations
  Future<bool> deleteReadNotifications() async {
    try {
      _clearError();
      await _notificationService.deleteReadNotifications();
      
      // Remove read notifications from local state
      _notifications.removeWhere((n) => n.isRead);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete read notifications: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> deleteExpiredNotifications() async {
    try {
      _clearError();
      await _notificationService.deleteExpiredNotifications();
      
      await loadNotifications();
      await loadPendingNotifications();
      
      return true;
    } catch (e) {
      _setError('Failed to delete expired notifications: ${e.toString()}');
      return false;
    }
  }
  
  Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    try {
      await _notificationService.cleanupOldNotifications(daysToKeep: daysToKeep);
      await loadNotifications();
    } catch (e) {
      _setError('Failed to cleanup old notifications: ${e.toString()}');
    }
  }
  
  // Statistics
  Future<void> loadNotificationStats() async {
    try {
      _notificationStats = await _notificationService.getNotificationStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notification stats: ${e.toString()}');
    }
  }
  
  Future<Map<String, dynamic>?> getNotificationSummary() async {
    try {
      return await _notificationService.getNotificationSummary();
    } catch (e) {
      _setError('Failed to get notification summary: ${e.toString()}');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>?> getNotificationHistory({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _notificationService.getNotificationHistory(
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('Failed to get notification history: ${e.toString()}');
      return null;
    }
  }
  
  Future<List<AppNotification>?> getUpcomingNotifications({int hours = 24}) async {
    try {
      return await _notificationService.getUpcomingNotifications(hours: hours);
    } catch (e) {
      _setError('Failed to get upcoming notifications: ${e.toString()}');
      return null;
    }
  }
  
  // Settings management
  Future<void> loadSettings() async {
    try {
      _settings = await _notificationService.getNotificationSettings();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notification settings: ${e.toString()}');
    }
  }
  
  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      _clearError();
      await _notificationService.updateNotificationSettings(newSettings);
      _settings.addAll(newSettings);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update settings: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> updateSetting(String key, dynamic value) async {
    return await updateSettings({key: value});
  }
  
  // Smart notifications
  Future<List<String>?> getSmartNotificationSuggestions() async {
    try {
      return await _notificationService.getSmartNotificationSuggestions();
    } catch (e) {
      _setError('Failed to get suggestions: ${e.toString()}');
      return null;
    }
  }
  
  Future<bool> enableSmartNotifications() async {
    try {
      _clearError();
      await _notificationService.enableSmartNotifications();
      return true;
    } catch (e) {
      _setError('Failed to enable smart notifications: ${e.toString()}');
      return false;
    }
  }
  
  // Notification interaction
  Future<void> handleNotificationTap(int notificationId) async {
    try {
      await _notificationService.handleNotificationTap(notificationId);
      await markAsRead(notificationId);
    } catch (e) {
      _setError('Failed to handle notification tap: ${e.toString()}');
    }
  }
  
  // Search and filtering
  List<AppNotification> searchNotifications(String query) {
    if (query.trim().isEmpty) {
      return _notifications;
    }
    
    final searchTerm = query.toLowerCase().trim();
    return _notifications.where((notification) {
      return notification.title.toLowerCase().contains(searchTerm) ||
             notification.message.toLowerCase().contains(searchTerm) ||
             notification.type.toLowerCase().contains(searchTerm);
    }).toList();
  }
  
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }
  
  List<AppNotification> getNotificationsForDate(DateTime date) {
    return _notifications.where((notification) {
      final notificationDate = notification.createdAt;
      return notificationDate.day == date.day &&
             notificationDate.month == date.month &&
             notificationDate.year == date.year;
    }).toList();
  }
  
  // Utility methods
  AppNotification? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }
  
  bool isQuietHours() {
    if (!_settings['quiet_hours_enabled']) return false;
    
    final now = TimeOfDay.now();
    final startTime = _parseTimeString(_settings['quiet_hours_start']);
    final endTime = _parseTimeString(_settings['quiet_hours_end']);
    
    if (startTime.hour > endTime.hour || 
        (startTime.hour == endTime.hour && startTime.minute > endTime.minute)) {
      // Quiet hours span midnight
      return now.hour >= startTime.hour || now.hour <= endTime.hour;
    } else {
      // Normal quiet hours
      return now.hour >= startTime.hour && now.hour <= endTime.hour;
    }
  }
  
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  
  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }
  
  // Debug and testing
  Future<void> createTestNotification() async {
    await _notificationService.createTestNotification();
    await loadNotifications();
  }
  
  @override
  void dispose() {
    _stopNotificationProcessing();
    super.dispose();
  }
}