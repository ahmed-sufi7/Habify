import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'database/database_manager.dart';
import 'screens/launch/splash_screen.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/add_habit/add_habit_screen.dart';
import 'screens/add_pomodoro/add_pomodoro_screen.dart';
import 'screens/pomodoro_timer/pomodoro_timer_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/habit_details/habit_details_screen.dart';
import 'services/first_time_user_service.dart';
import 'services/notification_service.dart';
import 'services/pomodoro_notification_service.dart';

// Global navigation key for handling notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only initialize essential services that must be ready immediately
  
  // Initialize first-time user service (needed for splash screen routing)
  try {
    await FirstTimeUserService.initialize();
  } catch (e) {
    debugPrint('FirstTimeUserService initialization failed: $e');
  }
  
  // Set system UI overlay style (visual - should be immediate)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Start the app immediately - other services will initialize in background
  runApp(const HabifyApp());
  
  // Initialize heavy services in background after app starts
  _initializeBackgroundServices();
}

/// Initialize heavy services in background without blocking UI
void _initializeBackgroundServices() {
  // Run in background without awaiting to not block UI
  Future.microtask(() async {
    debugPrint('🔄 Starting background service initialization...');
    
    
    // Initialize database
    try {
      await DatabaseManager().initialize();
      debugPrint('✅ Database initialized successfully');
    } catch (e) {
      debugPrint('❌ Database initialization failed: $e');
    }
    
    // Initialize notifications
    try {
      await NotificationService.initialize();
      await NotificationService.requestPermissions();
      
      // Initialize Pomodoro notifications
      await PomodoroNotificationService().initialize();
      
      // Setup notification tap handler
      PomodoroNotificationService().onNotificationTapped = _handleNotificationTap;
      
      debugPrint('✅ Notification services initialized successfully');
    } catch (e) {
      debugPrint('❌ Notification service initialization failed: $e');
    }
    
    debugPrint('✅ All background services initialized!');
  });
}

// Handle notification taps for Pomodoro timer
void _handleNotificationTap(String payload) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  final parts = payload.split(':');
  if (parts.length < 3) return;

  final action = parts[0];
  final sessionId = int.tryParse(parts[1]);
  final sessionName = parts[2];

  if (sessionId == null) return;

  switch (action) {
    case 'pomodoro_timer':
    case 'pomodoro_complete':
    case 'pomodoro_finished':
      // Navigate to timer screen
      navigatorKey.currentState?.pushNamed(
        '/pomodoro-timer',
        arguments: {
          'sessionId': sessionId,
          'sessionName': sessionName,
        },
      );
      break;
  }
}

class HabifyApp extends StatefulWidget {
  const HabifyApp({super.key});

  @override
  State<HabifyApp> createState() => _HabifyAppState();
}

class _HabifyAppState extends State<HabifyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being destroyed - clear notifications
        _clearNotificationsOnAppDestroy();
        break;
      case AppLifecycleState.paused:
        // App moved to background - notifications should continue
        break;
      case AppLifecycleState.resumed:
        // App came to foreground - check if timer is still valid
        _checkTimerValidityOnResume();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning states
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }

  void _clearNotificationsOnAppDestroy() {
    try {
      PomodoroNotificationService().stopProgressNotifications();
    } catch (e) {
      debugPrint('Error clearing notifications on app destroy: $e');
    }
  }

  void _checkTimerValidityOnResume() {
    // When app resumes, check if we have any stale notifications
    // This helps clean up if the system killed the app process while in background
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final pomodoroProvider = Provider.of<PomodoroProvider>(context, listen: false);
        
        // If no active session but we might have notifications, clear them
        if (pomodoroProvider.activeSession == null || !pomodoroProvider.hasActiveTimer) {
          PomodoroNotificationService().stopProgressNotifications();
        }
      }
    } catch (e) {
      debugPrint('Error checking timer validity on resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // App Settings Provider (initialize early)
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider()..initialize(),
          lazy: false,
        ),
        
        // Category Provider (needed by Habit Provider)
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        
        // Core data providers
        ChangeNotifierProvider(
          create: (_) => HabitProvider(),
        ),
        
        ChangeNotifierProvider(
          create: (_) => PomodoroProvider(),
        ),
        
        // Statistics Provider (depends on other providers for data)
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider(),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'Habify - Habit Tracker',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            
            // Theme configuration
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            themeMode: ThemeMode.system,
            
            // Localization (if language is set in settings)
            locale: settingsProvider.isInitialized
                ? Locale(settingsProvider.language)
                : const Locale('en'),
            
            // Global route configuration
            initialRoute: '/splash',
            onGenerateRoute: _onGenerateRoute,
            routes: {
              '/': (context) => const HomeScreen(),
              '/intro': (context) => const IntroScreen(),
              '/splash': (context) => const SplashScreen(),
              '/add-habit': (context) => const AddHabitScreen(),
              '/add-pomodoro': (context) => const AddPomodoroScreen(),
              '/statistics': (context) => const StatisticsScreen(),
            },
            
            // Error handling
            builder: (context, child) {
              return MediaQuery(
                // Prevent font scaling for consistent UI
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
  
  // This method is no longer needed as navigation is handled by SplashScreen
  
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // Handle dynamic routing for app navigation
    switch (settings.name) {
      case '/':
        return _createNoAnimationRoute(const HomeScreen());
      case '/intro':
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/add-habit':
        return CupertinoPageRoute(
          builder: (_) => const AddHabitScreen(),
          fullscreenDialog: true,
        );
      case '/add-pomodoro':
        return CupertinoPageRoute(
          builder: (_) => const AddPomodoroScreen(),
          fullscreenDialog: true,
        );
      case '/statistics':
        return _createNoAnimationRoute(const StatisticsScreen());
      case '/habit-details':
        // Extract habit ID from route arguments
        final habitId = settings.arguments as int?;
        if (habitId != null) {
          return CupertinoPageRoute(
            builder: (_) => HabitDetailsScreen(habitId: habitId),
            fullscreenDialog: true,
          );
        }
        return null;
      case '/pomodoro-timer':
        // Extract session data from route arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return CupertinoPageRoute(
            builder: (_) => PomodoroTimerScreen(
              sessionId: args['sessionId'] as int,
              sessionName: args['sessionName'] as String,
            ),
            fullscreenDialog: true,
          );
        }
        return null;
      default:
        return null;
    }
  }
  
  // Create a route with no transition animation
  PageRoute _createNoAnimationRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

// The SplashScreen is now imported from screens/launch/splash_screen.dart

// The IntroScreen is now imported from screens/intro/intro_screen.dart

// The MainAppScreen functionality is now handled by HomeScreen