import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';

/// Live Pomodoro Session Indicator Widget
/// Shows a horizontal section displaying active pomodoro session info
/// when a session is running or paused
class LivePomodoroIndicator extends StatefulWidget {
  final VoidCallback? onTap;
  
  const LivePomodoroIndicator({
    super.key,
    this.onTap,
  });

  @override
  State<LivePomodoroIndicator> createState() => _LivePomodoroIndicatorState();
}

class _LivePomodoroIndicatorState extends State<LivePomodoroIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateDotAnimation(bool shouldAnimate) {
    if (shouldAnimate && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!shouldAnimate && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  // Design colors from home_design.json for consistency
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color neutralMediumGray = Color(0xFF666666);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentBlue = Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, pomodoroProvider, child) {
        // Only show if there's an active timer (running or paused)
        if (!pomodoroProvider.hasActiveTimer) {
          return const SizedBox.shrink();
        }

        // Update dot animation based on timer state
        final shouldAnimateDot = pomodoroProvider.isRunning;
        _updateDotAnimation(shouldAnimateDot);

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _getBackgroundColor(pomodoroProvider),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Pomodoro icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: neutralBlack,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/icons/clock-icon.png',
                      width: 20,
                      height: 20,
                      color: neutralWhite,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Session info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pomodoroProvider.currentSessionTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: neutralBlack,
                          letterSpacing: 0,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pomodoroProvider.currentSessionDescription} • ${_getStatusText(pomodoroProvider)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: neutralMediumGray,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Status indicator and timer display
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status dot with breathing animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final isAnimating = pomodoroProvider.isRunning;
                        final isWorkSession = pomodoroProvider.currentSessionType == SessionType.work;
                        
                        return Transform.scale(
                          scale: isAnimating ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(pomodoroProvider),
                              shape: BoxShape.circle,
                              boxShadow: isAnimating
                                  ? [
                                      BoxShadow(
                                        color: _getStatusColor(pomodoroProvider).withValues(alpha: 0.4),
                                        blurRadius: 3,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: neutralBlack.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pomodoroProvider.formattedTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: neutralBlack,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(PomodoroProvider provider) {
    return const Color(0xFFE8D5F0); // Light lavender/pink background (same as habit cards)
  }

  Color _getStatusColor(PomodoroProvider provider) {
    switch (provider.currentSessionType) {
      case SessionType.work:
        return primaryOrange; // Orange for work sessions
      case SessionType.shortBreak:
        return accentGreen; // Green for short breaks
      case SessionType.longBreak:
        return accentBlue; // Blue for long breaks
    }
  }

  String _getStatusText(PomodoroProvider provider) {
    if (provider.isRunning) {
      return 'Running';
    } else if (provider.isPaused) {
      return 'Paused';
    } else {
      return 'Ready';
    }
  }
}