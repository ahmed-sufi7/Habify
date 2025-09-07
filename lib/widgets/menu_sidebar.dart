import 'package:flutter/material.dart';

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
      duration: const Duration(milliseconds: 300),
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
    setState(() {
      _dragDistance += details.delta.dx;
      // Only allow dragging to the left (closing direction)
      if (_dragDistance > 0) _dragDistance = 0;
      
      // Update animation based on drag distance
      double dragProgress = (_dragDistance / (MediaQuery.of(context).size.width * _menuWidth)).abs().clamp(0.0, 1.0);
      _animationController.value = 1.0 - dragProgress;
    });
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
                
                // Sliding menu container
                Transform.translate(
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
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/logos/logo_black_bg.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: neutralBlack,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: neutralWhite,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // App name and tagline
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habify',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: neutralBlack,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Build Great Habits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: neutralMediumGray,
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
            icon: Icons.home,
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
            icon: Icons.bar_chart,
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
            icon: Icons.add_circle_outline,
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
            icon: Icons.timer,
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
            icon: Icons.support_agent,
            title: 'Contact Us',
            backgroundColor: const Color(0xFFDCEDFF), // Light blue
            onTap: () {
              _closeMenu();
              _showContactDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
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
              child: Icon(
                icon,
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
          // Version info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: neutralWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neutralLightGray),
            ),
            child: const Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralMediumGray,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Close button
          GestureDetector(
            onTap: _closeMenu,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: neutralWhite,
                shape: BoxShape.circle,
                border: Border.all(color: neutralBlack, width: 1.5),
              ),
              child: const Icon(
                Icons.close,
                color: neutralBlack,
                size: 18,
              ),
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
          title: const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: neutralBlack,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get in touch with the Habify team:',
                style: TextStyle(
                  fontSize: 14,
                  color: neutralMediumGray,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email, color: primaryOrange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'support@habify.app',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: neutralBlack,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.web, color: primaryOrange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'www.habify.app',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: neutralBlack,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: neutralWhite,
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
}