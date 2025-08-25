import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage first-time user detection and app initialization state
class FirstTimeUserService {
  // Keys for SharedPreferences
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyAppVersion = 'app_version';
  static const String _keyLastLaunchDate = 'last_launch_date';
  static const String _keyInitializationComplete = 'initialization_complete';
  
  // Current app version (should match pubspec.yaml)
  static const String _currentVersion = '1.0.0';
  
  static SharedPreferences? _prefs;
  
  /// Initialize the service and SharedPreferences
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _checkAndUpdateVersion();
    } catch (error) {
      throw Exception('Failed to initialize FirstTimeUserService: $error');
    }
  }
  
  /// Check if this is the first time the user is launching the app
  static bool isFirstTimeUser() {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    return _prefs!.getBool(_keyFirstLaunch) ?? true;
  }
  
  /// Mark the first launch as complete
  static Future<void> markFirstLaunchComplete() async {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    await _prefs!.setBool(_keyFirstLaunch, false);
    await _updateLastLaunchDate();
  }
  
  /// Check if onboarding/intro screens have been completed
  static bool isOnboardingCompleted() {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    return _prefs!.getBool(_keyOnboardingCompleted) ?? false;
  }
  
  /// Mark onboarding as completed
  static Future<void> markOnboardingComplete() async {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    await _prefs!.setBool(_keyOnboardingCompleted, true);
  }
  
  /// Reset onboarding status (for testing or user preference)
  static Future<void> resetOnboarding() async {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    await _prefs!.setBool(_keyOnboardingCompleted, false);
  }
  
  /// Check if app initialization is complete
  static bool isInitializationComplete() {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    return _prefs!.getBool(_keyInitializationComplete) ?? false;
  }
  
  /// Mark app initialization as complete
  static Future<void> markInitializationComplete() async {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    await _prefs!.setBool(_keyInitializationComplete, true);
    await _updateLastLaunchDate();
  }
  
  /// Get the stored app version
  static String? getStoredVersion() {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    return _prefs!.getString(_keyAppVersion);
  }
  
  /// Get the last launch date
  static DateTime? getLastLaunchDate() {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    final dateString = _prefs!.getString(_keyLastLaunchDate);
    if (dateString != null) {
      return DateTime.tryParse(dateString);
    }
    return null;
  }
  
  /// Check if this is a new app version
  static bool isNewVersion() {
    final storedVersion = getStoredVersion();
    return storedVersion != _currentVersion;
  }
  
  /// Get comprehensive user status
  static UserStatus getUserStatus() {
    return UserStatus(
      isFirstTime: isFirstTimeUser(),
      isOnboardingCompleted: isOnboardingCompleted(),
      isInitializationComplete: isInitializationComplete(),
      isNewVersion: isNewVersion(),
      storedVersion: getStoredVersion(),
      currentVersion: _currentVersion,
      lastLaunchDate: getLastLaunchDate(),
    );
  }
  
  /// Reset all user data (for testing or factory reset)
  static Future<void> resetAllUserData() async {
    if (_prefs == null) {
      throw StateError('FirstTimeUserService not initialized. Call initialize() first.');
    }
    
    await _prefs!.remove(_keyFirstLaunch);
    await _prefs!.remove(_keyOnboardingCompleted);
    await _prefs!.remove(_keyAppVersion);
    await _prefs!.remove(_keyLastLaunchDate);
    await _prefs!.remove(_keyInitializationComplete);
  }
  
  /// Check and update version information
  static Future<void> _checkAndUpdateVersion() async {
    if (_prefs == null) return;
    
    final storedVersion = _prefs!.getString(_keyAppVersion);
    
    if (storedVersion == null || storedVersion != _currentVersion) {
      await _prefs!.setString(_keyAppVersion, _currentVersion);
      
      // If this is a version upgrade (not first install), we might want to
      // show a changelog or migration screen
      if (storedVersion != null && storedVersion != _currentVersion) {
        // This is an app update, not a first install
        // We might want to trigger update-specific logic here
      }
    }
  }
  
  /// Update the last launch date to current time
  static Future<void> _updateLastLaunchDate() async {
    if (_prefs == null) return;
    
    await _prefs!.setString(
      _keyLastLaunchDate,
      DateTime.now().toIso8601String(),
    );
  }
  
  /// Get debug information for troubleshooting
  static Map<String, dynamic> getDebugInfo() {
    if (_prefs == null) {
      return {'error': 'Service not initialized'};
    }
    
    return {
      'isFirstTime': isFirstTimeUser(),
      'isOnboardingCompleted': isOnboardingCompleted(),
      'isInitializationComplete': isInitializationComplete(),
      'storedVersion': getStoredVersion(),
      'currentVersion': _currentVersion,
      'isNewVersion': isNewVersion(),
      'lastLaunchDate': getLastLaunchDate()?.toIso8601String(),
    };
  }
}

/// Data class to hold user status information
class UserStatus {
  final bool isFirstTime;
  final bool isOnboardingCompleted;
  final bool isInitializationComplete;
  final bool isNewVersion;
  final String? storedVersion;
  final String currentVersion;
  final DateTime? lastLaunchDate;
  
  UserStatus({
    required this.isFirstTime,
    required this.isOnboardingCompleted,
    required this.isInitializationComplete,
    required this.isNewVersion,
    required this.storedVersion,
    required this.currentVersion,
    this.lastLaunchDate,
  });
  
  @override
  String toString() {
    return 'UserStatus('
        'isFirstTime: $isFirstTime, '
        'isOnboardingCompleted: $isOnboardingCompleted, '
        'isInitializationComplete: $isInitializationComplete, '
        'isNewVersion: $isNewVersion, '
        'storedVersion: $storedVersion, '
        'currentVersion: $currentVersion, '
        'lastLaunchDate: $lastLaunchDate'
        ')';
  }
}