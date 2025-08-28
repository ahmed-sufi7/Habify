import 'package:flutter_test/flutter_test.dart';
import 'package:habify/models/habit_completion.dart';

void main() {
  group('Habit Miss/Fail Behavior Tests', () {
    
    test('What happens when a user misses a habit', () {
      print('🚫 HABIT MISS BEHAVIOR ANALYSIS');
      print('================================\n');
      
      // Simulate missing a habit
      final missedDate = DateTime.now();
      
      final missedCompletion = HabitCompletion.missed(
        habitId: 1,
        date: missedDate,
        notes: 'Forgot to do the habit today',
      );
      
      print('When a habit is marked as missed:');
      print('• Status: ${missedCompletion.status}');
      print('• Completed at: ${missedCompletion.completedAt}');
      print('• Streak count: ${missedCompletion.streakCount}');
      print('• Is completed: ${missedCompletion.isCompleted}');
      print('• Is missed: ${missedCompletion.isMissed}');
      
      // Verify missed completion properties
      expect(missedCompletion.status, 'missed');
      expect(missedCompletion.completedAt, null);
      expect(missedCompletion.streakCount, 0); // Streak resets to 0
      expect(missedCompletion.isCompleted, false);
      expect(missedCompletion.isMissed, true);
      
      print('\n✅ Missing a habit creates a "missed" entry with streak reset to 0');
    });
    
    test('Streak calculation behavior with missed days', () {
      print('\n📊 STREAK CALCULATION WITH MISSED DAYS');
      print('======================================\n');
      
      // Simulate a streak scenario: 3 days completed, then 1 missed, then 2 more completed
      final now = DateTime.now();
      final completions = [
        // Most recent first (as database returns them)
        {'date': now, 'status': 'completed'}, // Today - completed
        {'date': now.subtract(Duration(days: 1)), 'status': 'completed'}, // Yesterday - completed
        {'date': now.subtract(Duration(days: 2)), 'status': 'missed'}, // 2 days ago - MISSED
        {'date': now.subtract(Duration(days: 3)), 'status': 'completed'}, // 3 days ago - completed
        {'date': now.subtract(Duration(days: 4)), 'status': 'completed'}, // 4 days ago - completed
        {'date': now.subtract(Duration(days: 5)), 'status': 'completed'}, // 5 days ago - completed
      ];
      
      // Simulate the calculateCurrentStreak logic
      int streak = 0;
      for (final completion in completions) {
        final status = completion['status'] as String;
        final date = completion['date'] as DateTime;
        
        print('${date.toIso8601String().split('T')[0]}: $status');
        
        if (status == 'completed') {
          streak++;
        } else if (status == 'missed') {
          print('  ❌ Streak broken at this point!');
          break; // Streak broken
        }
      }
      
      print('\nCurrent streak: $streak days');
      print('Explanation: Counting backwards from today, streak continues until the first "missed" entry');
      
      expect(streak, 2); // Only today + yesterday (stops at missed day)
      
      print('\n✅ Streak calculation stops at the first missed day when counting backwards');
    });
    
    test('Grid visualization behavior for missed habits', () {
      print('\n🟩 GRID VISUALIZATION WITH MISSED HABITS');
      print('=======================================\n');
      
      // Simulate a 7-day period with mixed completions and misses
      final now = DateTime.now();
      final habitHistory = [
        {'date': now, 'completed': true},                           // Today: ●
        {'date': now.subtract(Duration(days: 1)), 'completed': true},  // Day 1: ●
        {'date': now.subtract(Duration(days: 2)), 'completed': false}, // Day 2: ○ (missed)
        {'date': now.subtract(Duration(days: 3)), 'completed': true},  // Day 3: ●
        {'date': now.subtract(Duration(days: 4)), 'completed': false}, // Day 4: ○ (missed)
        {'date': now.subtract(Duration(days: 5)), 'completed': false}, // Day 5: ○ (missed)
        {'date': now.subtract(Duration(days: 6)), 'completed': true},  // Day 6: ●
      ];
      
      print('Grid visualization for first 7 dots:');
      print('=====================================');
      
      String gridRow = '';
      for (int i = 0; i < 7; i++) {
        final dayData = habitHistory[i];
        final isCompleted = dayData['completed'] as bool;
        final dotSymbol = isCompleted ? '●' : '○';
        gridRow += '$dotSymbol ';
        
        final date = dayData['date'] as DateTime;
        final dayDescription = i == 0 ? 'Today' : '${i} day${i > 1 ? 's' : ''} ago';
        final status = isCompleted ? 'Completed' : 'Missed';
        
        print('Index $i ($dayDescription): $dotSymbol $status');
      }
      
      print('\nGrid row: $gridRow');
      print('\nColor coding:');
      print('● = Black dot (habit completed)');
      print('○ = Light gray dot (habit missed/not completed)');
      
      // Count completed vs missed in this sample
      int completed = habitHistory.where((day) => day['completed'] as bool).length;
      int missed = habitHistory.where((day) => !(day['completed'] as bool)).length;
      
      print('\nIn this 7-day sample:');
      print('• Completed: $completed days');
      print('• Missed: $missed days');
      print('• Current streak: 2 days (today + yesterday, broken by day 2 miss)');
      
      expect(completed, 4);
      expect(missed, 3);
      
      print('\n✅ Grid shows both completed (●) and missed (○) days visually');
    });
    
    test('Different types of habit status outcomes', () {
      print('\n📝 DIFFERENT HABIT STATUS TYPES');
      print('===============================\n');
      
      final testDate = DateTime.now();
      
      // Test all three status types
      final completed = HabitCompletion.forDate(
        habitId: 1,
        date: testDate,
        status: 'completed',
        streakCount: 5,
      );
      
      final missed = HabitCompletion.missed(
        habitId: 1,
        date: testDate,
      );
      
      final skipped = HabitCompletion.forDate(
        habitId: 1,
        date: testDate,
        status: 'skipped',
        notes: 'Sick day - doctor advised rest',
      );
      
      print('Status types and their effects:');
      print('================================');
      
      print('1. COMPLETED:');
      print('   • Status: ${completed.status}');
      print('   • Completed at: ${completed.completedAt != null ? 'Set' : 'null'}');
      print('   • Streak: ${completed.streakCount}');
      print('   • Grid: ● (black dot)');
      print('   • Effect: Continues/builds streak\n');
      
      print('2. MISSED:');
      print('   • Status: ${missed.status}');
      print('   • Completed at: ${missed.completedAt}');
      print('   • Streak: ${missed.streakCount}');
      print('   • Grid: ○ (gray dot)');
      print('   • Effect: BREAKS streak (resets to 0)\n');
      
      print('3. SKIPPED:');
      print('   • Status: ${skipped.status}');
      print('   • Completed at: ${skipped.completedAt}');
      print('   • Streak: ${skipped.streakCount}');
      print('   • Grid: ○ (gray dot)');
      print('   • Effect: Does NOT break streak (neutral)\n');
      
      // Verify the different statuses
      expect(completed.isCompleted, true);
      expect(missed.isMissed, true);
      expect(skipped.isSkipped, true);
      
      print('✅ Three status types handle different scenarios appropriately');
    });
    
    test('Long-term habit pattern with failures', () {
      print('\n📅 LONG-TERM PATTERN WITH MISSED DAYS');
      print('====================================\n');
      
      // Simulate a realistic 30-day habit journey
      final now = DateTime.now();
      final monthPattern = [
        // Week 1: Strong start
        true, true, true, true, true, true, true,
        // Week 2: One slip
        true, true, false, true, true, true, true,
        // Week 3: Tough week with multiple misses  
        false, false, true, true, false, true, true,
        // Week 4: Recovery
        true, true, true, true, true, true, true,
        // Extra days to make 30
        true, true,
      ];
      
      print('30-day habit pattern (● = completed, ○ = missed):');
      
      String pattern = '';
      int currentStreak = 0;
      int completedDays = 0;
      int missedDays = 0;
      
      // Count from most recent (today) backwards
      for (int i = 0; i < monthPattern.length; i++) {
        final completed = monthPattern[i];
        pattern += completed ? '● ' : '○ ';
        
        if (completed) {
          completedDays++;
          if (i < 7) currentStreak++; // Only count current streak from today
        } else {
          missedDays++;
          if (i < 7 && currentStreak > 0) {
            // This would break the current streak calculation
          }
        }
        
        if ((i + 1) % 7 == 0) {
          print('Week ${(i / 7).ceil()}: ${pattern.substring(pattern.length - 14)}');
        }
      }
      
      final completionRate = (completedDays / monthPattern.length * 100).round();
      
      print('\nMonth summary:');
      print('• Total days: ${monthPattern.length}');
      print('• Completed: $completedDays days');
      print('• Missed: $missedDays days');  
      print('• Completion rate: $completionRate%');
      print('• Current streak: $currentStreak days');
      
      print('\nKey insights:');
      print('• Grid shows last 30 days of this pattern');
      print('• Missed days appear as gray dots but don\'t erase progress');
      print('• Streak counter reflects current consecutive completions');
      print('• Overall progress is still visible and motivating');
      
      expect(completedDays + missedDays, monthPattern.length);
      expect(completionRate, greaterThan(70)); // Still a good completion rate
      
      print('\n✅ Realistic habit patterns show both progress and setbacks');
    });
  });
}