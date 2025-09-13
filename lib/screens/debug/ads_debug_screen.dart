import 'package:flutter/material.dart';
import '../../services/admob_service.dart';

class AdsDebugScreen extends StatefulWidget {
  const AdsDebugScreen({super.key});

  @override
  State<AdsDebugScreen> createState() => _AdsDebugScreenState();
}

class _AdsDebugScreenState extends State<AdsDebugScreen> {
  String _logOutput = 'Tap buttons to test ads...\n\n';

  void _addLog(String message) {
    setState(() {
      _logOutput += '[${DateTime.now().toString().substring(11, 19)}] $message\n';
    });
  }

  void _testHabitCreationAd() {
    _addLog('Testing habit creation ad...');
    AdMobService().showAdAfterHabitCreation(
      onAdClosed: () {
        _addLog('✅ Habit creation ad closed');
      },
    );
  }

  void _testPomodoroAd() {
    _addLog('Testing Pomodoro session ad...');
    AdMobService().showAdAfterPomodoroSession(
      onAdClosed: () {
        _addLog('✅ Pomodoro ad closed');
      },
    );
  }

  void _testHabitDetailsAd() {
    _addLog('Testing habit details ad...');
    AdMobService().showAdInHabitDetails(
      onAdClosed: () {
        _addLog('✅ Habit details ad closed');
      },
    );
  }

  void _testHabitCompletion() {
    _addLog('Testing habit completion counter...');
    AdMobService().incrementHabitCompletion(
      onAdClosed: () {
        _addLog('✅ Habit completion ad closed');
      },
    );
  }

  void _resetHabitCounter() {
    _addLog('Resetting habit completion counter...');
    AdMobService().resetHabitsCompletedCount();
    _addLog('✅ Counter reset');
  }

  void _clearLog() {
    setState(() {
      _logOutput = 'Log cleared...\n\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AdMob Debug'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Ad Integration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testHabitCreationAd,
                  child: const Text('Test Habit Creation Ad'),
                ),
                ElevatedButton(
                  onPressed: _testPomodoroAd,
                  child: const Text('Test Pomodoro Ad'),
                ),
                ElevatedButton(
                  onPressed: _testHabitDetailsAd,
                  child: const Text('Test Habit Details Ad'),
                ),
                ElevatedButton(
                  onPressed: _testHabitCompletion,
                  child: const Text('Test Habit Completion'),
                ),
                ElevatedButton(
                  onPressed: _resetHabitCounter,
                  child: const Text('Reset Counter'),
                ),
                ElevatedButton(
                  onPressed: _clearLog,
                  child: const Text('Clear Log'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Debug Log:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Log output
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logOutput,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}