import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/pomodoro_provider.dart';

class PomodoroTimerScreen extends StatefulWidget {
  final int sessionId;
  final String sessionName;
  
  const PomodoroTimerScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
  });

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Load the session for display (but don't start timer automatically)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<PomodoroProvider>(context, listen: false);
      
      // Check if there's already an active session with this ID
      if (provider.activeSession?.id == widget.sessionId) {
        // Session is already active, just continue with current state
        return;
      }
      
      // Load the session into provider state for display
      await provider.loadSessionForDisplay(widget.sessionId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safely handle provider state changes
    try {
      final provider = Provider.of<PomodoroProvider>(context);
      
      // Handle animation based on timer state
      if (mounted && provider.isRunning && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (mounted && !provider.isRunning && _pulseController.isAnimating) {
        _pulseController.stop();
      }
      
      // Handle timer completion
      if (mounted && provider.isCompleted) {
        // Show completion dialog and move to next session
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pulseController.stop(); // Stop pulse animation
            _moveToNextSessionDialog(provider);
          }
        });
      }
    } catch (e) {
      // Gracefully handle provider errors
      debugPrint('Error in didChangeDependencies: $e');
    }
  }


  @override
  void dispose() {
    // Properly cleanup animation controller
    _pulseController.stop();
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePlayPause() {
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    
    if (provider.isRunning) {
      // Pause the timer
      provider.pauseTimer();
      _pulseController.stop();
    } else if (provider.isPaused) {
      // Resume the timer
      provider.resumeTimer();
      _pulseController.repeat(reverse: true);
    } else if (provider.isIdle || provider.isCompleted) {
      // Start the timer for the loaded session (only if there's an active session)
      if (provider.activeSession != null) {
        provider.startLoadedTimer();
        if (provider.isRunning) {
          _pulseController.repeat(reverse: true);
        }
      }
    }
  }

  void _handleSkip() {
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    
    if (!provider.isRunning && !provider.isPaused) return;
    
    // Complete current timer and show next session dialog
    provider.stopLoadedTimer();
    _pulseController.stop();
    
    if (mounted) {
      // Show completion message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${provider.currentSessionDescription} skipped!'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Move to next session
      _moveToNextSessionDialog(provider);
    }
  }

  void _terminateSessionAndGoHome() {
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    
    // Stop animation
    _pulseController.stop();
    
    // Completely terminate the session
    provider.terminateCurrentSession();
    
    // Navigate to home screen, removing all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _handleStop() {
    final provider = Provider.of<PomodoroProvider>(context, listen: false);
    
    if (provider.isIdle && provider.activeSession == null) {
      // If no active session, just go back
      Navigator.of(context).pop();
      return;
    }
    
    // Show confirmation dialog for active timers
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFF44336),
                    size: 32,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Stop Session?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Content
                const Text(
                  'Are you sure you want to stop the current session? Your progress will be lost and cannot be recovered.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Stop button
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF44336).withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            _terminateSessionAndGoHome();
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Stop Session',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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


  void _moveToNextSessionDialog(PomodoroProvider provider) {
    if (provider.currentSessionType == SessionType.work) {
      // After work, move to break
      final isLongBreak = provider.currentSessionNumber % 4 == 0;
      final breakType = isLongBreak ? 'Long Break' : 'Short Break';
      
      _showNextSessionDialog(
        title: 'Work Session Complete!',
        message: 'Time for a $breakType. Ready to continue?',
        onStart: () {
          provider.moveToNextSession(
            isLongBreak ? SessionType.longBreak : SessionType.shortBreak, 
            isLongBreak
          );
          // Auto-start the next session
          provider.startLoadedTimer();
          if (provider.isRunning) {
            _pulseController.repeat(reverse: true);
          }
        },
      );
    } else {
      // After break, move to next work session or finish
      if (provider.currentSessionNumber < (provider.activeSession?.sessionsCount ?? 4)) {
        _showNextSessionDialog(
          title: 'Break Complete!',
          message: 'Ready for the next work session?',
          onStart: () {
            provider.moveToNextSession(
              SessionType.work, 
              false, 
              provider.currentSessionNumber + 1
            );
            // Auto-start the next session
            provider.startLoadedTimer();
            if (provider.isRunning) {
              _pulseController.repeat(reverse: true);
            }
          },
        );
      } else {
        _showCompletionDialog();
      }
    }
  }

  void _showNextSessionDialog({
    required String title,
    required String message,
    required VoidCallback onStart,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success/Next icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50),
                    size: 32,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Content
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Buttons
                Row(
                  children: [
                    // Skip button
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Start button
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2C2C2C).withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onStart();
                          },
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'Start Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Center(
                    child: Text(
                      '🎉',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'All Sessions Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Content
                const Text(
                  'Congratulations! You\'ve completed all Pomodoro sessions. You\'ve made great progress today!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Finish button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // Go back to previous screen
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Finish Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Stats preview (optional)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Consumer<PomodoroProvider>(
                            builder: (context, provider, child) {
                              return Text(
                                '${provider.activeSession?.sessionsCount ?? 0}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C2C2C),
                                ),
                              );
                            },
                          ),
                          const Text(
                            'Sessions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: const Color(0xFFE8E8E8),
                      ),
                      Column(
                        children: [
                          Consumer<PomodoroProvider>(
                            builder: (context, provider, child) {
                              final totalMinutes = (provider.activeSession?.workDurationMinutes ?? 0) * 
                                                 (provider.activeSession?.sessionsCount ?? 0);
                              return Text(
                                '${totalMinutes}m',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C2C2C),
                                ),
                              );
                            },
                          ),
                          const Text(
                            'Focus Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTimerSection() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            const SizedBox(height: 32),
            
            // Big timer circle
            AnimatedBuilder(
              animation: provider.isRunning ? _pulseAnimation : 
                         const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: provider.isRunning ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFFFFF),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 6),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: CircularProgressIndicator(
                            value: provider.progress,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFE8E8E8),
                            valueColor: AlwaysStoppedAnimation(
                              _getProgressColor(provider.currentSessionType),
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.formattedTime,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.02,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${provider.currentSessionNumber} of ${provider.activeSession?.sessionsCount ?? 4}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }


  Color _getProgressColor(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.work:
        return const Color(0xFF2C2C2C); // Dark (from stats screen)
      case SessionType.shortBreak:
        return const Color(0xFF4CAF50); // Green (from stats screen)
      case SessionType.longBreak:
        return const Color(0xFFFF6B35); // Orange (from stats screen)
    }
  }

  Widget _buildControlButtons() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip button
              _buildControlButton(
                icon: Icons.skip_next,
                label: 'Skip',
                onTap: _handleSkip,
                backgroundColor: const Color(0xFFEED8FF),
                iconColor: const Color(0xFF2C2C2C),
              ),
              
              // Main Play/Pause button
              _buildMainControlButton(
                icon: provider.isRunning 
                    ? Icons.pause 
                    : provider.isPaused 
                        ? Icons.play_arrow
                        : Icons.play_arrow,
                onTap: _handlePlayPause,
                isPlaying: provider.isRunning,
              ),
              
              // Stop button  
              _buildControlButton(
                icon: Icons.stop,
                label: 'Stop',
                onTap: _handleStop,
                backgroundColor: const Color(0xFFFFE5E5),
                iconColor: const Color(0xFFF44336),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isPlaying,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C2C2C).withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFFFFFF),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildDurationAndHistory() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        final session = provider.activeSession;
        if (session == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Duration Section
              const Text(
                'Duration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              
              // Work Duration
              _buildDurationItem(
                icon: Icons.schedule,
                title: 'Work Duration',
                duration: '${session.workDurationMinutes} min',
              ),
              const SizedBox(height: 12),
              
              // Short Break Duration
              _buildDurationItem(
                icon: Icons.schedule,
                title: 'Short Break Duration',
                duration: '${session.shortBreakMinutes} min',
              ),
              const SizedBox(height: 12),
              
              // Long Break Duration
              _buildDurationItem(
                icon: Icons.schedule,
                title: 'Long Break Duration',
                duration: '${session.longBreakMinutes} min',
              ),
              
              const SizedBox(height: 32),
              
              // Session History Section
              const Text(
                'Session History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              
              // Session History Items - all items in column
              ...List.generate(session.sessionsCount, (index) {
                final sessionNumber = index + 1;
                final isCompleted = sessionNumber < provider.currentSessionNumber;
                final isCurrent = sessionNumber == provider.currentSessionNumber;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSessionHistoryItem(
                    sessionNumber: sessionNumber,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                  ),
                );
              }),
              
              const SizedBox(height: 32), // Space at bottom
            ],
          ),
        );
      },
    );
  }

  Widget _buildDurationItem({
    required IconData icon,
    required String title,
    required String duration,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFFFFF),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Text(
          duration,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHistoryItem({
    required int sessionNumber,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_fire_department,
            color: Color(0xFFFFFFFF),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Session $sessionNumber',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A), // All sessions fully visible
            ),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF2C2C2C) : Colors.transparent,
            shape: BoxShape.circle,
            border: isCompleted 
                ? null 
                : Border.all(color: const Color(0xFF2C2C2C), width: 2),
          ),
          child: isCompleted 
              ? const Icon(
                  Icons.check,
                  color: Color(0xFFFFFFFF),
                  size: 16,
                )
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            size: 22,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.sessionName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.01,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content (Timer + Duration + History)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Timer section
                    _buildTimerSection(),
                    
                    // Duration and History section
                    _buildDurationAndHistory(),
                  ],
                ),
              ),
            ),
            
            // Control buttons at bottom - fixed size
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }
}