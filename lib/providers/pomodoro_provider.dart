import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/pomodoro_session.dart';
import '../models/pomodoro_completion.dart';
import '../services/database/pomodoro_service.dart';

enum TimerState {
  idle,
  running,
  paused,
  completed,
  cancelled,
}

enum SessionType {
  work,
  shortBreak,
  longBreak,
}

class PomodoroProvider extends ChangeNotifier {
  final PomodoroService _pomodoroService = PomodoroService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // State variables
  List<PomodoroSession> _sessions = [];
  PomodoroSession? _activeSession;
  PomodoroCompletion? _currentCompletion;
  Timer? _timer;
  
  // Timer state
  TimerState _timerState = TimerState.idle;
  SessionType _currentSessionType = SessionType.work;
  int _currentSessionNumber = 1;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isLongBreak = false;
  
  // UI state
  bool _isLoading = false;
  String? _error;
  
  // Statistics
  Map<String, dynamic>? _todayStats;
  Map<String, dynamic>? _overallStats;
  List<Map<String, dynamic>>? _weeklyStats;
  
  // Getters
  List<PomodoroSession> get sessions => _sessions;
  List<PomodoroSession> get activeSessions => _sessions.where((s) => s.isActive).toList();
  PomodoroSession? get activeSession => _activeSession;
  PomodoroCompletion? get currentCompletion => _currentCompletion;
  
  TimerState get timerState => _timerState;
  SessionType get currentSessionType => _currentSessionType;
  int get currentSessionNumber => _currentSessionNumber;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get elapsedSeconds => _totalSeconds - _remainingSeconds;
  bool get isLongBreak => _isLongBreak;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Map<String, dynamic>? get todayStats => _todayStats;
  Map<String, dynamic>? get overallStats => _overallStats;
  List<Map<String, dynamic>>? get weeklyStats => _weeklyStats;
  
  // Computed properties
  bool get isRunning => _timerState == TimerState.running;
  bool get isPaused => _timerState == TimerState.paused;
  bool get isIdle => _timerState == TimerState.idle;
  bool get isCompleted => _timerState == TimerState.completed;
  bool get hasActiveTimer => _timerState == TimerState.running || _timerState == TimerState.paused;
  
  double get progress => _totalSeconds > 0 ? elapsedSeconds / _totalSeconds : 0.0;
  String get formattedTime => _formatTime(_remainingSeconds);
  String get formattedElapsedTime => _formatTime(elapsedSeconds);
  
