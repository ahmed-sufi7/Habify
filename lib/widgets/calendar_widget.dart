import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

/// Calendar widget based on calendar_design.json specifications
/// Shows habit completion status with dynamic borders for each date
/// Designed to be used as a slide-up bottom sheet
class HabitCalendarWidget extends StatefulWidget {
  const HabitCalendarWidget({super.key});

  @override
  State<HabitCalendarWidget> createState() => _HabitCalendarWidgetState();
}

class _HabitCalendarWidgetState extends State<HabitCalendarWidget>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late PageController _pageController;
  
  // Base date for calculating page indices
  final DateTime _baseDate = DateTime(2020, 1, 1);
  
  
  // Reasonable page limits to prevent memory issues
  static const int _maxPages = 1200; // 100 years worth of months

  // Design colors from calendar_design.json
  static const Color backgroundGradient1 = Color(0xFFE8D5F0);
  static const Color backgroundGradient2 = Color(0xFFF0E1F5);
  static const Color completedDay = Color(0xFF2C2C2C);
  static const Color completedDayText = Color(0xFFFFFFFF);
  static const Color incompleteDayBorder = Color(0xFF2C2C2C);
  static const Color incompleteDayText = Color(0xFF2C2C2C);
  static const Color futureDay = Color(0xFFFFFFFF);
  static const Color futureDayText = Color(0xFF2C2C2C);
  static const Color currentDay = Color(0xFFFF6B35);
  static const Color currentDayText = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF2C2C2C);
  static const Color secondaryText = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    
    // Calculate initial page based on current month
    final monthsDiff = (_currentMonth.year - _baseDate.year) * 12 + 
                     (_currentMonth.month - _baseDate.month);
    _pageController = PageController(initialPage: monthsDiff);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [backgroundGradient1, backgroundGradient2],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  _buildDragHandle(),
                  const SizedBox(height: 12),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildWeekdayHeaders(),
                  const SizedBox(height: 12),
                  _buildScrollableCalendar(),
                  // Minimal padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
                ],
              ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: secondaryText.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - Icon and month text
        Row(
          children: [
            // Calendar icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completedDay, // Black background
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/icons/calendder.png',
                  color: Colors.white, // White icon color
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Month and year text
            Text(
              _getMonthYearString(_currentMonth),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: primaryText,
                letterSpacing: -0.5,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ),
        
        // Right side - Navigation buttons
        Row(
          children: [
            _buildNavButton(Icons.chevron_left, () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }),
            const SizedBox(width: 4),
            _buildNavButton(Icons.chevron_right, () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekdays.map((day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: secondaryText,
              letterSpacing: 0.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScrollableCalendar() {
    return SizedBox(
      height: 280, // Fixed height for calendar grid
      child: PageView.builder(
        controller: _pageController,
        itemCount: _maxPages, // Prevent infinite scrolling
        onPageChanged: (pageIndex) {
          setState(() {
            // Safe month calculation with bounds checking
            final totalMonths = pageIndex;
            final years = totalMonths ~/ 12;
            final months = totalMonths % 12;
            
            // Clamp to reasonable date ranges
            final targetYear = (_baseDate.year + years).clamp(1900, 2200);
            final targetMonth = (_baseDate.month + months).clamp(1, 12);
            
            _currentMonth = DateTime(targetYear, targetMonth, 1);
          });
        },
        itemBuilder: (context, pageIndex) {
          if (pageIndex >= _maxPages) return const SizedBox();
          
          final totalMonths = pageIndex;
          final years = totalMonths ~/ 12;
          final months = totalMonths % 12;
          
          final targetYear = (_baseDate.year + years).clamp(1900, 2200);
          final targetMonth = (_baseDate.month + months).clamp(1, 12);
          
          final monthToShow = DateTime(targetYear, targetMonth, 1);
          return _buildCalendarForMonth(monthToShow);
        },
      ),
    );
  }

  Widget _buildCalendarForMonth(DateTime month) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Use pre-loaded data from HabitProvider
        final monthData = habitProvider.getCalendarDataForMonth(month);
        
        // If no data available, load it asynchronously
        if (monthData.isEmpty) {
          // Trigger loading in background
          habitProvider.ensureCalendarDataLoaded(month);
        }
        
        final daysInMonth = _getDaysInMonth(month);
        final firstDayOfMonth = DateTime(month.year, month.month, 1);
        final startDayOfWeek = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
        
        // Calculate how many cells we need (including empty cells for previous month)
        final totalCells = daysInMonth + (startDayOfWeek - 1);
        final rows = (totalCells / 7).ceil().clamp(1, 6); // Max 6 rows
        
        return Column(
          children: List.generate(rows, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (dayIndex) {
                  final cellIndex = weekIndex * 7 + dayIndex;
                  final dayNumber = cellIndex - (startDayOfWeek - 1) + 1;
                  
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    // Empty cell for days outside current month
                    return const Expanded(child: SizedBox(height: 44));
                  }
                  
                  final date = DateTime(month.year, month.month, dayNumber);
                  final dateData = monthData[date] ?? {
                    'completionRatio': 0.0,
                    'completedCount': 0,
                    'totalCount': 0,
                  };
                  
                  return Expanded(
                    child: Center(child: _buildDayCell(date, dateData)),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDayCell(DateTime date, Map<String, dynamic> habitData) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cellDate = DateTime(date.year, date.month, date.day);
    
    final isToday = cellDate.isAtSameMomentAs(today);
    final isFuture = cellDate.isAfter(today);
    
    final completionRatio = habitData['completionRatio'] as double;
    final completedCount = habitData['completedCount'] as int;
    final totalCount = habitData['totalCount'] as int;
    
    return _buildBaseDayCell(
      date, 
      isToday, 
      isFuture, 
      completionRatio, 
      completedCount, 
      totalCount
    );
  }

  Widget _buildBaseDayCell(
    DateTime date, 
    bool isToday, 
    bool isFuture, 
    double completionRatio, 
    int completedCount, 
    int totalCount
  ) {
    Color backgroundColor;
    Color textColor;
    
    if (isToday) {
      backgroundColor = currentDay;
      textColor = currentDayText;
    } else if (isFuture) {
      backgroundColor = futureDay;
      textColor = futureDayText;
    } else if (completionRatio >= 1.0) {
      // All habits completed - solid black background
      backgroundColor = completedDay;
      textColor = completedDayText;
    } else {
      // Some or no habits completed - no background (transparent) with dynamic border
      backgroundColor = Colors.transparent;
      textColor = incompleteDayText;
    }
    
    return GestureDetector(
      onTap: () => _onDateTapped(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Stack(
          children: [
            // Border system for past days (white base + dynamic black progress)
            if (!isFuture && !isToday)
              _buildProgressBorder(completionRatio),
            
            // Day number
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isToday 
                    ? FontWeight.w700 
                    : completionRatio >= 1.0 
                      ? FontWeight.w600 
                      : isFuture 
                        ? FontWeight.w400 
                        : FontWeight.w500,
                  color: textColor,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBorder(double completionRatio) {
    return CustomPaint(
      painter: PartialBorderPainter(
        completionRatio: completionRatio,
        borderColor: incompleteDayBorder,
        borderWidth: 2.0,
      ),
      child: const SizedBox(width: 44, height: 44),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: primaryText,
          size: 15,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }




  void _onDateTapped(DateTime date) {
    // Add haptic feedback
    // HapticFeedback.lightImpact();
    
    // Date tap functionality can be implemented here
    // to show habit details or navigate to a detailed view
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }


}

/// Custom painter for partial circular border based on habit completion ratio
class PartialBorderPainter extends CustomPainter {
  final double completionRatio;
  final Color borderColor;
  final double borderWidth;

  PartialBorderPainter({
    required this.completionRatio,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.5; // Account for border width

    // Always draw white base border first (full circle) for all past dates
    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, whitePaint);

    // Draw black progress border on top if there's completion
    if (completionRatio > 0) {
      final blackPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Calculate the sweep angle based on completion ratio
      // Start from top (-π/2) and go clockwise
      const startAngle = -3.14159 / 2; // Start from top (12 o'clock)
      final sweepAngle = 2 * 3.14159 * completionRatio; // Full circle = 2π

      // Draw the partial black border on top
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        blackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PartialBorderPainter oldDelegate) {
    return completionRatio != oldDelegate.completionRatio ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth;
  }
}