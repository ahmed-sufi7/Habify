import 'package:flutter/material.dart';
import '../intro/intro_screen.dart';
import '../home/home_screen.dart';
import '../../services/first_time_user_service.dart';

/// Simple splash screen with centered logo on white background
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Start user status check immediately
      final startTime = DateTime.now();
      
      // Check user status quickly
      bool isNewUser = false;
      try {
        // Ensure service is initialized (should be from main.dart)
        if (!FirstTimeUserService.isServiceInitialized()) {
          await FirstTimeUserService.initialize();
        }
        
        isNewUser = FirstTimeUserService.isFirstTimeUser() || 
                   !FirstTimeUserService.isOnboardingCompleted();
      } catch (error) {
        debugPrint('User status check error: $error');
        // Default to new user on error
        isNewUser = true;
      }
      
      // For new users, show splash very briefly (300ms)  
      // For returning users, show splash briefly (800ms)
      final targetDelay = isNewUser 
          ? const Duration(milliseconds: 300) 
          : const Duration(milliseconds: 800);
      
      final elapsed = DateTime.now().difference(startTime);
      final remainingDelay = targetDelay - elapsed;
      
      if (remainingDelay.inMilliseconds > 0) {
        await Future.delayed(remainingDelay);
      }
      
      if (mounted) {
        _navigateToNextScreen();
      }
      
    } catch (error) {
      debugPrint('Splash screen initialization error: $error');
      
      // Quick fallback navigation for any errors
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    try {
      // Check if user is first-time or onboarding not completed
      final isFirstTime = FirstTimeUserService.isFirstTimeUser();
      final isOnboardingCompleted = FirstTimeUserService.isOnboardingCompleted();
      
      Widget destinationScreen;
      
      if (isFirstTime || !isOnboardingCompleted) {
        // Show intro screen for first-time users or users who haven't completed onboarding
        destinationScreen = const IntroScreen();
      } else {
        // Show home screen for returning users
        destinationScreen = const HomeScreen();
      }
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destinationScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (error) {
      debugPrint('Navigation error: $error');
      // Fallback to home screen if there's an error
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logos/logo_white_bg.png',
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image fails to load
            return Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: const Icon(
                Icons.apps,
                size: 60,
                color: Colors.black,
              ),
            );
          },
        ),
      ),
    );
  }
}

