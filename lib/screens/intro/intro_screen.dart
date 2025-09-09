import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form controllers for user info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  // Animation controllers for smooth button feedback
  late AnimationController _getStartedButtonController;
  late AnimationController _completeButtonController;
  late Animation<double> _getStartedButtonScale;
  late Animation<double> _completeButtonScale;

  // Design color palette
  static const Color primaryDark = Color(0xFF000000);
  static const Color primaryBlue = Color(0xFF4A5FBD);
  static const Color accentBlue = Color(0xFFC8D4F0);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _getStartedButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _completeButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _getStartedButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _getStartedButtonController, curve: Curves.easeInOut),
    );
    _completeButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _completeButtonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _getStartedButtonController.dispose();
    _completeButtonController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep < 1) {
      // Add button press animation
      await _getStartedButtonController.forward();
      await _getStartedButtonController.reverse();
      
      setState(() {
        _currentStep++;
      });
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }


  void _completeSetup() async {
    // Add button press animation
    await _completeButtonController.forward();
    await _completeButtonController.reverse();
    
    // Validate inputs
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    
    // Validate name (required)
    if (name.isEmpty) {
      _showErrorDialog('Please enter your name to continue');
      return;
    }
    
    if (name.length < 2) {
      _showErrorDialog('Name must be at least 2 characters long');
      return;
    }
    
    if (name.length > 50) {
      _showErrorDialog('Name must be less than 50 characters');
      return;
    }
    
    // Validate age input
    if (ageText.isNotEmpty) {
      final age = int.tryParse(ageText);
      if (age == null || age < 1 || age > 120) {
        _showErrorDialog('Please enter a valid age between 1 and 120');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save user data
      final settingsProvider = context.read<AppSettingsProvider>();
      await settingsProvider.setUserName(name);
      if (_selectedGender != null) {
        await settingsProvider.setUserGender(_selectedGender!);
      }
      if (ageText.isNotEmpty) {
        final age = int.tryParse(ageText);
        if (age != null && age >= 1 && age <= 120) {
          await settingsProvider.setUserAge(age);
        }
      }

      // Mark onboarding as completed
      await FirstTimeUserService.markOnboardingComplete();
      await FirstTimeUserService.markFirstLaunchComplete();
      await settingsProvider.markOnboardingComplete();
      await settingsProvider.markFirstLaunchComplete();

      // Navigate to add habit screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/add-habit');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Something went wrong. Please try again.');
    }
  }

  void _showGenderPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...['Male', 'Female', 'Other', 'Prefer not to say'].map(
                  (gender) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedGender = gender;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedGender == gender ? primaryDark : white,
                        foregroundColor: _selectedGender == gender ? white : textPrimary,
                        elevation: 0,
                        side: BorderSide(
                          color: _selectedGender == gender ? primaryDark : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        gender,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundLight,
        resizeToAvoidBottomInset: false, // Prevent keyboard from resizing the screen
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildWelcomeScreen(), _buildUserInfoForm()],
        ),
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
                      'Build small habits, achieve big changes with Habify',
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
                      'Create positive habits every day, stay consistent, track your progress, and stay motivated with reminders and insights.',
                      style: TextStyle(
                        fontSize: 16, //increase from 14
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action button - only Get Started button with animation
                  AnimatedBuilder(
                    animation: _getStartedButtonScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _getStartedButtonScale.value,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C2C2C),
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
                      );
                    },
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
      child: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
            // Logo section
            SizedBox(
              height: 70,
              child: Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logos/logo_black_bg.png',
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 65,
                          height: 65,
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
            ),
            const SizedBox(height: 16),

            // Progress section
            const Text(
              'Let\'s get started with Habify!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 48),

            // Form fields
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
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
                    maxLength: 50,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color:
                          textPrimary, // Dark text color for contrast with white background
                    ),
                    decoration: InputDecoration(
                      counterText: '', // Hide character counter
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
                          color: Color(0xFF000000),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF000000),
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
                  GestureDetector(
                    onTap: _showGenderPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: white,
                        border: Border.all(
                          color: const Color(0xFF000000),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedGender ?? 'Select your gender',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: _selectedGender != null ? textPrimary : textSecondary,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: textPrimary,
                          ),
                        ],
                      ),
                    ),
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
                    maxLength: 3,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color:
                          textPrimary, // Dark text color for contrast with white background
                    ),
                    decoration: InputDecoration(
                      counterText: '', // Hide character counter
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
                          color: Color(0xFF000000),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF000000),
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
            const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        // Fixed button at bottom
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child:
            AnimatedBuilder(
              animation: _completeButtonScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _completeButtonScale.value,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? textSecondary : const Color(0xFF2C2C2C),
                        foregroundColor: white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(white),
                              ),
                            )
                          : const Text(
                              'Start my First Habit',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                );
              },
            ),
        ),
        ],
      ),
    );
  }
}
