import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import 'edit_habit_screen.dart';

/// Habit Details Screen - Shows detailed information about a specific habit
/// Following the design specification from Habit_details.json
/// 
/// Features:
/// - Hero image illustration  
/// - Category tags
/// - Time schedule section
/// - Streak tracking card with calendar grid
/// - Goals section with statistics
/// - Description section
/// - App bar with back navigation and more options
class HabitDetailsScreen extends StatefulWidget {
  final int habitId;

  const HabitDetailsScreen({
    super.key,
    required this.habitId,
  });

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  // Design colors from Habit_details.json
  static const Color primaryBackground = Color(0xFFFFFFFF);
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color darkGray = Color(0xFF2C2C2C);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color neutralWhite = Color(0xFFFFFFFF);

  Habit? _habit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabitDetails();
  }

  void _loadHabitDetails() async {
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final habit = habitProvider.getHabitById(widget.habitId);
      
      setState(() {
        _habit = habit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading habit details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: primaryBackground,
        body: const Center(
          child: CircularProgressIndicator(
            color: primaryOrange,
          ),
        ),
      );
    }

    if (_habit == null) {
      return Scaffold(
        backgroundColor: primaryBackground,
        appBar: AppBar(
          backgroundColor: primaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: darkGray, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Habit Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: neutralBlack,
              letterSpacing: -0.2,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Habit not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Section
                    _buildHeroSection(),
                    
                    const SizedBox(height: 12),
                    
                    // Category Tags
                    _buildCategoryTags(),
                    
                    const SizedBox(height: 28),
                    
                    // Time Section
                    _buildTimeSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Streak Card
                    _buildStreakCard(),
                    
                    const SizedBox(height: 20),
                    
                    // Goals Section
                    _buildGoalsSection(),
                    
                    const SizedBox(height: 8),
                    
                    // Description Section (only if description exists)
                    if (_habit!.description.isNotEmpty) ...[
                      _buildDescriptionSection(),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: darkGray, size: 16),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            _habit?.name ?? 'Habit Details',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: neutralBlack,
              letterSpacing: -0.2,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: darkGray,
              size: 18,
            ),
            onPressed: () {
              // Show more options menu
              _showMoreOptionsMenu();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/illustrations/reading.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 80,
                color: mediumGray,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTags() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // Category tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD0D7F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Category: ${_getCategoryName(_habit!.categoryId)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: neutralBlack,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Priority tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFC4DBE6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Priority: ${_habit!.priority}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: neutralBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Time icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: darkGray,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/icons/calendder.png',
                width: 24,
                height: 24,
                color: neutralWhite,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Time content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'At ${_formatTime12Hour(_habit!.notificationTime)} for ${_habit!.durationMinutes} ${_habit!.durationMinutes == 1 ? 'minute' : 'minutes'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  _habit!.repetitionPattern,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: mediumGray,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Use the complete habit card from home screen
        return _buildHabitCard(_habit!, habitProvider, 0);
      },
    );
  }

  Widget _buildHabitCard(Habit habit, HabitProvider habitProvider, int index) {
    final isCompleted = habitProvider.isHabitCompletedToday(habit.id!);
    final currentStreak = habitProvider.getCurrentStreak(habit.id!);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getHabitBackgroundColor(index),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header row
          Row(
            children: [
              // Habit icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: neutralBlack,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _getHabitIcon(habit),
              ),
              const SizedBox(width: 8),
              
              // Title and streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: neutralBlack,
                        letterSpacing: 0,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Streak display
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(24, 0),
                    child: Text(
                      '$currentStreak',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: primaryOrange,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(14, 0),
                    child: Image.asset(
                      'assets/icons/streak-icon.png',
                      width: 60,
                      height: 60,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress grid (7x10 dots)
          _buildProgressGrid(habit, habitProvider),
          
          const SizedBox(height: 18),
          
          // Bottom row with time and toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time indicator
              Text(
                '${_formatTime12Hour(habit.notificationTime)} Reminder',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryOrange,
                ),
              ),
              
              // Dynamic sliding toggle button
              _buildDynamicToggle(habit.id!, isCompleted, index),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressGrid(Habit habit, HabitProvider habitProvider) {
    // Pre-calculate base date to avoid repeated DateTime.now() calls
    final baseDate = DateTime.now();
    final today = DateTime(baseDate.year, baseDate.month, baseDate.day);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 16,
        childAspectRatio: 1,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: 64, // 16x4 grid
      itemBuilder: (context, index) {
        // Calculate how many days since habit creation
        final daysSinceHabitCreation = today.difference(DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day)).inDays;
        
        // Only show dots for days that have passed since habit creation
        if (index > daysSinceHabitCreation) {
          // Future date - show empty/inactive dot
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }
        
        // Calculate which date this dot represents (progressive from habit start)
        final dotDate = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day).add(Duration(days: index));
        
        // Check if habit should show on this date
        if (!habit.shouldShowOnDate(dotDate)) {
          // Habit wasn't scheduled for this date - use neutral color
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }
        
        // For active dates, use FutureBuilder to check completion status
        return FutureBuilder<bool>(
          future: index == daysSinceHabitCreation 
              ? Future.value(habitProvider.isHabitCompletedToday(habit.id!))
              : habitProvider.isHabitCompletedOnDate(habit.id!, dotDate),
          builder: (context, snapshot) {
            Color dotColor;
            
            if (snapshot.hasData && snapshot.data!) {
              // Habit was completed on this date
              dotColor = neutralBlack;
            } else {
              // Habit was not completed on this date (or loading)
              dotColor = const Color(0xFFFAFAFA);
            }
            
            return Container(
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildGoalsSection() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getHabitStatistics(habitProvider),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final stats = snapshot.data!;
            final completedCount = stats['completed_count'] as int;
            final missedCount = stats['missed_count'] as int;
            final longestStreak = stats['longest_streak'] as int;
            final completionRate = stats['completion_rate'] as double;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Goal items
              _buildGoalItem('assets/icons/habit-completed.png', 'Habit Completed', '$completedCount'),
              _buildGoalItem('assets/icons/habit-missed.png', 'Habit Missed', '$missedCount'),
              _buildGoalItem('assets/icons/streak-category.png', 'Longest Streak', '$longestStreak'),
              _buildGoalItem('assets/icons/completed-today.png', 'Completion Rate', '${completionRate.toStringAsFixed(0)}%'),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildGoalItem(String iconPath, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: darkGray,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: neutralWhite,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkGray,
                ),
              ),
            ],
          ),
          
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: neutralBlack,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: darkGray,
            ),
          ),
          
          const SizedBox(height: 6),
          
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _habit!.description,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: mediumGray,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Habit'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditHabit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Habit', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Delete Habit',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Are you sure you want to delete "${_habit!.name}"? This action cannot be undone.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _deleteHabit();
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteHabit() async {
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final habitName = _habit!.name;
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Deleting habit...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Delete the habit
      final success = await habitProvider.deleteHabit(_habit!.id!);
      
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (success) {
          // Navigate back to home screen first
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$habitName deleted successfully')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Failed to delete habit. Please try again.')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () => _showDeleteConfirmation(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Clear loading snackbar
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Show detailed error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Error deleting habit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$e', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Color _getHabitBackgroundColor(int index) {
    // Cycle through the three specified colors
    const colors = [
      Color(0xFFD0D7F9), // Light purple-blue
      Color(0xFFC4DBE6), // Light blue
      Color(0xFFFFFBC5), // Light yellow
    ];
    
    return colors[index % 3];
  }

  Widget _getHabitIcon(Habit habit) {
    switch (habit.categoryId) {
      case 1: // Health & Fitness
        return const Icon(
          Icons.fitness_center,
          size: 20,
          color: neutralWhite,
        );
      case 2: // Learning
        return const Icon(Icons.school, size: 20, color: neutralWhite);
      case 3: // Social
        return const Icon(Icons.people, size: 20, color: neutralWhite);
      case 4: // Productivity
        return const Icon(Icons.work, size: 20, color: neutralWhite);
      case 5: // Mindfulness
        return const Icon(Icons.self_improvement, size: 20, color: neutralWhite);
      default: // Other
        return const Icon(Icons.star, size: 20, color: neutralWhite);
    }
  }

  Widget _buildDynamicToggle(int habitId, bool isCompleted, int index) {
    return GestureDetector(
      onTap: () => _onHabitToggle(habitId, !isCompleted, index),
      onPanUpdate: (details) {
        // Handle horizontal drag to toggle
        if (details.delta.dx > 5 && !isCompleted) {
          _onHabitToggle(habitId, true, index);
        } else if (details.delta.dx < -5 && isCompleted) {
          _onHabitToggle(habitId, false, index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: 120,
        height: 36,
        decoration: BoxDecoration(
          color: isCompleted ? neutralBlack : _getHabitBackgroundColor(index),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: neutralBlack,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Text positioned opposite to scroller
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: isCompleted ? 8 : 31,
              right: isCompleted ? 36 : 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? neutralWhite : neutralBlack,
                    letterSpacing: 0,
                  ),
                  child: Text(
                    isCompleted ? 'Completed' : 'Complete',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Sliding circle with correct positioning
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: isCompleted ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isCompleted ? neutralWhite : neutralBlack,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: neutralBlack.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.close,
                  size: 16,
                  color: isCompleted ? neutralBlack : neutralWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onHabitToggle(int habitId, bool isCompleted, int index) async {
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      
      if (isCompleted) {
        await habitProvider.completeHabit(habitId);
      } else {
        await habitProvider.undoHabitCompletion(habitId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      debugPrint('Habit toggle error: $e');
    }
  }

  String _getCategoryName(int categoryId) {
    switch (categoryId) {
      case 1:
        return 'Health & Fitness';
      case 2:
        return 'Learning';
      case 3:
        return 'Social';
      case 4:
        return 'Productivity';
      case 5:
        return 'Mindfulness';
      default:
        return 'Other';
    }
  }

  Future<Map<String, dynamic>> _getHabitStatistics(HabitProvider habitProvider) async {
    final completedCount = await habitProvider.getHabitCompletedCount(_habit!.id!);
    final missedCount = await habitProvider.getHabitMissedCount(_habit!.id!);
    final longestStreak = await habitProvider.getLongestStreak(_habit!.id!);
    final completionRate = await habitProvider.getCompletionRate(_habit!.id!);
    
    return {
      'completed_count': completedCount,
      'missed_count': missedCount,
      'longest_streak': longestStreak,
      'completion_rate': completionRate,
    };
  }

  String _formatTime12Hour(String timeString) {
    try {
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) return timeString;
      
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      
      return '$displayHour:$displayMinute $period';
    } catch (e) {
      return timeString;
    }
  }

  void _navigateToEditHabit() async {
    if (_habit == null) return;
    
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (context) => EditHabitScreen(habit: _habit!),
      ),
    );
    
    if (result != null && result['success'] == true) {
      // Reload habit details after successful edit
      _loadHabitDetails();
      
      // Show success message
      if (mounted && result['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(result['message'])),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}