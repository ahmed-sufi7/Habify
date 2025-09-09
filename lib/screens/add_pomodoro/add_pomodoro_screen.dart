import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../pomodoro_timer/pomodoro_timer_screen.dart';

class AddPomodoroScreen extends StatefulWidget {
  const AddPomodoroScreen({super.key});

  @override
  State<AddPomodoroScreen> createState() => _AddPomodoroScreenState();
}

class _AddPomodoroScreenState extends State<AddPomodoroScreen> with TickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  
  // State variables with default values from PomodoroSession
  int _workDurationMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessionsCount = 4;
  
  // Animation controllers
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  
  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _buttonScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _savePomodoroSession() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a name for your Pomodoro session';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pomodoroProvider = Provider.of<PomodoroProvider>(context, listen: false);
      final sessionId = await pomodoroProvider.createSession(
        name: _nameController.text.trim(),
        workDurationMinutes: _workDurationMinutes,
        shortBreakMinutes: _shortBreakMinutes,
        longBreakMinutes: _longBreakMinutes,
        sessionsCount: _sessionsCount,
      );

      if (sessionId == null) {
        throw Exception('Failed to create session');
      }

      if (mounted) {
        // Navigate to Pomodoro timer screen
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => PomodoroTimerScreen(
              sessionId: sessionId,
              sessionName: _nameController.text.trim(),
            ),
            fullscreenDialog: true,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create Pomodoro session: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTimePickerRow(String label, int value, ValueChanged<int> onChanged, {required Color backgroundColor, int min = 1, int max = 120}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Decrease button
                GestureDetector(
                  onTap: value > min ? () => onChanged(value - 1) : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: value > min ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: value > min ? Colors.white : const Color(0xFF999999),
                      size: 16,
                    ),
                  ),
                ),
                // Value display
                Expanded(
                  child: Center(
                    child: Text(
                      '$value min${value == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
                // Increase button
                GestureDetector(
                  onTap: value < max ? () => onChanged(value + 1) : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: value < max ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: value < max ? Colors.white : const Color(0xFF999999),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        titleSpacing: 0,
        title: const Text(
          'Add Pomodoro',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.01,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE53E3E)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFE53E3E)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFE53E3E),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Session Name
                    const Text(
                      'Session Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter session name ',
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        maxLength: 50,
                        buildCounter: (context, {required currentLength, maxLength, required isFocused}) => null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Work Duration
                    _buildTimePickerRow(
                      'Work Duration', 
                      _workDurationMinutes, 
                      (value) => setState(() => _workDurationMinutes = value),
                      backgroundColor: const Color(0xFFD0D7F9), // Light purple-blue
                      min: 1,
                      max: 120,
                    ),

                    // Short Break Duration
                    _buildTimePickerRow(
                      'Short Break Duration', 
                      _shortBreakMinutes, 
                      (value) => setState(() => _shortBreakMinutes = value),
                      backgroundColor: const Color(0xFFF9DCF8), // Light pink
                      min: 1,
                      max: 30,
                    ),

                    // Long Break Duration
                    _buildTimePickerRow(
                      'Long Break Duration', 
                      _longBreakMinutes, 
                      (value) => setState(() => _longBreakMinutes = value),
                      backgroundColor: const Color(0xFFFFFBC5), // Light yellow
                      min: 5,
                      max: 60,
                    ),

                    // Sessions Count
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Number of Sessions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC4DBE6), // Light blue
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Decrease button
                                GestureDetector(
                                  onTap: _sessionsCount > 1 ? () => setState(() => _sessionsCount--) : null,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _sessionsCount > 1 ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: _sessionsCount > 1 ? Colors.white : const Color(0xFF999999),
                                      size: 16,
                                    ),
                                  ),
                                ),
                                // Value display
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      '$_sessionsCount session${_sessionsCount == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                  ),
                                ),
                                // Increase button
                                GestureDetector(
                                  onTap: _sessionsCount < 12 ? () => setState(() => _sessionsCount++) : null,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _sessionsCount < 12 ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: _sessionsCount < 12 ? Colors.white : const Color(0xFF999999),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom save button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: AnimatedBuilder(
                animation: _buttonScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _buttonScale.value,
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePomodoroSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2C),
                          foregroundColor: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFFFFF),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Pomodoro Session',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}