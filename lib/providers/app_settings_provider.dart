import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  // Settings keys
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _analyticsEnabledKey = 'analytics_enabled';
  static const String _crashReportingEnabledKey = 'crash_reporting_enabled';
  static const String _firstLaunchKey = 'first_launch';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _reminderTimeKey = 'default_reminder_time';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _backupFrequencyKey = 'backup_frequency';
  static const String _dataRetentionDaysKey = 'data_retention_days';
  static const String _appVersionKey = 'app_version';
  static const String _lastBackupDateKey = 'last_backup_date';
  
  // Default values
  static const ThemeMode _defaultThemeMode = ThemeMode.system;
  static const String _defaultLanguage = 'en';
  static const bool _defaultNotificationsEnabled = true;
  static const bool _defaultSoundEnabled = true;
  static const bool _defaultVibrationEnabled = true;
  static const bool _defaultAnalyticsEnabled = false;
  static const bool _defaultCrashReportingEnabled = true;
  static const bool _defaultFirstLaunch = true;
  static const bool _defaultOnboardingCompleted = false;
  static const String _defaultReminderTime = '09:00';
  static const bool _defaultAutoBackupEnabled = false;
  static const String _defaultBackupFrequency = 'weekly';
  static const int _defaultDataRetentionDays = 365;
  
  // Current settings
  ThemeMode _themeMode = _defaultThemeMode;
  String _language = _defaultLanguage;
  bool _notificationsEnabled = _defaultNotificationsEnabled;
  bool _soundEnabled = _defaultSoundEnabled;
  bool _vibrationEnabled = _defaultVibrationEnabled;
  bool _analyticsEnabled = _defaultAnalyticsEnabled;
  bool _crashReportingEnabled = _defaultCrashReportingEnabled;
  bool _firstLaunch = _defaultFirstLaunch;
  bool _onboardingCompleted = _defaultOnboardingCompleted;
  String _reminderTime = _defaultReminderTime;
  bool _autoBackupEnabled = _defaultAutoBackupEnabled;
  String _backupFrequency = _defaultBackupFrequency;
  int _dataRetentionDays = _defaultDataRetentionDays;
  String? _appVersion;
  DateTime? _lastBackupDate;
  
  // Getters
  bool get isInitialized => _isInitialized;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get crashReportingEnabled => _crashReportingEnabled;
  bool get firstLaunch => _firstLaunch;
  bool get onboardingCompleted => _onboardingCompleted;
  String get reminderTime => _reminderTime;
  bool get autoBackupEnabled => _autoBackupEnabled;
  String get backupFrequency => _backupFrequency;
  int get dataRetentionDays => _dataRetentionDays;
  String? get appVersion => _appVersion;
  DateTime? get lastBackupDate => _lastBackupDate;
  
  // Computed properties
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  TimeOfDay get reminderTimeOfDay {
    final parts = _reminderTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  
  // Available options
  static const List<String> availableLanguages = [
    'en', // English
    'es', // Spanish
    'fr', // French
    'de', // German
    'it', // Italian
    'pt', // Portuguese
    'ru', // Russian
    'ja', // Japanese
    'ko', // Korean
    'zh', // Chinese
    'ar', // Arabic
    'hi', // Hindi
  ];
  
  static const List<String> backupFrequencyOptions = [
    'daily',
    'weekly',
    'monthly',
    'never',
  ];
  
  static const List<int> dataRetentionOptions = [
    30,   // 1 month
    90,   // 3 months
    180,  // 6 months
    365,  // 1 year
    730,  // 2 years
    -1,   // Forever
  ];
  
  // Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }
  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _themeMode = ThemeMode.values[_prefs.getInt(_themeKey) ?? _defaultThemeMode.index];
    _language = _prefs.getString(_languageKey) ?? _defaultLanguage;
    _notificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? _defaultNotificationsEnabled;
    _soundEnabled = _prefs.getBool(_soundEnabledKey) ?? _defaultSoundEnabled;
    _vibrationEnabled = _prefs.getBool(_vibrationEnabledKey) ?? _defaultVibrationEnabled;
    _analyticsEnabled = _prefs.getBool(_analyticsEnabledKey) ?? _defaultAnalyticsEnabled;
    _crashReportingEnabled = _prefs.getBool(_crashReportingEnabledKey) ?? _defaultCrashReportingEnabled;
    _firstLaunch = _prefs.getBool(_firstLaunchKey) ?? _defaultFirstLaunch;
    _onboardingCompleted = _prefs.getBool(_onboardingCompletedKey) ?? _defaultOnboardingCompleted;
    _reminderTime = _prefs.getString(_reminderTimeKey) ?? _defaultReminderTime;
    _autoBackupEnabled = _prefs.getBool(_autoBackupEnabledKey) ?? _defaultAutoBackupEnabled;
    _backupFrequency = _prefs.getString(_backupFrequencyKey) ?? _defaultBackupFrequency;
    _dataRetentionDays = _prefs.getInt(_dataRetentionDaysKey) ?? _defaultDataRetentionDays;
    _appVersion = _prefs.getString(_appVersionKey);
    
    final lastBackupMillis = _prefs.getInt(_lastBackupDateKey);
    _lastBackupDate = lastBackupMillis != null ? DateTime.fromMillisecondsSinceEpoch(lastBackupMillis) : null;
  }
  
  // Theme settings
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      await _prefs.setInt(_themeKey, themeMode.index);
      notifyListeners();
    }
  }
  
  Future<void> toggleTheme() async {
    ThemeMode newTheme;
    switch (_themeMode) {
      case ThemeMode.light:
        newTheme = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newTheme = ThemeMode.system;
        break;
      case ThemeMode.system:
        newTheme = ThemeMode.light;
        break;
    }
    await setThemeMode(newTheme);
  }
  
  // Language settings
  Future<void> setLanguage(String language) async {
    if (_language != language && availableLanguages.contains(language)) {
      _language = language;
      await _prefs.setString(_languageKey, language);
      notifyListeners();
    }
  }
  
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'it': return 'Italiano';
      case 'pt': return 'Português';
      case 'ru': return 'Русский';
      case 'ja': return '日本語';
      case 'ko': return '한국어';
      case 'zh': return '中文';
      case 'ar': return 'العربية';
      case 'hi': return 'हिंदी';
      default: return languageCode.toUpperCase();
    }
  }
  
  // Notification settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled != enabled) {
      _notificationsEnabled = enabled;
      await _prefs.setBool(_notificationsEnabledKey, enabled);
      notifyListeners();
    }
  }
  
  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled != enabled) {
      _soundEnabled = enabled;
      await _prefs.setBool(_soundEnabledKey, enabled);
      notifyListeners();
    }
  }
  
  Future<void> setVibrationEnabled(bool enabled) async {
    if (_vibrationEnabled != enabled) {
      _vibrationEnabled = enabled;
      await _prefs.setBool(_vibrationEnabledKey, enabled);
      notifyListeners();
    }
  }
  
  Future<void> setReminderTime(String time) async {
    if (_reminderTime != time) {
      _reminderTime = time;
      await _prefs.setString(_reminderTimeKey, time);
      notifyListeners();
    }
  }
  
  Future<void> setReminderTimeOfDay(TimeOfDay time) async {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await setReminderTime(timeString);
  }
  
  // Privacy settings
  Future<void> setAnalyticsEnabled(bool enabled) async {
    if (_analyticsEnabled != enabled) {
      _analyticsEnabled = enabled;
      await _prefs.setBool(_analyticsEnabledKey, enabled);
      notifyListeners();
    }
  }
  
  Future<void> setCrashReportingEnabled(bool enabled) async {
    if (_crashReportingEnabled != enabled) {
      _crashReportingEnabled = enabled;
      await _prefs.setBool(_crashReportingEnabledKey, enabled);
      notifyListeners();
    }
  }
  
  // App lifecycle settings
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    if (_firstLaunch != isFirstLaunch) {
      _firstLaunch = isFirstLaunch;
      await _prefs.setBool(_firstLaunchKey, isFirstLaunch);
      notifyListeners();
    }
  }
  
  Future<void> setOnboardingCompleted(bool completed) async {
    if (_onboardingCompleted != completed) {
      _onboardingCompleted = completed;
      await _prefs.setBool(_onboardingCompletedKey, completed);
      notifyListeners();
    }
  }
  
  Future<void> markFirstLaunchComplete() async {
    await setFirstLaunch(false);
  }
  
  Future<void> markOnboardingComplete() async {
    await setOnboardingCompleted(true);
  }
  
  // Backup settings
  Future<void> setAutoBackupEnabled(bool enabled) async {
    if (_autoBackupEnabled != enabled) {
      _autoBackupEnabled = enabled;
      await _prefs.setBool(_autoBackupEnabledKey, enabled);
      notifyListeners();
    }
  }
  
  Future<void> setBackupFrequency(String frequency) async {
    if (_backupFrequency != frequency && backupFrequencyOptions.contains(frequency)) {
      _backupFrequency = frequency;
      await _prefs.setString(_backupFrequencyKey, frequency);
      notifyListeners();
    }
  }
  
  Future<void> setLastBackupDate(DateTime date) async {
    _lastBackupDate = date;
    await _prefs.setInt(_lastBackupDateKey, date.millisecondsSinceEpoch);
    notifyListeners();
  }
  
  String getBackupFrequencyDisplayName(String frequency) {
    switch (frequency) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      case 'never': return 'Never';
      default: return frequency.toUpperCase();
    }
  }
  
  // Data retention settings
  Future<void> setDataRetentionDays(int days) async {
    if (_dataRetentionDays != days && (dataRetentionOptions.contains(days) || days > 0)) {
      _dataRetentionDays = days;
      await _prefs.setInt(_dataRetentionDaysKey, days);
      notifyListeners();
    }
  }
  
  String getDataRetentionDisplayName(int days) {
    switch (days) {
      case 30: return '1 Month';
      case 90: return '3 Months';
      case 180: return '6 Months';
      case 365: return '1 Year';
      case 730: return '2 Years';
      case -1: return 'Forever';
      default: return '$days Days';
    }
  }
  
  // App version tracking
  Future<void> setAppVersion(String version) async {
    if (_appVersion != version) {
      _appVersion = version;
      await _prefs.setString(_appVersionKey, version);
      notifyListeners();
    }
  }
  
  // Backup scheduling helpers
  bool shouldBackupToday() {
    if (!_autoBackupEnabled || _lastBackupDate == null) {
      return _autoBackupEnabled;
    }
    
    final now = DateTime.now();
    final daysSinceLastBackup = now.difference(_lastBackupDate!).inDays;
    
    switch (_backupFrequency) {
      case 'daily':
        return daysSinceLastBackup >= 1;
      case 'weekly':
        return daysSinceLastBackup >= 7;
      case 'monthly':
        return daysSinceLastBackup >= 30;
      case 'never':
        return false;
      default:
        return false;
    }
  }
  
  // Reset settings
  Future<void> resetToDefaults() async {
    await Future.wait([
      setThemeMode(_defaultThemeMode),
      setLanguage(_defaultLanguage),
      setNotificationsEnabled(_defaultNotificationsEnabled),
      setSoundEnabled(_defaultSoundEnabled),
      setVibrationEnabled(_defaultVibrationEnabled),
      setAnalyticsEnabled(_defaultAnalyticsEnabled),
      setCrashReportingEnabled(_defaultCrashReportingEnabled),
      setReminderTime(_defaultReminderTime),
      setAutoBackupEnabled(_defaultAutoBackupEnabled),
      setBackupFrequency(_defaultBackupFrequency),
      setDataRetentionDays(_defaultDataRetentionDays),
    ]);
    
    // Don't reset first launch and onboarding completed flags
  }
  
  Future<void> resetPrivacySettings() async {
    await Future.wait([
      setAnalyticsEnabled(false),
      setCrashReportingEnabled(false),
    ]);
  }
  
  Future<void> resetNotificationSettings() async {
    await Future.wait([
      setNotificationsEnabled(_defaultNotificationsEnabled),
      setSoundEnabled(_defaultSoundEnabled),
      setVibrationEnabled(_defaultVibrationEnabled),
      setReminderTime(_defaultReminderTime),
    ]);
  }
  
  // Import/Export settings
  Map<String, dynamic> exportSettings() {
    return {
      'theme_mode': _themeMode.index,
      'language': _language,
      'notifications_enabled': _notificationsEnabled,
      'sound_enabled': _soundEnabled,
      'vibration_enabled': _vibrationEnabled,
      'analytics_enabled': _analyticsEnabled,
      'crash_reporting_enabled': _crashReportingEnabled,
      'reminder_time': _reminderTime,
      'auto_backup_enabled': _autoBackupEnabled,
      'backup_frequency': _backupFrequency,
      'data_retention_days': _dataRetentionDays,
      'app_version': _appVersion,
      'last_backup_date': _lastBackupDate?.millisecondsSinceEpoch,
      'export_date': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['theme_mode'] != null) {
        await setThemeMode(ThemeMode.values[settings['theme_mode']]);
      }
      if (settings['language'] != null) {
        await setLanguage(settings['language']);
      }
      if (settings['notifications_enabled'] != null) {
        await setNotificationsEnabled(settings['notifications_enabled']);
      }
      if (settings['sound_enabled'] != null) {
        await setSoundEnabled(settings['sound_enabled']);
      }
      if (settings['vibration_enabled'] != null) {
        await setVibrationEnabled(settings['vibration_enabled']);
      }
      if (settings['analytics_enabled'] != null) {
        await setAnalyticsEnabled(settings['analytics_enabled']);
      }
      if (settings['crash_reporting_enabled'] != null) {
        await setCrashReportingEnabled(settings['crash_reporting_enabled']);
      }
      if (settings['reminder_time'] != null) {
        await setReminderTime(settings['reminder_time']);
      }
      if (settings['auto_backup_enabled'] != null) {
        await setAutoBackupEnabled(settings['auto_backup_enabled']);
      }
      if (settings['backup_frequency'] != null) {
        await setBackupFrequency(settings['backup_frequency']);
      }
      if (settings['data_retention_days'] != null) {
        await setDataRetentionDays(settings['data_retention_days']);
      }
      if (settings['app_version'] != null) {
        await setAppVersion(settings['app_version']);
      }
      if (settings['last_backup_date'] != null) {
        await setLastBackupDate(DateTime.fromMillisecondsSinceEpoch(settings['last_backup_date']));
      }
    } catch (e) {
      // Handle import errors gracefully
      debugPrint('Error importing settings: $e');
    }
  }
  
  // Debug helpers
  void printCurrentSettings() {
    debugPrint('Current App Settings:');
    debugPrint('Theme Mode: $_themeMode');
    debugPrint('Language: $_language');
    debugPrint('Notifications Enabled: $_notificationsEnabled');
    debugPrint('Sound Enabled: $_soundEnabled');
    debugPrint('Vibration Enabled: $_vibrationEnabled');
    debugPrint('Analytics Enabled: $_analyticsEnabled');
    debugPrint('Crash Reporting Enabled: $_crashReportingEnabled');
    debugPrint('First Launch: $_firstLaunch');
    debugPrint('Onboarding Completed: $_onboardingCompleted');
    debugPrint('Reminder Time: $_reminderTime');
    debugPrint('Auto Backup Enabled: $_autoBackupEnabled');
    debugPrint('Backup Frequency: $_backupFrequency');
    debugPrint('Data Retention Days: $_dataRetentionDays');
    debugPrint('App Version: $_appVersion');
    debugPrint('Last Backup Date: $_lastBackupDate');
  }
  
  // Clear all settings (for testing or reset)
  Future<void> clearAllSettings() async {
    await _prefs.clear();
    await _loadSettings();
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}