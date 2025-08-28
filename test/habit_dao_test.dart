import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habit DAO Database Query Tests', () {
    test('Date string comparison logic verification', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      
      // Simulate a habit created now
      final habitCreatedNow = now;
      
      print('Current time: $now');
      print('Today midnight: $today');
      print('End of today: $endOfToday');
      print('Habit created at: $habitCreatedNow');
      
      // Simulate database comparison strings
      final todayString = today.toIso8601String();
      final endOfTodayString = endOfToday.toIso8601String();
      final habitStartDateString = habitCreatedNow.toIso8601String();
      
      print('\nDatabase comparison strings:');
      print('Today string (midnight): $todayString');
      print('End of today string: $endOfTodayString');
      print('Habit start date string: $habitStartDateString');
      
      // Test the old logic (which was broken)
      final oldLogicWorks = habitStartDateString.compareTo(todayString) <= 0;
      print('\nOld logic (habit_start <= today_midnight): $oldLogicWorks');
      
      // Test the new logic (which should work)
      final newLogicWorks = habitStartDateString.compareTo(endOfTodayString) <= 0;
      print('New logic (habit_start <= end_of_today): $newLogicWorks');
      
      // The new logic should work, old logic should fail for same-day created habits
      expect(oldLogicWorks, false, reason: 'Old logic should fail for habits created during the day');
      expect(newLogicWorks, true, reason: 'New logic should work for habits created during the day');
    });
    
    test('Verify date comparison edge cases', () {
      // Test habit created at different times of the day
      final testCases = [
        DateTime(2025, 8, 28, 0, 0, 1), // Just after midnight
        DateTime(2025, 8, 28, 12, 0, 0), // Noon
        DateTime(2025, 8, 28, 23, 59, 59), // Just before midnight
      ];
      
      final today = DateTime(2025, 8, 28);
      final endOfToday = DateTime(2025, 8, 28, 23, 59, 59, 999);
      
      for (final habitCreationTime in testCases) {
        final todayString = today.toIso8601String();
        final endOfTodayString = endOfToday.toIso8601String();
        final habitStartDateString = habitCreationTime.toIso8601String();
        
        final newLogicWorks = habitStartDateString.compareTo(endOfTodayString) <= 0;
        
        print('Habit created at ${habitCreationTime.hour}:${habitCreationTime.minute}:${habitCreationTime.second} -> New logic works: $newLogicWorks');
        
        expect(newLogicWorks, true, reason: 'Habit created at any time during the day should be available');
      }
    });
    
    test('Future habits should not be available today', () {
      final tomorrow = DateTime(2025, 8, 29, 12, 0, 0);
      final today = DateTime(2025, 8, 28);
      final endOfToday = DateTime(2025, 8, 28, 23, 59, 59, 999);
      
      final endOfTodayString = endOfToday.toIso8601String();
      final tomorrowHabitString = tomorrow.toIso8601String();
      
      final shouldNotWork = tomorrowHabitString.compareTo(endOfTodayString) <= 0;
      
      expect(shouldNotWork, false, reason: 'Future habits should not be available today');
    });
  });
}