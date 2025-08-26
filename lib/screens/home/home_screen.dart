import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../models/habit.dart';

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  int? _celebratingHabitId;
  
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
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final appSettingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
      habitProvider.initialize();
      categoryProvider.initialize();
      appSettingsProvider.initialize();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _onHabitToggle(int habitId, bool isCompleted) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    
    if (isCompleted) {
      await habitProvider.completeHabit(habitId);
      // Trigger celebration
      setState(() {
        _celebratingHabitId = habitId;
      });
      _celebrationController.forward().then((_) {
        _celebrationController.reset();
        setState(() {
          _celebratingHabitId = null;
        });
      });
    } else {
      await habitProvider.undoHabitCompletion(habitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
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
                    
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
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
                    'assets/icons/calendder.png',
                    fit: BoxFit.contain,
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
      padding: const EdgeInsets.only(left: 24),
      child: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final currentStreaks = habitProvider.currentStreaks;
          final maxStreak = currentStreaks.values.isNotEmpty 
              ? currentStreaks.values.reduce((a, b) => a > b ? a : b) 
              : 0;
          final totalHabits = habitProvider.habits.length;
          final completedToday = habitProvider.habits.where((habit) {
            final today = DateTime.now();
            final completions = habitProvider.todayCompletionStatus;
            return completions[habit.id] == true;
          }).length;
              
          return Row(
            children: [
              // Streak Card
              Container(
                width: 320,
                margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
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
                width: 320,
                margin: const EdgeInsets.only(right: 24, top: 16, bottom: 16),
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
          final now = DateTime.now();
          final dates = List.generate(14, (index) {
            return now.subtract(Duration(days: 6 - index));
          });
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            controller: ScrollController(
              initialScrollOffset: (6 * 67.0) - (MediaQuery.of(context).size.width / 2) + 33.5, // Center today
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isToday = _isSameDay(date, now);
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
        final todayHabits = habitProvider.todayHabits;
        
        if (todayHabits.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Icon(
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
          children: todayHabits.map((habit) => _buildHabitCard(habit, habitProvider)).toList(),
        );
      },
    );
  }

  Widget _buildHabitCard(Habit habit, HabitProvider habitProvider) {
    final isCompleted = habitProvider.isHabitCompletedToday(habit.id!);
    final currentStreak = habitProvider.getCurrentStreak(habit.id!);
    final isCelebrating = _celebratingHabitId == habit.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: _getHabitBackgroundColor(habit),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
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
                      child: const Icon(
                        Icons.fitness_center,
                        size: 20,
                        color: neutralWhite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and streak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: neutralBlack,
                              letterSpacing: -0.25,
                            ),
                          ),
                          Text(
                            '$currentStreak day streak',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Toggle button
                    GestureDetector(
                      onTap: () => _onHabitToggle(habit.id!, !isCompleted),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCompleted ? neutralBlack : neutralMediumGray,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: neutralWhite,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Progress grid (7x10 dots)
                _buildProgressGrid(habit, habitProvider),
                
                const SizedBox(height: 12),
                
                // Time indicator
                Text(
                  '${habit.notificationTime} Coming!',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: primaryOrange,
                  ),
                ),
              ],
            ),
          ),
          
          // Celebration overlay
          if (isCelebrating)
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: accentGreen.withValues(alpha: 0.1 * _celebrationController.value),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: 1.0 + (0.2 * _celebrationController.value),
                      child: Opacity(
                        opacity: _celebrationController.value,
                        child: const Icon(
                          Icons.celebration,
                          size: 80,
                          color: accentGreen,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProgressGrid(Habit habit, HabitProvider habitProvider) {
    return SizedBox(
      height: 120, // 10 rows * 12px dots
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 70, // 7x10 grid
        itemBuilder: (context, index) {
          // Calculate which day this dot represents
          final now = DateTime.now();
          final dayOffset = index - 69; // Most recent dot is at index 69
          final dotDate = now.add(Duration(days: dayOffset));
          
          Color dotColor;
          if (dotDate.isAfter(now)) {
            // Future dates
            dotColor = neutralWhite.withValues(alpha: 0.7);
          } else if (_isDateCompleted(dotDate, habitProvider)) {
            // Completed dates
            dotColor = neutralBlack;
          } else {
            // Missed dates
            dotColor = neutralMediumGray;
          }
          
          return Container(
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(6),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 70,
      decoration: BoxDecoration(
        color: neutralBlack,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home button
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.home,
                size: 24,
                color: neutralWhite,
              ),
            ),
            
            // Add button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: neutralWhite,
                borderRadius: BorderRadius.circular(22),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pushNamed('/add-habit'),
                icon: const Icon(
                  Icons.add,
                  size: 28,
                  color: neutralBlack,
                ),
              ),
            ),
            
            // Statistics button
            IconButton(
              onPressed: () {
                // Navigate to statistics screen when implemented
              },
              icon: const Icon(
                Icons.bar_chart,
                size: 24,
                color: neutralWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHabitBackgroundColor(Habit habit) {
    // Map categories to colors from design
    switch (habit.categoryId) {
      case 1: // Health & Fitness
        return accentYellow;
      case 2: // Learning
        return accentBlue;
      case 3: // Social
        return accentPurple;
      case 4: // Productivity
        return accentGreenLight;
      case 5: // Mindfulness
        return const Color(0xFFFFE5E5);
      default:
        return neutralBackgroundGray;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
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
}

