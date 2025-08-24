import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'providers/providers.dart';
import 'database/database_manager.dart';
import 'utils/provider_initialization_helper.dart';

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
            
            // Home page with provider initialization wrapper
            home: ProviderInitializer(
              child: _getHomePage(settingsProvider),
              loadingWidget: const SplashScreen(),
            ),
            
            // Global route configuration (for future navigation)
            onGenerateRoute: _onGenerateRoute,
            
            // Error handling
            builder: (context, child) {
              return MediaQuery(
                // Prevent font scaling for consistent UI
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _getHomePage(AppSettingsProvider settingsProvider) {
    // Show splash screen while initializing
    if (!settingsProvider.isInitialized) {
      return const SplashScreen();
    }
    
    // Show intro screen for first time users
    if (settingsProvider.firstLaunch || !settingsProvider.onboardingCompleted) {
      return const IntroScreen();
    }
    
    // Show main app
    return const MainAppScreen();
  }
  
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    // This will be expanded later when we implement navigation
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainAppScreen());
      case '/intro':
        return MaterialPageRoute(builder: (_) => const IntroScreen());
      default:
        return null;
    }
  }
}

// Temporary splash screen while providers initialize
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B35), // Primary orange
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Color(0xFFFF6B35),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App name
            const Text(
              'Habify',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Tagline
            const Text(
              'Build Better Habits',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder intro screen
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Habify!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Your journey to better habits starts here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () {
                // Mark onboarding as completed
                context.read<AppSettingsProvider>().markOnboardingComplete();
                context.read<AppSettingsProvider>().markFirstLaunchComplete();
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder main app screen
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habify'),
        actions: [
          // Theme toggle button
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                onPressed: themeProvider.toggleTheme,
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
              );
            },
          ),
        ],
      ),
      
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          if (habitProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (habitProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${habitProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: habitProvider.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Show empty state or habit list
          if (habitProvider.habits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No habits yet!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first habit to get started.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          // Show habit list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: habitProvider.habits.length,
            itemBuilder: (context, index) {
              final habit = habitProvider.habits[index];
              final isCompleted = habitProvider.isHabitCompletedToday(habit.id!);
              final currentStreak = habitProvider.getCurrentStreak(habit.id!);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    habit.name,
                    style: TextStyle(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'Streak: $currentStreak days',
                    style: TextStyle(
                      color: currentStreak > 0
                          ? const Color(0xFFFF6B35)
                          : Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      if (isCompleted) {
                        habitProvider.undoHabitCompletion(habit.id!);
                      } else {
                        habitProvider.completeHabit(habit.id!);
                      }
                    },
                    icon: Icon(
                      isCompleted ? Icons.undo : Icons.check,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add habit screen
          _showAddHabitDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      
      // Bottom navigation placeholder
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Pomodoro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
  
  void _showAddHabitDialog(BuildContext context) {
    // Simple add habit dialog for testing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Habit'),
        content: const Text('This feature will be implemented in the next steps.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}