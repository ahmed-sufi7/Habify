import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/providers.dart';
import 'database/database_manager.dart';
import 'screens/launch/splash_screen.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/home/home_screen.dart';
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
        // Theme Provider (initialize first as other providers may depend on it)
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          lazy: false,
        ),
        
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
      child: Consumer2<ThemeProvider, AppSettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          return MaterialApp(
            title: 'Habify - Habit Tracker',
            debugShowCheckedModeBanner: false,
            
            // Theme configuration
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: settingsProvider.isInitialized
                ? settingsProvider.themeMode
                : ThemeMode.system,
            
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
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/intro':
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      default:
        return null;
    }
  }
}

// The SplashScreen is now imported from screens/launch/splash_screen.dart

// The IntroScreen is now imported from screens/intro/intro_screen.dart

// The MainAppScreen functionality is now handled by HomeScreen