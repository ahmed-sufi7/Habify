import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

/// Helper class to manage provider initialization order and dependencies
class ProviderInitializationHelper {
  static bool _isInitializing = false;
  static bool _isInitialized = false;
  
  /// Initialize providers in the correct order with proper dependency management
  static Future<void> initializeProviders(BuildContext context) async {
    if (_isInitializing || _isInitialized) return;
    
    _isInitializing = true;
    
    try {
      // Phase 1: Initialize core providers (Theme, App Settings)
      await _initializeCoreProviders(context);
      
      // Phase 2: Initialize data providers (Categories first, then others)
      await _initializeDataProviders(context);
      
      // Phase 3: Initialize dependent providers (Statistics)
      await _initializeDependentProviders(context);
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Provider initialization error: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Initialize core providers that don't depend on data
  static Future<void> _initializeCoreProviders(BuildContext context) async {
    // Theme Provider - already initialized in provider tree
    
    // App Settings Provider - already initialized in provider tree
    final appSettingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
    if (!appSettingsProvider.isInitialized) {
      await appSettingsProvider.initialize();
    }
  }
  
  /// Initialize data providers in dependency order
  static Future<void> _initializeDataProviders(BuildContext context) async {
    try {
      // Categories first (required by Habits)
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.initialize();
      
      // Habits (depends on categories)
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await habitProvider.initialize();
      
      // Pomodoro (independent)
      final pomodoroProvider = Provider.of<PomodoroProvider>(context, listen: false);
      await pomodoroProvider.initialize();
      
      // Note: Notification provider removed - using simple notification service instead
      
    } catch (e) {
      debugPrint('Data provider initialization error: $e');
      rethrow;
    }
  }
  
  /// Initialize providers that depend on other data providers
  static Future<void> _initializeDependentProviders(BuildContext context) async {
    try {
      // Statistics (depends on all other data providers)
      final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
      await statisticsProvider.initialize();
      
    } catch (e) {
      debugPrint('Dependent provider initialization error: $e');
      rethrow;
    }
  }
  
  /// Check if a specific provider is ready
  static bool isProviderReady<T extends ChangeNotifier>(BuildContext context) {
    try {
      final provider = Provider.of<T>(context, listen: false);
      
      if (provider is HabitProvider) {
        return !provider.isLoading && provider.error == null;
      } else if (provider is CategoryProvider) {
        return !provider.isLoading && provider.error == null;
      } else if (provider is PomodoroProvider) {
        return !provider.isLoading && provider.error == null;
      } else if (provider is StatisticsProvider) {
        return !provider.isLoading && provider.error == null;
      } else if (provider is AppSettingsProvider) {
        return provider.isInitialized;
      }
      
      return true;
    } catch (e) {
      debugPrint('Provider readiness check error: $e');
      return false;
    }
  }
  
  /// Check if all critical providers are ready
  static bool areAllProvidersReady(BuildContext context) {
    return isProviderReady<AppSettingsProvider>(context) &&
           isProviderReady<CategoryProvider>(context) &&
           isProviderReady<HabitProvider>(context) &&
           isProviderReady<PomodoroProvider>(context);
  }
  
  /// Refresh all providers
  static Future<void> refreshAllProviders(BuildContext context) async {
    try {
      final providers = [
        Provider.of<CategoryProvider>(context, listen: false),
        Provider.of<HabitProvider>(context, listen: false),
        Provider.of<PomodoroProvider>(context, listen: false),
        Provider.of<StatisticsProvider>(context, listen: false),
      ];
      
      // Providers are automatically initialized, no need to call refresh
    } catch (e) {
      debugPrint('Provider refresh error: $e');
      rethrow;
    }
  }
  
  /// Reset initialization state (for testing or app restart)
  static void reset() {
    _isInitializing = false;
    _isInitialized = false;
  }
  
  /// Get initialization status
  static bool get isInitialized => _isInitialized;
  static bool get isInitializing => _isInitializing;
}

/// Widget that ensures providers are initialized before building its child
class ProviderInitializer extends StatefulWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  
  const ProviderInitializer({
    Key? key,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key);
  
  @override
  State<ProviderInitializer> createState() => _ProviderInitializerState();
}

class _ProviderInitializerState extends State<ProviderInitializer> {
  bool _isInitialized = false;
  bool _hasError = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }
  
  Future<void> _initializeProviders() async {
    try {
      await ProviderInitializationHelper.initializeProviders(context);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _error = e.toString();
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultError();
    }
    
    if (!_isInitialized) {
      return widget.loadingWidget ?? _buildDefaultLoading();
    }
    
    return widget.child;
  }
  
  Widget _buildDefaultLoading() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing app...'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefaultError() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Initialization Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializeProviders();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}