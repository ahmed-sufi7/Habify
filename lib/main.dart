import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

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

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Handle Firebase initialization error gracefully
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Initialize database
  try {
    await DatabaseManager().initialize();
  } catch (e) {
    debugPrint('Database initialization failed: $e');
    // Continue with app startup even if database fails
  }
  
  // Initialize first-time user service
  try {
    await FirstTimeUserService.initialize();
  } catch (e) {
    debugPrint('FirstTimeUserService initialization failed: $e');
    // Continue with app startup even if service fails
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const HabifyApp());
}

class HabifyApp extends StatelessWidget {
  const HabifyApp({super.key});

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
        
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
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
        return MaterialPageRoute(builder: (_) => const AddHabitScreen());
      case '/add-pomodoro':
        return MaterialPageRoute(builder: (_) => const AddPomodoroScreen());
      case '/statistics':
        return _createNoAnimationRoute(const StatisticsScreen());
      case '/habit-details':
        // Extract habit ID from route arguments
        final habitId = settings.arguments as int?;
        if (habitId != null) {
          return MaterialPageRoute(
            builder: (_) => HabitDetailsScreen(habitId: habitId),
          );
        }
        return null;
      case '/pomodoro-timer':
        // Extract session data from route arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => PomodoroTimerScreen(
              sessionId: args['sessionId'] as int,
              sessionName: args['sessionName'] as String,
            ),
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