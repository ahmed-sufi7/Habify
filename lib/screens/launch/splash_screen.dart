import 'package:flutter/material.dart';
import '../intro/intro_screen.dart';

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
      // Wait for brief display duration
      await Future.delayed(const Duration(seconds: 2));
      
      // Navigate to appropriate screen
      if (mounted) {
        _navigateToNextScreen();
      }
      
    } catch (error) {
      debugPrint('Splash screen initialization error: $error');
      
      // Still navigate after a delay even if there's an error
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    // Always navigate to intro screen for now to avoid provider access issues
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const IntroScreen(),
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

