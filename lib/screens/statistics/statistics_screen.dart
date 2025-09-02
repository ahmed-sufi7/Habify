import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/calendar_widget.dart';

enum StatisticsViewType { weekly, monthly, yearly }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Design colors from home_design.json for consistency
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color neutralMediumGray = Color(0xFF666666);
  static const Color neutralLightGray = Color(0xFFE0E0E0);

  // View navigation state
  StatisticsViewType _viewType = StatisticsViewType.weekly;
  DateTime _selectedWeek = DateTime.now();
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
        await statisticsProvider.initialize();
      });
    } catch (e) {
      debugPrint('Statistics provider initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
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
                        // Statistics cards
                        _buildStatisticsCards(),
                        
                        // Statistics chart
                        _buildStatisticsChart(),
                        
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
          // Menu and title
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
                          Icons.bar_chart,
                          color: neutralWhite,
                          size: 18,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Title
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: neutralBlack,
                      letterSpacing: 0.3,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Action buttons
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

  Widget _buildStatisticsCards() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final totalHabits = habitProvider.habits.length;
        final completedToday = habitProvider.todayCompletedCount;
        final longestStreak = habitProvider.longestStreak;
        final averageStreak = habitProvider.averageStreak;
        final completionRate = habitProvider.todayCompletionRate;
        final totalMissed = habitProvider.totalMissedHabits;
        final totalCompleted = habitProvider.totalCompletedHabits;
        final consistencyScore = habitProvider.overallConsistencyScore;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              // Top row - Total habits and Completed today
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Habits',
                      value: '$totalHabits',
                      backgroundColor: const Color(0xFFD0D7F9),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/habit-category.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Completed Today',
                      value: '$completedToday/$totalHabits',
                      backgroundColor: const Color(0xFFF9DCF8),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/completed-today.png',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Second row - Longest streak and Average streak
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Longest Streak',
                      value: '$longestStreak days',
                      backgroundColor: const Color(0xFFFFFBC5),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/streak-category.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Average Streak',
                      value: '${averageStreak.toStringAsFixed(1)} days',
                      backgroundColor: const Color(0xFFC4DBE6),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/average-streak.png',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Third row - Habits completed and Habits missed
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Habits Completed',
                      value: '$totalCompleted',
                      backgroundColor: const Color(0xFFEED8FF),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/habit-completed.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Habits Missed',
                      value: '$totalMissed',
                      backgroundColor: const Color(0xFFD0D7F9),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/habit-missed.png',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Fourth row - Completion rate and Consistency score
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Today\'s Rate',
                      value: '${completionRate.toStringAsFixed(0)}%',
                      backgroundColor: const Color(0xFFFFE5E5),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/todays-rate.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Consistency Score',
                      value: '${consistencyScore.toStringAsFixed(0)}%',
                      backgroundColor: const Color(0xFFDCEDFF),
                      valueColor: neutralBlack,
                      iconPath: 'assets/icons/consistency-score.png',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color backgroundColor,
    required Color valueColor,
    required String iconPath,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title in one line
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  iconPath,
                  fit: BoxFit.contain,
                  color: neutralBlack,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: neutralBlack,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Value below
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: neutralBlack,
              letterSpacing: -0.25,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompactViewToggle() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: neutralWhite.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(21),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = constraints.maxWidth / 3;
          return Stack(
            children: [
              // Animated background indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _getIndicatorPosition() * buttonWidth,
                top: 0,
                child: Container(
                  width: buttonWidth,
                  height: 42,
                  decoration: BoxDecoration(
                    color: neutralBlack,
                    borderRadius: BorderRadius.circular(21),
                  ),
                ),
              ),
              // Toggle buttons
              Row(
                children: [
                  _buildCompactToggleButton('Weekly', StatisticsViewType.weekly, 0),
                  _buildCompactToggleButton('Monthly', StatisticsViewType.monthly, 1),
                  _buildCompactToggleButton('Yearly', StatisticsViewType.yearly, 2),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactToggleButton(String title, StatisticsViewType viewType, int index) {
    final isSelected = _viewType == viewType;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _viewType = viewType;
          });
        },
        child: Container(
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? neutralWhite : neutralBlack.withValues(alpha: 0.7),
                letterSpacing: -0.25,
              ),
              child: Text(title),
            ),
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition() {
    switch (_viewType) {
      case StatisticsViewType.weekly:
        return 0.0;
      case StatisticsViewType.monthly:
        return 1.0;
      case StatisticsViewType.yearly:
        return 2.0;
    }
  }

  String _getChartTitle() {
    switch (_viewType) {
      case StatisticsViewType.weekly:
        return 'Weekly Progress';
      case StatisticsViewType.monthly:
        return 'Monthly Progress';
      case StatisticsViewType.yearly:
        return 'Yearly Progress';
    }
  }

  Widget _buildStatisticsChart() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEED8FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background illustration positioned bottom right (70% visible)
                Positioned(
                  bottom: -70,
                  right: -70,
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Image.asset(
                      'assets/illustrations/leaf.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              
                // Main card content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and navigation
                      Row(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: const BoxDecoration(
                              color: neutralBlack,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              'assets/icons/stats-active.png',
                              fit: BoxFit.contain,
                              color: neutralWhite,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getChartTitle(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: neutralBlack,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ),
                          // Navigation arrows
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: neutralWhite.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 16,
                                  onPressed: () {
                                    setState(() {
                                      _navigatePrevious();
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: neutralBlack,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: neutralWhite.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 16,
                                  onPressed: () {
                                    setState(() {
                                      _navigateNext();
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: neutralBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Week range and score
                      _buildWeekInfo(habitProvider),
                      
                      const SizedBox(height: 20),
                      
                      // Weekly completion pattern chart
                      _buildWeeklyChart(habitProvider),
                      
                      const SizedBox(height: 16),
                      
                      // View toggle buttons
                      _buildCompactViewToggle(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildWeekInfo(HabitProvider habitProvider) {
    String dateRange;
    String periodLabel;
    Map<String, double> data;
    double score;
    
    switch (_viewType) {
      case StatisticsViewType.weekly:
        final startOfWeek = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        dateRange = '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}';
        periodLabel = _isCurrentWeek() ? 'This Week' : _getWeekLabel();
        data = habitProvider.getWeeklyCompletionPattern(_selectedWeek);
        score = data.values.fold(0.0, (sum, value) => sum + value) / data.length * 100;
        break;
      
      case StatisticsViewType.monthly:
        dateRange = '${_formatMonth(_selectedMonth)} ${_selectedMonth.year}';
        periodLabel = _isCurrentMonth() ? 'This Month' : _getMonthLabel();
        data = habitProvider.getMonthlyCompletionPattern(_selectedMonth);
        score = data.values.fold(0.0, (sum, value) => sum + value) / data.length * 100;
        break;
      
      case StatisticsViewType.yearly:
        dateRange = '${_selectedYear.year}';
        periodLabel = _isCurrentYear() ? 'This Year' : '${_selectedYear.year}';
        data = habitProvider.getYearlyCompletionPattern(_selectedYear);
        score = data.values.fold(0.0, (sum, value) => sum + value) / data.length * 100;
        break;
    }
    
    // Mock comparison data - in real app would get from database
    final previousScore = score * 0.85; // 15% lower for demo
    final improvement = score - previousScore;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Week range
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateRange,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: neutralBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              periodLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralBlack.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        
        // Weekly score and comparison
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: neutralBlack,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: improvement >= 0 
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                        : const Color(0xFFF44336).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        improvement >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 12,
                        color: improvement >= 0 
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${improvement.abs().toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: improvement >= 0 
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getComparisonLabel(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralBlack.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final selectedWeekStart = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
    
    return currentWeekStart.year == selectedWeekStart.year &&
           currentWeekStart.month == selectedWeekStart.month &&
           currentWeekStart.day == selectedWeekStart.day;
  }

  String _getWeekLabel() {
    final now = DateTime.now();
    final selectedWeekStart = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weekDiff = currentWeekStart.difference(selectedWeekStart).inDays ~/ 7;
    
    if (weekDiff == 1) return 'Last Week';
    if (weekDiff == -1) return 'Next Week';
    if (weekDiff > 1) return '$weekDiff weeks ago';
    if (weekDiff < -1) return '${weekDiff.abs()} weeks ahead';
    
    return 'This Week';
  }

  String _formatMonth(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[date.month - 1];
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  bool _isCurrentYear() {
    final now = DateTime.now();
    return _selectedYear.year == now.year;
  }

  String _getMonthLabel() {
    final now = DateTime.now();
    final monthDiff = (now.year - _selectedMonth.year) * 12 + (now.month - _selectedMonth.month);
    
    if (monthDiff == 1) return 'Last Month';
    if (monthDiff == -1) return 'Next Month';
    if (monthDiff > 1) return '$monthDiff months ago';
    if (monthDiff < -1) return '${monthDiff.abs()} months ahead';
    
    return 'This Month';
  }

  String _getComparisonLabel() {
    switch (_viewType) {
      case StatisticsViewType.weekly:
        return 'vs last week';
      case StatisticsViewType.monthly:
        return 'vs last month';
      case StatisticsViewType.yearly:
        return 'vs last year';
    }
  }

  void _navigatePrevious() {
    switch (_viewType) {
      case StatisticsViewType.weekly:
        _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
        break;
      case StatisticsViewType.monthly:
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
        break;
      case StatisticsViewType.yearly:
        _selectedYear = DateTime(_selectedYear.year - 1, 1, 1);
        break;
    }
  }

  void _navigateNext() {
    switch (_viewType) {
      case StatisticsViewType.weekly:
        _selectedWeek = _selectedWeek.add(const Duration(days: 7));
        break;
      case StatisticsViewType.monthly:
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
        break;
      case StatisticsViewType.yearly:
        _selectedYear = DateTime(_selectedYear.year + 1, 1, 1);
        break;
    }
  }


  Widget _buildWeeklyChart(HabitProvider habitProvider) {
    Map<String, double> chartData;
    List<String> labels;
    
    switch (_viewType) {
      case StatisticsViewType.weekly:
        chartData = habitProvider.getWeeklyCompletionPattern(_selectedWeek);
        labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        break;
      case StatisticsViewType.monthly:
        chartData = habitProvider.getMonthlyCompletionPattern(_selectedMonth);
        labels = chartData.keys.map((key) => key.replaceAll('Week ', 'W')).toList();
        break;
      case StatisticsViewType.yearly:
        chartData = habitProvider.getYearlyCompletionPattern(_selectedYear);
        labels = chartData.keys.toList();
        break;
    }
    
    final maxValue = chartData.isEmpty ? 1.0 : chartData.values.reduce((a, b) => a > b ? a : b);
    
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Column(
        children: [
          // Y-axis labels
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Chart bars
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        // Bars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: chartData.keys.toList().map((key) {
                            final value = chartData[key] ?? 0.0;
                            final barHeight = (value / maxValue) * 130; // Max 130px for the bar area, leaving space for percentage labels
                            
                            Color barColor;
                            if (value >= 0.8) {
                              barColor = const Color(0xFF4CAF50); // Green for excellent
                            } else if (value >= 0.6) {
                              barColor = primaryOrange; // Orange for good
                            } else if (value >= 0.4) {
                              barColor = const Color(0xFFFFA726); // Light orange for fair
                            } else if (value >= 0.2) {
                              barColor = const Color(0xFFFFCC80); // Very light orange for poor
                            } else {
                              barColor = neutralLightGray; // Gray for very poor
                            }
                            
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _viewType == StatisticsViewType.monthly ? 8 : 4,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Percentage label above bar
                                    if (value > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          '${(value * 100).toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: neutralBlack,
                                          ),
                                        ),
                                      ),
                                    // Bar
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutCubic,
                                      width: double.infinity,
                                      height: barHeight.clamp(4.0, 130.0), // Minimum 4px height
                                      decoration: BoxDecoration(
                                        color: neutralWhite, // White color
                                        borderRadius: BorderRadius.circular(20), // Pill shape
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: labels.map((label) {
              return Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: neutralBlack,
                    letterSpacing: -0.25,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habitsByCategory = habitProvider.habitsByCategory;
        
        if (habitsByCategory.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: neutralWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: neutralBlack.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habits by Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: neutralBlack,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 20),
              
              ...habitsByCategory.entries.map((entry) => _buildCategoryItem(
                entry.key, 
                entry.value.length,
                _getCategoryColor(entry.key),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(String categoryName, int habitCount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getCategoryIcon(categoryName),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              categoryName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: neutralBlack,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$habitCount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Health & Fitness':
        return const Color(0xFF4CAF50);
      case 'Learning':
        return const Color(0xFF2C2C2C);
      case 'Social':
        return const Color(0xFFE91E63);
      case 'Productivity':
        return const Color(0xFF2196F3);
      case 'Mindfulness':
        return const Color(0xFFFF9800);
      case 'Other':
        return const Color(0xFF607D8B);
      default:
        return neutralMediumGray;
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Health & Fitness':
        return Icons.fitness_center;
      case 'Learning':
        return Icons.school;
      case 'Social':
        return Icons.people;
      case 'Productivity':
        return Icons.work;
      case 'Mindfulness':
        return Icons.self_improvement;
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.star;
    }
  }

  Widget _buildHabitBreakdown() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;
        
        if (habits.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: neutralWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 48,
                  color: neutralMediumGray,
                ),
                SizedBox(height: 16),
                Text(
                  'No habits to analyze',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: neutralMediumGray,
                  ),
                ),
                Text(
                  'Add some habits to see detailed statistics',
                  style: TextStyle(
                    fontSize: 14,
                    color: neutralMediumGray,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: neutralWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: neutralBlack.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habit Breakdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: neutralBlack,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 20),
              
              ...habits.take(5).map((habit) => _buildHabitBreakdownItem(habit, habitProvider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHabitBreakdownItem(dynamic habit, HabitProvider habitProvider) {
    final streak = habitProvider.getCurrentStreak(habit.id!);
    final completionRate = habitProvider.getHabitCompletionRate(habit.id!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
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
          
          const SizedBox(width: 12),
          
          // Habit details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: neutralBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Streak: $streak days • ${(completionRate * 100).toStringAsFixed(0)}% completed',
                  style: const TextStyle(
                    fontSize: 14,
                    color: neutralMediumGray,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress indicator
          Container(
            width: 50,
            height: 8,
            decoration: BoxDecoration(
              color: neutralLightGray,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completionRate,
              child: Container(
                decoration: BoxDecoration(
                  color: primaryOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = (screenWidth * 0.65).clamp(200.0, 280.0);
    
    return Center(
      child: SizedBox(
        width: navWidth,
        height: 85,
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Image.asset(
                        'assets/icons/home-inactive.png',
                        width: 24,
                        height: 24,
                        color: neutralWhite,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.home_outlined,
                          size: 24,
                          color: neutralWhite,
                        ),
                      ),
                    ),
                    
                    // Empty space for the protruding add button
                    const SizedBox(width: 44),
                    
                    // Statistics button (active)
                    IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/icons/stats-active.png',
                        width: 24,
                        height: 24,
                        color: neutralWhite,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.bar_chart,
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
              top: 0,
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
                  onPressed: () => Navigator.of(context).pushNamed('/add-habit'),
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

  Color _getConsistencyScoreColor(double score) {
    if (score >= 80) {
      return const Color(0xFFE8F5E8); // Light green for excellent
    } else if (score >= 60) {
      return const Color(0xFFFFEAE4); // Light orange for good
    } else if (score >= 40) {
      return const Color(0xFFFFF3E0); // Light yellow for fair
    } else {
      return const Color(0xFFFFEBEE); // Light red for needs improvement
    }
  }

  Color _getConsistencyScoreValueColor(double score) {
    if (score >= 80) {
      return const Color(0xFF4CAF50); // Green for excellent (80-100)
    } else if (score >= 60) {
      return primaryOrange; // Orange for good (60-79)
    } else if (score >= 40) {
      return const Color(0xFFF57F17); // Amber for fair (40-59)
    } else {
      return const Color(0xFFD32F2F); // Red for needs improvement (0-39)
    }
  }

  Widget _getHabitIcon(dynamic habit) {
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
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return const HabitCalendarWidget();
          },
        );
      },
    );
  }
}