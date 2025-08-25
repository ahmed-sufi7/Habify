import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/first_time_user_service.dart';

/// IntroScreen - Multi-step introduction flow
///
/// Implements the complete intro flow:
/// 1. Welcome Screen - App introduction with Get Started button
/// 2. User Info Form - Name, gender, age collection 
///
/// Uses local storage to save user data
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  PageController _pageController = PageController();
  int _currentStep = 0;

  // Form controllers for user info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  // Design color palette
  static const Color primaryDark = Color(0xFF2D2D2D);
  static const Color primaryBlue = Color(0xFF4A5FBD);
  static const Color accentBlue = Color(0xFFC8D4F0);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundPurple = Color(0xFFD4CFED);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToMain() {
    // Skip to main app without additional setup
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _completeSetup() async {
    // Save user data locally and complete the setup process
    try {
      // Save user data
      final settingsProvider = context.read<AppSettingsProvider>();
      if (_nameController.text.isNotEmpty) {
        await settingsProvider.setUserName(_nameController.text.trim());
      }
      if (_selectedGender != null) {
        await settingsProvider.setUserGender(_selectedGender!);
      }
      if (_ageController.text.isNotEmpty) {
        final age = int.tryParse(_ageController.text);
        if (age != null) {
          await settingsProvider.setUserAge(age);
        }
      }
      
      // Mark onboarding as completed
      await FirstTimeUserService.markOnboardingComplete();
      await FirstTimeUserService.markFirstLaunchComplete();
      await settingsProvider.markOnboardingComplete();
      await settingsProvider.markFirstLaunchComplete();

      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      // Handle error - for now just navigate to home
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildWelcomeScreen(),
          _buildUserInfoForm(),
        ],
      ),
    );
  }

  /// Welcome Screen - First screen with app introduction
  Widget _buildWelcomeScreen() {
    return SafeArea(
      child: Column(
        children: [
          // Header with logo and title - Mobile header at top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo from assets - Smaller 40x40 circle for mobile
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logos/logo_black_bg.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.self_improvement,
                            color: white,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title text with Expanded to prevent overflow
                const Expanded(
                  child: Text(
                    'Welcome to Habify!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),

          // Main content with padding
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Illustration section
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/illustrations/reading.png',
                        height: 320,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 320,
                            width: 320,
                            decoration: BoxDecoration(
                              color: accentBlue.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(160),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 140,
                              color: primaryDark,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Content section with smaller font sizes
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Small habits, create big changes with Habify',
                      style: TextStyle(
                        fontSize: 18, // increase from 16
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Build a positive routine every day, achieving your life goals in a consistent and enjoyable way.',
                      style: TextStyle(
                        fontSize: 16, //increase from 14
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Action button - only Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryDark,
                        foregroundColor: white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// User Info Form - Collect basic user information
  Widget _buildUserInfoForm() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            // Header with skip button and logo
            Stack(
              children: [
                // Centered logo
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logos/logo_black_bg.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: primaryDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.self_improvement,
                              color: white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Skip button positioned at top right
                Positioned(
                  top: 0,
                  right: 0,
                  child: TextButton(
                    onPressed: _skipToMain,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Progress section
            const Text(
              'Two steps to get started a Habit!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 48),

            // Form fields
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: textPrimary, // Dark text color for contrast with white background
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                      filled: true,
                      fillColor: white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: borderLight,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: borderLight,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Gender (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: textPrimary, // Dark text color for contrast with purple background
                    ),
                    dropdownColor: backgroundPurple, // Match the field background color
                    icon: Container(
                      margin: const EdgeInsets.only(right: 8), // Center the arrow better
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 24,
                      ),
                    ),
                    isExpanded: true, // Ensure dropdown fills the container width
                    decoration: InputDecoration(
                      hintText: 'Enter your gender',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                      filled: true,
                      fillColor: backgroundPurple,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    items: ['Male', 'Female', 'Other', 'Prefer not to say']
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(
                              gender,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: textPrimary, // Dark text in dropdown items
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Age (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: textPrimary, // Dark text color for contrast with white background
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your age',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                      filled: true,
                      fillColor: white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: borderLight,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: borderLight,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  foregroundColor: white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create First Habit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}