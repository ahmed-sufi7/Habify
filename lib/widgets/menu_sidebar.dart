import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// Menu Sidebar Widget
/// 
/// A slide-out navigation drawer that follows the design consistency
/// of home and statistics screens with the same color palette and design patterns.
/// 
/// Features:
/// - Home navigation
/// - Statistics navigation  
/// - Add Habit option
/// - Add Pomodoro option
/// - Contact Us option
/// - Consistent design with app theme
/// - Smooth sliding animation
/// - Swipe to close gesture
class MenuSidebar extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isVisible;
  
  const MenuSidebar({
    super.key,
    this.onClose,
    this.isVisible = true,
  });

  @override
  State<MenuSidebar> createState() => _MenuSidebarState();
}

class _MenuSidebarState extends State<MenuSidebar> 
    with TickerProviderStateMixin {

  // Design colors matching home and stats screens
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color neutralMediumGray = Color(0xFF666666);
  static const Color neutralLightGray = Color(0xFFE0E0E0);

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  double _dragDistance = 0.0;
  final double _menuWidth = 0.80; // 80% of screen width

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250), // Slightly faster for better responsiveness
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(MenuSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragDistance = 0.0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dx;
    // Only allow dragging to the left (closing direction)
    if (_dragDistance > 0) _dragDistance = 0;
    
    // Update animation based on drag distance without setState for better performance
    double dragProgress = (_dragDistance / (MediaQuery.of(context).size.width * _menuWidth)).abs().clamp(0.0, 1.0);
    _animationController.value = 1.0 - dragProgress;
  }

  void _handleDragEnd(DragEndDetails details) {
    double dragProgress = (_dragDistance / (MediaQuery.of(context).size.width * _menuWidth)).abs();
    double velocity = details.velocity.pixelsPerSecond.dx;
    
    // Close if dragged more than 30% or if swipe velocity is high enough
    if (dragProgress > 0.3 || velocity < -500) {
      _closeMenu();
    } else {
      // Snap back to open position
      _animationController.forward();
    }
    
    _dragDistance = 0.0;
  }

  void _closeMenu() async {
    await _animationController.reverse();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = screenWidth * _menuWidth;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: _fadeAnimation.value),
          child: SafeArea(
            child: Stack(
              children: [
                // Background tap area to close
                GestureDetector(
                  onTap: _closeMenu,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
                
                // Sliding menu container with performance optimization
                RepaintBoundary(
                  child: Transform.translate(
                    offset: Offset(_slideAnimation.value * menuWidth, 0),
                    child: GestureDetector(
                    onPanStart: _handleDragStart,
                    onPanUpdate: _handleDragUpdate,
                    onPanEnd: _handleDragEnd,
                    child: Container(
                      width: menuWidth,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA), // Same as home/stats background
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header section
                          _buildHeader(),
                          
                          const SizedBox(height: 32),
                          
                          // Menu items
                          Expanded(
                            child: _buildMenuItems(context),
                          ),
                          
                          // Footer
                          _buildFooter(),
                        ],
                      ),
                    ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Row(
        children: [
          // App logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/logos/logo_black_bg.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: neutralBlack,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: neutralWhite,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // App name and tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Habify',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: neutralBlack,
                    letterSpacing: 0,
                    height: 1.2, // Reduced line height
                  ),
                ),
                Text(
                  DateFormat('EEEE').format(DateTime.now()), // Today's day
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: neutralBlack,
                    height: 1.2, // Reduced line height
                  ),
                ),
                const SizedBox(height: 0.5),
                Text(
                  DateFormat('MMMM dd, yyyy').format(DateTime.now()), // Today's date
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: neutralMediumGray,
                    height: 1.2, // Reduced line height
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Home
          _buildMenuItem(
            iconPath: 'assets/icons/home-active.png',
            title: 'Home',
            backgroundColor: const Color(0xFFE8F5EA), // Light green
            onTap: () {
              _closeMenu();
              Navigator.of(context).pushReplacementNamed('/home');
            },
          ),
          
          const SizedBox(height: 12),
          
          // Statistics
          _buildMenuItem(
            iconPath: 'assets/icons/stats-active.png',
            title: 'Statistics',
            backgroundColor: const Color(0xFFD0D7F9), // Light purple-blue
            onTap: () {
              _closeMenu();
              Navigator.of(context).pushReplacementNamed('/statistics');
            },
          ),
          
          const SizedBox(height: 12),
          
          // Add Habit
          _buildMenuItem(
            icon: Icons.add_circle,
            title: 'Add Habit',
            backgroundColor: const Color(0xFFFFE5E5), // Light pink
            onTap: () {
              _closeMenu();
              Navigator.of(context).pushNamed('/add-habit');
            },
          ),
          
          const SizedBox(height: 12),
          
          // Add Pomodoro
          _buildMenuItem(
            iconPath: 'assets/icons/clock-icon.png',
            title: 'Add Pomodoro',
            backgroundColor: const Color(0xFFFFFBC5), // Light yellow
            onTap: () {
              _closeMenu();
              Navigator.of(context).pushNamed('/add-pomodoro');
            },
          ),
          
          const SizedBox(height: 12),
          
          // Contact Us
          _buildMenuItem(
            iconPath: 'assets/icons/contact-icon.png',
            title: 'Contact Us',
            backgroundColor: const Color(0xFFDCEDFF), // Light blue
            onTap: () {
              _showContactDialog(context); // Don't close menu
            },
          ),
          
          const SizedBox(height: 12),
          
          // Rate This App
          _buildMenuItem(
            iconPath: 'assets/icons/rate-icon.png',
            title: 'Rate This App',
            backgroundColor: const Color(0xFFC4DBE6), // Light blue-gray
            onTap: () {
              _closeMenu();
              _showRateDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    String? iconPath,
    required String title,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: neutralBlack,
                shape: BoxShape.circle,
              ),
              child: iconPath != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        iconPath,
                        width: 20,
                        height: 20,
                        color: neutralWhite,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.error,
                          color: neutralWhite,
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(
                      icon ?? Icons.star,
                      color: neutralWhite,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: neutralBlack,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.chevron_right,
              color: neutralMediumGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          const Spacer(),
          // Version info
          const Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: neutralMediumGray,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: neutralBlack,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    'assets/icons/contact-icon.png',
                    width: 18,
                    height: 18,
                    color: neutralWhite,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.support_agent,
                      color: neutralWhite,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: neutralBlack,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How can we help you today?',
                style: TextStyle(
                  fontSize: 14,
                  color: neutralMediumGray,
                ),
              ),
              const SizedBox(height: 20),
              
              // Contact Support
              _buildContactOption(
                context: context,
                icon: Icons.headset_mic,
                title: 'Contact Support',
                description: 'Get help with technical issues',
                onTap: () => _sendEmail(
                  context,
                  subject: 'Support Request - Habify App',
                  body: 'Hi Habify Team,\n\nI need help with:\n\n[Please describe your issue here]\n\nDevice: [Your device model]\nApp Version: 1.0.0\n\nThanks!',
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Send Suggestions
              _buildContactOption(
                context: context,
                icon: Icons.lightbulb_outline,
                title: 'Send Suggestions',
                description: 'Share ideas to improve the app',
                onTap: () => _sendEmail(
                  context,
                  subject: 'Feature Suggestion - Habify App',
                  body: 'Hi Habify Team,\n\nI have a suggestion for the app:\n\n[Please describe your suggestion here]\n\nThis would help because:\n[Explain the benefit]\n\nThanks for building such a great app!',
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Report a Bug
              _buildContactOption(
                context: context,
                icon: Icons.bug_report,
                title: 'Report a Bug',
                description: 'Let us know about any issues',
                onTap: () => _sendEmail(
                  context,
                  subject: 'Bug Report - Habify App',
                  body: 'Hi Habify Team,\n\nI found a bug in the app:\n\nWhat happened:\n[Describe the bug]\n\nSteps to reproduce:\n1. [First step]\n2. [Second step]\n3. [Third step]\n\nExpected result:\n[What should happen]\n\nActual result:\n[What actually happened]\n\nDevice: [Your device model]\nApp Version: 1.0.0\n\nThanks!',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: neutralLightGray,
                foregroundColor: neutralBlack,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: neutralWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: neutralLightGray),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryOrange,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: neutralBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: neutralMediumGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: neutralMediumGray,
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmail(BuildContext context, {required String subject, required String body}) async {
    // Build the mailto URL
    final String emailUrl = 'mailto:pixelwebstudio7@gmail.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    final Uri emailUri = Uri.parse(emailUrl);
    
    Navigator.of(context).pop(); // Close the dialog first
    
    try {
      // Try to launch the email app
      bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        // If launch failed, show fallback message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No email app found!'),
                  SizedBox(height: 4),
                  Text('Please email us at: pixelwebstudio7@gmail.com'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Copy Email',
                textColor: neutralWhite,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email copied: pixelwebstudio7@gmail.com'),
                      backgroundColor: Color(0xFF4CAF50),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors that occur during launch
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cannot open email app'),
                Text('Error: ${e.toString()}'),
                const SizedBox(height: 4),
                const Text('Please email us manually at: pixelwebstudio7@gmail.com'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy Email',
              textColor: neutralWhite,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email copied: pixelwebstudio7@gmail.com'),
                    backgroundColor: Color(0xFF4CAF50),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: neutralBlack,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    'assets/icons/rate-icon.png',
                    width: 18,
                    height: 18,
                    color: neutralWhite,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rate Habify',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: neutralBlack,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enjoying Habify? Help us grow by rating the app!',
                style: TextStyle(
                  fontSize: 14,
                  color: neutralMediumGray,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '⭐ Your feedback helps us improve',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: neutralBlack,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '📱 Takes just a few seconds',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: neutralBlack,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: neutralMediumGray,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Maybe Later',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Add actual rating functionality (launch store)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thanks! This would open the app store.'),
                    backgroundColor: primaryOrange,
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: neutralWhite,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Rate Now',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}