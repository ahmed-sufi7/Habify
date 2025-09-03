import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../models/habit.dart';
import '../../widgets/calendar_widget.dart';
import '../statistics/statistics_screen.dart';

/// Home Screen - Main dashboard following home_design.json specifications
/// 
/// Features:
/// - Header with user avatar and notifications
/// - Streak card with flame icon and current streak
/// - Horizontal date timeline with completion status
/// - Habit cards with progress grid and toggle buttons
/// - Bottom navigation bar
/// - Celebration overlays on habit completion
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // Design colors from home_design.json
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color neutralMediumGray = Color(0xFF666666);
  static const Color neutralLightGray = Color(0xFFE0E0E0);
  static const Color neutralBackgroundGray = Color(0xFFF5F5F5);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentGreenLight = Color(0xFFC8E6C9);
  static const Color accentBlue = Color(0xFFE3F2FD);
  static const Color accentPurple = Color(0xFFE1BEE7);
  static const Color accentYellow = Color(0xFFF9F9C4);

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    try {
      // Wait for first frame to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        final habitProvider = Provider.of<HabitProvider>(context, listen: false);
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        final appSettingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
        
        // Initialize providers sequentially to avoid conflicts
        await habitProvider.initialize();
        if (!mounted) return;
        
        await categoryProvider.initialize();
        if (!mounted) return;
        
        await appSettingsProvider.initialize();
      });
    } catch (e) {
      // Handle initialization errors gracefully
      debugPrint('Provider initialization failed: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isToggling = false;
  
  // Cache for expensive calculations to avoid rebuilds
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCacheUpdate;
  

  Future<void> _onHabitToggle(int habitId, bool isCompleted) async {
    // Prevent multiple simultaneous toggles
    if (_isToggling || !mounted) return;
    
    _isToggling = true;
    
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      
      // Validate habitId exists
      final habit = habitProvider.todayHabits.cast<Habit?>().firstWhere(
        (h) => h?.id == habitId,
        orElse: () => null,
      );
      
      if (habit == null) {
        debugPrint('Habit with ID $habitId not found');
        return;
      }
      
      if (isCompleted) {
        final success = await habitProvider.completeHabit(habitId);
        if (!success && mounted) {
          // Show error feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to complete habit')),
          );
        }
      } else {
        final success = await habitProvider.undoHabitCompletion(habitId);
        if (!success && mounted) {
          // Show error feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to undo habit completion')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      debugPrint('Habit toggle error: $e');
    } finally {
      _isToggling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Streak card
                        _buildStreakCard(),
                        
                        // Date timeline
                        _buildDateTimeline(),
                        
                        // Habit cards section
                        _buildHabitCards(),
                        
                        const SizedBox(height: 100), // Space for floating bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating bottom navigation (positioned absolutely)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: SafeArea(
              child: _buildBottomNavigation(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu and greeting
          Row(
            children: [
              // Habify logo
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/logos/logo_black_bg.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: neutralBlack,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: neutralWhite,
                          size: 18,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Greeting
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getTimeBasedGreeting()},',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: neutralMediumGray,
                      height: 1.0,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<AppSettingsProvider>(
                    builder: (context, appSettingsProvider, child) {
                      final userName = appSettingsProvider.userName;
                      final displayName = (userName != null && userName.isNotEmpty) 
                          ? userName 
                          : 'User';
                      
                      return Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: neutralBlack,
                          letterSpacing: 0.3,
                          height: 1.0,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calendar button
              GestureDetector(
                onTap: () => _showCalendar(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: neutralWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: neutralBlack, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      'assets/icons/calendder.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Notification bell
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: neutralWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: neutralBlack, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    'assets/icons/notification-bing.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      child: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final currentStreaks = habitProvider.currentStreaks;
          final maxStreak = currentStreaks.values.isNotEmpty 
              ? currentStreaks.values.reduce((a, b) => a > b ? a : b) 
              : 0;
          final totalHabits = habitProvider.habits.length;
          final completedToday = habitProvider.todayCompletedCount;
              
          return Row(
            children: [
              // Streak Card
              Container(
                width: MediaQuery.of(context).size.width - 32,
                margin: const EdgeInsets.only(right: 8, top: 16, bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAE4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Flame icon with days
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Image.asset(
                          'assets/icons/streak-icon.png',
                          width: 100,
                          height: 100,
                        ),
                        Transform.translate(
                          offset: const Offset(0, -25),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$maxStreak',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      color: primaryOrange,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    maxStreak == 1 ? 'Day' : 'Days',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      color: primaryOrange,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Streak Score',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0x99F25D07),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    
                    // Streak info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Keep up your Streak!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: neutralBlack,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Habit Card
              Container(
                width: MediaQuery.of(context).size.width - 32,
                margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Habit icon with count
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Image.asset(
                          'assets/icons/Habit-icon.png',
                          width: 100,
                          height: 100,
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$completedToday/$totalHabits',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF63C271),
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Habit',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF63C271),
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0x9963C271),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    
                    // Habit info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Build Great Habits!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: neutralBlack,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateTimeline() {
    return Container(
      height: 88,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          // Pre-calculate base date and normalize to avoid timezone issues
          final baseDate = DateTime.now();
          final today = DateTime(baseDate.year, baseDate.month, baseDate.day);
          final dates = List.generate(14, (index) {
            return today.subtract(Duration(days: 6 - index));
          });
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            controller: ScrollController(
              initialScrollOffset: (6 * 67.0) - (MediaQuery.of(context).size.width / 2) + 33.5, // Center today
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isToday = date.isAtSameMomentAs(today);
              final isCompleted = _isDateCompleted(date, habitProvider);
              
              return Container(
                width: 55,
                height: 85,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isToday 
                      ? neutralBlack
                      : isCompleted 
                          ? primaryOrange
                          : neutralWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: isToday || isCompleted 
                      ? null 
                      : Border.all(color: neutralBlack, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isToday || isCompleted ? neutralWhite : neutralBlack,
                      ),
                    ),
                    Text(
                      _getWeekdayName(date.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isToday || isCompleted ? neutralWhite : neutralBlack,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHabitCards() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Show loading state
        if (habitProvider.isLoading) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: primaryOrange),
                  SizedBox(height: 16),
                  Text(
                    'Loading habits...',
                    style: TextStyle(
                      fontSize: 16,
                      color: neutralMediumGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Show error state
        if (habitProvider.error != null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load habits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  habitProvider.error!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: neutralMediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => habitProvider.loadHabits(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: neutralWhite,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        final todayHabits = habitProvider.todayHabits;
        
        if (todayHabits.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  size: 64,
                  color: neutralMediumGray,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No habits for today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: neutralMediumGray,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your first habit to get started!',
                  style: TextStyle(
                    fontSize: 14,
                    color: neutralMediumGray,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/add-habit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: neutralWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Add Habit'),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: todayHabits.asMap().entries.map((entry) {
            int index = entry.key;
            Habit habit = entry.value;
            return _buildHabitCard(habit, habitProvider, index);
          }).toList(),
        );
      },
    );
  }

  Widget _buildHabitCard(Habit habit, HabitProvider habitProvider, int index) {
    final isCompleted = habitProvider.isHabitCompletedToday(habit.id!);
    final currentStreak = habitProvider.getCurrentStreak(habit.id!);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/habit-details',
          arguments: habit.id,
        );
      },
      child: Container(
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

  Widget _buildBottomNavigation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = (screenWidth * 0.65).clamp(200.0, 280.0);
    
    return Center(
      child: SizedBox(
        width: navWidth,
        height: 85, // Increased to accommodate protruding button
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Navigation bar container
            Container(
              width: navWidth,
              height: 65,
              decoration: BoxDecoration(
                color: neutralBlack,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: neutralBlack.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Home button
                    IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/icons/home-active.png',
                        width: 24,
                        height: 24,
                        color: neutralWhite,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.home,
                          size: 24,
                          color: neutralWhite,
                        ),
                      ),
                    ),
                    
                    // Empty space for the protruding add button
                    const SizedBox(width: 44),
                    
                    // Statistics button
                    IconButton(
                      onPressed: () => _navigateToStatistics(),
                      icon: Image.asset(
                        'assets/icons/stats-inacative.png',
                        width: 24,
                        height: 24,
                        color: neutralWhite,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.bar_chart_outlined,
                          size: 24,
                          color: neutralWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Add button protruding above the navbar
            Positioned(
              top: 0, // Position at top of the SizedBox (protruding above navbar)
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: neutralWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: neutralBlack,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: neutralBlack.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _showAddOptionsModal(),
                  icon: const Icon(
                    Icons.add,
                    size: 26,
                    color: neutralBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHabitBackgroundColor(int index) {
    // Cycle through the three specified colors
    const colors = [
      Color(0xFFD0D7F9), // Light purple-blue
      Color(0xFFC4DBE6), // Light blue
      Color(0xFFE8D5F0), // Light lavender
    ];
    
    return colors[index % 3];
  }

  Widget _buildDynamicToggle(int habitId, bool isCompleted, int index) {
    return GestureDetector(
      onTap: () => _onHabitToggle(habitId, !isCompleted),
      onPanUpdate: (details) {
        // Handle horizontal drag to toggle
        if (details.delta.dx > 5 && !isCompleted) {
          _onHabitToggle(habitId, true);
        } else if (details.delta.dx < -5 && isCompleted) {
          _onHabitToggle(habitId, false);
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    // Normalize both dates to compare only the date part
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d1.isAtSameMomentAs(d2);
  }

  bool _isDateCompleted(DateTime date, HabitProvider habitProvider) {
    // This would check if any habits were completed on this date
    // For now, return false as we need more complex logic
    return false;
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[weekday];
  }

  String _formatTime12Hour(String timeString) {
    try {
      // Parse the time string (assuming format "HH:mm")
      final timeParts = timeString.split(':');
      if (timeParts.length != 2) return timeString;
      
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Convert to 12-hour format
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      
      return '$displayHour:$displayMinute $period';
    } catch (e) {
      return timeString; // Return original if parsing fails
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  void _navigateToStatistics() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const StatisticsScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showCalendar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: true,
      showDragHandle: false,
      useSafeArea: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.0,
          maxChildSize: 0.55,
          snap: true,
          snapSizes: const [0.0, 0.55],
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: const HabitCalendarWidget(),
            );
          },
        );
      },
    );
  }

  void _showAddOptionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: true,
      showDragHandle: false,
      useSafeArea: true,
      builder: (BuildContext context) {
        // Calculate height based on content:
        // - Drag handle: 12 (top margin) + 5 (height) = 17px
        // - Top spacing: 24px  
        // - First button: 80px (Add Pomodoro)
        // - Button spacing: 16px
        // - Second button: 60px (Add Habit)
        // - Bottom padding: 16px
        // Total: 213px + safe area padding
        const double contentHeight = 213.0;
        final double screenHeight = MediaQuery.of(context).size.height;
        final double adaptiveHeight = (contentHeight + MediaQuery.of(context).padding.bottom + 20) / screenHeight;
        
        return DraggableScrollableSheet(
          initialChildSize: adaptiveHeight,
          minChildSize: 0.0,
          maxChildSize: adaptiveHeight,
          snap: true,
          snapSizes: [0.0, adaptiveHeight],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: neutralLightGray,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Add Pomodoro button
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(); // Close modal
                            // Navigate to add pomodoro screen when implemented
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add Pomodoro feature coming soon!'),
                                backgroundColor: primaryOrange,
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF2C2C2C),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Add Pomodoro',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2C2C2C),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Add Habit button
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(); // Close modal
                            Navigator.of(context).pushNamed('/add-habit');
                          },
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: Text(
                                'Add Habit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: neutralWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16), // Bottom padding
                ],
              ),
            );
          },
        );
      },
    );
  }
}


