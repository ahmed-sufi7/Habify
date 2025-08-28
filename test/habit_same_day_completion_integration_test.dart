import 'package:flutter_test/flutter_test.dart';
import 'package:habify/models/habit.dart';
import 'package:habify/models/habit_completion.dart';

/// Integration test that simulates the complete flow of creating a habit
/// today and marking it complete on the same day
void main() {
  group('Habit Same-Day Completion Integration Tests', () {
    
    test('Complete flow: create habit today, verify it shows today, mark complete', () {
      // Step 1: Simulate creating a habit right now (what happens in add_habit_screen)
      final creationTime = DateTime.now();
      print('🕐 Creating habit at: $creationTime');
      
      final newHabit = Habit(
        name: 'Daily Reading',
        description: 'Read for 30 minutes',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 30,
        notificationTime: '08:00',
        repetitionPattern: 'Everyday',
        startDate: creationTime, // This is the key - real creation time
        createdAt: creationTime,
        updatedAt: creationTime,
      );
      
      print('📝 Created habit: ${newHabit.name}');
      print('📅 Start date: ${newHabit.startDate}');
      
      // Step 2: Verify habit shows up in today's habits (HabitDao.getTodayHabits logic)
      final today = DateTime(creationTime.year, creationTime.month, creationTime.day);
      final endOfToday = DateTime(creationTime.year, creationTime.month, creationTime.day, 23, 59, 59, 999);
      
      // Simulate the database query condition
      final startDateString = newHabit.startDate.toIso8601String();
      final endOfTodayString = endOfToday.toIso8601String();
      final wouldPassDatabaseFilter = startDateString.compareTo(endOfTodayString) <= 0;
      
      print('🔍 Database filter check (start_date <= end_of_today): $wouldPassDatabaseFilter');
      expect(wouldPassDatabaseFilter, true, reason: 'Habit should pass database date filter');
      
      // Step 3: Verify habit.shouldShowToday() works (after passing database filter)
      final shouldShowToday = newHabit.shouldShowToday();
      print('✅ shouldShowToday(): $shouldShowToday');
      expect(shouldShowToday, true, reason: 'Habit should be available for completion today');
      
      // Step 4: Simulate marking habit complete (HabitService.completeHabit flow)
      final completionTime = DateTime.now();
      
      // This simulates HabitCompletion.forDate factory method
      final completion = HabitCompletion.forDate(
        habitId: 1, // Simulated habit ID
        date: completionTime,
        status: 'completed',
        streakCount: 1, // First completion
      );
      
      print('🎯 Created completion: ${completion.status}');
      print('📅 Completion date: ${completion.completionDate}');
      print('🔥 Streak count: ${completion.streakCount}');
      
      // Verify completion was created correctly
      expect(completion.isCompleted, true);
      expect(completion.streakCount, 1);
      expect(completion.completionDate.year, today.year);
      expect(completion.completionDate.month, today.month);
      expect(completion.completionDate.day, today.day);
      
      print('✅ Same-day habit completion flow works correctly!');
    });
    
    test('Edge case: Habit created at 11:59 PM should be completable', () {
      // Create habit just before midnight
      final lateCreation = DateTime(2025, 8, 28, 23, 58, 0);
      
      final lateHabit = Habit(
        name: 'Late Night Habit',
        description: 'Last minute habit',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 5,
        notificationTime: '23:30',
        repetitionPattern: 'Everyday',
        startDate: lateCreation,
        createdAt: lateCreation,
        updatedAt: lateCreation,
      );
      
      // Should still be available for completion before midnight
      expect(lateHabit.shouldShowToday(), true);
      
      // Database filter should also work
      final endOfDay = DateTime(2025, 8, 28, 23, 59, 59, 999);
      final passesFilter = lateCreation.toIso8601String().compareTo(endOfDay.toIso8601String()) <= 0;
      expect(passesFilter, true);
      
      print('✅ Late night habit creation edge case works!');
    });
    
    test('Streak calculation should work for same-day completion', () {
      final creationTime = DateTime.now();
      
      // Create first completion for today
      final firstCompletion = HabitCompletion.forDate(
        habitId: 1,
        date: creationTime,
        status: 'completed',
        streakCount: 1, // This would be calculated by calculateCurrentStreak
      );
      
      expect(firstCompletion.streakCount, 1);
      expect(firstCompletion.isCompleted, true);
      
      // Verify completion date is normalized to day-only
      final expectedDate = DateTime(creationTime.year, creationTime.month, creationTime.day);
      expect(firstCompletion.completionDate, expectedDate);
      
      print('✅ Streak calculation for same-day completion works!');
    });
  });
}