  // Session info
  String get currentSessionTitle => _activeSession?.name ?? 'No Session';
  String get currentSessionDescription {
    if (_activeSession == null) return 'Select a session to start';
    
    switch (_currentSessionType) {
      case SessionType.work:
        return 'Work Session $_currentSessionNumber';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }
  
  // Initialize provider
  Future<void> initialize() async {
    await Future.wait([
      loadSessions(),
      loadCurrentSession(),
      loadStats(),
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
  
  // Session management
  Future<void> loadSessions() async {
    try {
      _setLoading(true);
      _clearError();
      _sessions = await _pomodoroService.getActiveSessions();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sessions: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load a specific session for display in timer screen
  Future<void> loadSessionForDisplay(int sessionId) async {
    try {
      _clearError();
      final session = await _pomodoroService.getSessionById(sessionId);
      if (session != null) {
        _activeSession = session;
        // Initialize timer state for new session
        _currentSessionNumber = 1;
        _currentSessionType = SessionType.work;
        _totalSeconds = session.workDurationMinutes * 60;
        _remainingSeconds = _totalSeconds;
        _timerState = TimerState.idle;
        _isLongBreak = false;
        notifyListeners();
      } else {
        _setError('Session not found');
      }
    } catch (e) {
      _setError('Failed to load session: ${e.toString()}');
    }
  }
  
  Future<int?> createSession({
    required String name,
    int workDurationMinutes = 25,
    int shortBreakMinutes = 5,
    int longBreakMinutes = 15,
    int sessionsCount = 4,
    bool notificationEnabled = true,
    bool alarmEnabled = false,
    String? description,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final sessionId = await _pomodoroService.createPomodoroSession(
        name: name,
        workDurationMinutes: workDurationMinutes,
        shortBreakMinutes: shortBreakMinutes,
        longBreakMinutes: longBreakMinutes,
        sessionsCount: sessionsCount,
        notificationEnabled: notificationEnabled,
        alarmEnabled: alarmEnabled,
        description: description,
      );
      
      await loadSessions();
      return sessionId;
    } catch (e) {
      _setError('Failed to create session: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> updateSession(PomodoroSession session) async {
    try {
      _clearError();
      await _pomodoroService.updatePomodoroSession(session);
      
      // Update local state
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session;
        if (_activeSession?.id == session.id) {
          _activeSession = session;
        }
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update session: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> deleteSession(int sessionId) async {
    try {
      _clearError();
      
      // Don't delete if it's the active session with a running timer
      if (_activeSession?.id == sessionId && hasActiveTimer) {
        throw ArgumentError('Cannot delete session with active timer');
      }
      
      await _pomodoroService.deletePomodoroSession(sessionId);
      
      // Remove from local state
      _sessions.removeWhere((session) => session.id == sessionId);
      
      // Clear active session if it was deleted
      if (_activeSession?.id == sessionId) {
        _activeSession = null;
        _stopTimer();
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete session: ${e.toString()}');
      return false;
    }
  }
  
  // Timer control
  Future<bool> startWorkSession(int sessionId, {int sessionNumber = 1}) async {
    try {
      _clearError();
      
      final result = await _pomodoroService.startWorkSession(sessionId, sessionNumber: sessionNumber);
      
      _activeSession = result['session'] as PomodoroSession;
      _currentSessionNumber = sessionNumber;
      _currentSessionType = SessionType.work;
      _isLongBreak = false;
      
      _totalSeconds = _activeSession!.workDurationMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _timerState = TimerState.running;
      
      _startTimer();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start work session: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> startBreakSession(int sessionId, int sessionNumber, bool isLongBreak) async {
    try {
      _clearError();
      
      final result = await _pomodoroService.startBreakSession(sessionId, sessionNumber, isLongBreak);
      
      _activeSession = result['session'] as PomodoroSession;
      _currentSessionNumber = sessionNumber;
      _currentSessionType = isLongBreak ? SessionType.longBreak : SessionType.shortBreak;
      _isLongBreak = isLongBreak;
      
      final breakDuration = isLongBreak 
          ? _activeSession!.longBreakMinutes 
          : _activeSession!.shortBreakMinutes;
      
      _totalSeconds = breakDuration * 60;
      _remainingSeconds = _totalSeconds;
      _timerState = TimerState.running;
      
      _startTimer();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start break session: ${e.toString()}');
      return false;
    }
  }
  
  void pauseTimer() {
    if (_timerState == TimerState.running) {
      _stopTimer();
      _timerState = TimerState.paused;
      notifyListeners();
    }
  }
  
  void resumeTimer() {
    if (_timerState == TimerState.paused) {
      _timerState = TimerState.running;
      _startTimer();
      notifyListeners();
    }
  }
  
  void resetTimer() {
    _stopTimer();
    _timerState = TimerState.idle;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  // Simple timer start for loaded sessions (doesn't create database session)
  void startLoadedTimer() {
    if (_activeSession != null && _timerState == TimerState.idle) {
      _timerState = TimerState.running;
      _startTimer();
      notifyListeners();
    }
  }

  // Simple timer stop for loaded sessions (doesn't affect database)
  void stopLoadedTimer() {
    _stopTimer();
    _timerState = TimerState.idle;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  // Terminate the current session completely (clears active session)
  void terminateCurrentSession() {
    _stopTimer();
    _timerState = TimerState.idle;
    _activeSession = null;
    _currentCompletion = null;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    _currentSessionNumber = 1;
    _currentSessionType = SessionType.work;
    _isLongBreak = false;
    notifyListeners();
  }

  // Update session type and duration for next session
  void moveToNextSession(SessionType sessionType, bool isLongBreak, [int? sessionNumber]) {
    if (_activeSession == null) return;
    
    _currentSessionType = sessionType;
    _isLongBreak = isLongBreak;
    if (sessionNumber != null) {
      _currentSessionNumber = sessionNumber;
    }
    
    // Set duration based on session type
    switch (sessionType) {
      case SessionType.work:
        _totalSeconds = _activeSession!.workDurationMinutes * 60;
        break;
      case SessionType.shortBreak:
        _totalSeconds = _activeSession!.shortBreakMinutes * 60;
        break;
      case SessionType.longBreak:
        _totalSeconds = _activeSession!.longBreakMinutes * 60;
        break;
    }
    
    _remainingSeconds = _totalSeconds;
    _timerState = TimerState.idle;
    notifyListeners();
  }
  
  Future<bool> completeCurrentSession() async {
    try {
      _clearError();
      
      await _pomodoroService.completeCurrentSession();
      
      _stopTimer();
      _timerState = TimerState.completed;
      
      // Load updated stats
      await loadStats();
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to complete session: ${e.toString()}');
      return false;
    }
  }
  
  Future<bool> cancelCurrentSession({String? notes}) async {
    try {
      _clearError();
      
      await _pomodoroService.cancelCurrentSession(notes: notes);
      
      _stopTimer();
      _timerState = TimerState.cancelled;
      _activeSession = null;
      _currentCompletion = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to cancel session: ${e.toString()}');
      return false;
    }
  }
  
  // Timer private methods
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Timer completed
        _timerCompleted();
      }
    });
  }
  
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
  
  void _timerCompleted() {
    _stopTimer();
    _timerState = TimerState.completed;
    notifyListeners();
    
    // Play completion sound
    _playCompletionSound();
    
    // Don't auto-complete database session, just mark as completed locally
    // Let the UI handle showing next session dialog
  }
  
  // Play completion sound
  Future<void> _playCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/completion_chime.mp3'));
    } catch (e) {
      // Handle audio playback error silently
      debugPrint('Error playing completion sound: $e');
    }
  }
  
  // Current session management
  Future<void> loadCurrentSession() async {
    try {
      final currentSessionData = await _pomodoroService.getCurrentSession();
      
      if (currentSessionData != null) {
        _currentCompletion = currentSessionData['completion'] as PomodoroCompletion;
        _activeSession = currentSessionData['session'] as PomodoroSession;
        _remainingSeconds = currentSessionData['remaining_seconds'] as int;
        _totalSeconds = currentSessionData['total_seconds'] as int;
        
        // Set session type and number based on completion data
        if (_currentCompletion!.isWorkSession) {
          _currentSessionType = SessionType.work;
        } else if (_currentCompletion!.isLongBreak) {
          _currentSessionType = SessionType.longBreak;
        } else {
          _currentSessionType = SessionType.shortBreak;
        }
        
        _currentSessionNumber = _currentCompletion!.sessionNumber;
        _isLongBreak = _currentCompletion!.isLongBreak;
        _timerState = TimerState.running;
        
        _startTimer();
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load current session: ${e.toString()}');
    }
  }
  
  // Statistics
  Future<void> loadStats() async {
    try {
      final todayData = await _pomodoroService.getPomodorosDashboardData();
      _todayStats = todayData;
      
      _overallStats = await _pomodoroService.getOverallPomodoroStats();
      _weeklyStats = await _pomodoroService.getDailyStats(7);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load stats: ${e.toString()}');
    }
  }
  
  // Session queries
  Future<List<PomodoroSession>> searchSessions(String query) async {
    try {
      return await _pomodoroService.searchSessions(query);
    } catch (e) {
      _setError('Failed to search sessions: ${e.toString()}');
      return [];
    }
  }
  
  PomodoroSession? getSessionById(int id) {
    try {
      return _sessions.firstWhere((session) => session.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Preset sessions
  Future<List<PomodoroSession>> getPresetSessions() async {
    try {
      return await _pomodoroService.getPresetSessions();
    } catch (e) {
      _setError('Failed to get preset sessions: ${e.toString()}');
      return [];
    }
  }
  
  Future<int?> createSessionFromPreset(String presetName) async {
    try {
      final sessionId = await _pomodoroService.createSessionFromPreset(presetName);
      await loadSessions();
      return sessionId;
    } catch (e) {
      _setError('Failed to create session from preset: ${e.toString()}');
      return null;
    }
  }
  
  // Recommendations
  Future<Map<String, dynamic>?> getNextRecommendedAction(int sessionId) async {
    try {
      return await _pomodoroService.getNextRecommendedAction(sessionId);
    } catch (e) {
      _setError('Failed to get recommendation: ${e.toString()}');
      return null;
    }
  }
  
  // Activity history
  Future<List<Map<String, dynamic>>?> getActivityHistory({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _pomodoroService.getActivityHistory(
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('Failed to get activity history: ${e.toString()}');
      return null;
    }
  }
  
  // Productivity insights
  Future<Map<String, dynamic>?> getProductivityInsights(int daysBack) async {
    try {
      return await _pomodoroService.getProductivityInsights(daysBack);
    } catch (e) {
      _setError('Failed to get productivity insights: ${e.toString()}');
      return null;
    }
  }
  
  // Session statistics
  Future<Map<String, dynamic>?> getSessionStats(int sessionId) async {
    try {
      return await _pomodoroService.getSessionStats(sessionId);
    } catch (e) {
      _setError('Failed to get session stats: ${e.toString()}');
      return null;
    }
  }
  
  // Data management
  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    try {
      await _pomodoroService.cleanupOldData(daysToKeep: daysToKeep);
    } catch (e) {
      _setError('Failed to cleanup old data: ${e.toString()}');
    }
  }
  
  Future<Map<String, dynamic>?> exportSessionData(int sessionId) async {
    try {
      return await _pomodoroService.exportSessionData(sessionId);
    } catch (e) {
      _setError('Failed to export session data: ${e.toString()}');
      return null;
    }
  }
  
  // Utility methods
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }
  
  // Quick actions
  Future<bool> startQuickSession({int minutes = 25}) async {
    // Create a temporary session for quick starts
    final sessionId = await createSession(
      name: 'Quick Session',
      workDurationMinutes: minutes,
    );
    
    if (sessionId != null) {
      return await startWorkSession(sessionId);
    }
    
    return false;
  }
  
  // Session templates
  Map<String, Map<String, dynamic>> getSessionTemplates() {
    return {
      'Classic Pomodoro': {
        'work': 25,
        'short_break': 5,
        'long_break': 15,
        'sessions': 4,
        'description': 'The traditional 25-minute Pomodoro technique',
      },
      'Extended Focus': {
        'work': 45,
        'short_break': 10,
        'long_break': 30,
        'sessions': 4,
        'description': 'Longer sessions for deep work',
      },
      'Short Bursts': {
        'work': 15,
        'short_break': 5,
        'long_break': 15,
        'sessions': 6,
        'description': 'Quick sessions for busy schedules',
      },
      'Deep Work': {
        'work': 90,
        'short_break': 20,
        'long_break': 60,
        'sessions': 3,
        'description': 'Long sessions for complex tasks',
      },
    };
  }
  
  @override
  void dispose() {
    _stopTimer();
    _audioPlayer.dispose();
    super.dispose();
  }
}