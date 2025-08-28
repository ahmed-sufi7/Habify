import 'package:flutter_test/flutter_test.dart';
import 'package:habify/models/habit.dart';

void main() {
  group('Habit Same-Day Completion Tests', () {
    test('Habit created today should show today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Create a habit with start date as today
      final habit = Habit(
        name: 'Test Habit',
        description: 'Test description',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 30,
        notificationTime: '09:00',
        repetitionPattern: 'Everyday',
        startDate: today,
        createdAt: now,
        updatedAt: now,
      );
      
      // The habit should show today
      expect(habit.shouldShowToday(), true);
    });
    
    test('Habit created with current datetime should show today', () {
      final now = DateTime.now();
      
      // Create a habit with start date as current time
      final habit = Habit(
        name: 'Test Habit',
        description: 'Test description',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 30,
        notificationTime: '09:00',
        repetitionPattern: 'Everyday',
        startDate: now, // This is the key - start date includes time
        createdAt: now,
        updatedAt: now,
      );
      
      // The habit should show today even with time component
      expect(habit.shouldShowToday(), true);
    });
    
    test('Habit with future start date should not show today', () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      
      // Create a habit with start date as tomorrow
      final habit = Habit(
        name: 'Test Habit',
        description: 'Test description',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 30,
        notificationTime: '09:00',
        repetitionPattern: 'Everyday',
        startDate: tomorrow,
        createdAt: now,
        updatedAt: now,
      );
      
      // The habit should not show today
      expect(habit.shouldShowToday(), false);
    });
    
    test('shouldShowOnDate works correctly for same day', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Create a habit with start date as current time
      final habit = Habit(
        name: 'Test Habit',
        description: 'Test description',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 30,
        notificationTime: '09:00',
        repetitionPattern: 'Everyday',
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );
      
      // The habit should show on today's date
      expect(habit.shouldShowOnDate(today), true);
      expect(habit.shouldShowOnDate(now), true);
    });
    
    test('Real world scenario: habit created now with DateTime.now()', () {
      // Simulate exactly what happens when creating a habit in the app
      final creationTime = DateTime.now();
      print('Creation time: $creationTime');
      
      // This is how habits are created in the add_habit_screen
      final habit = Habit(
        name: 'Morning Exercise',
        description: 'Daily morning workout',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 30,
        notificationTime: '07:00',
        repetitionPattern: 'Everyday',
        startDate: creationTime, // This includes hours, minutes, seconds
        createdAt: creationTime,
        updatedAt: creationTime,
      );
      
      print('Start date: ${habit.startDate}');
      print('Should show today: ${habit.shouldShowToday()}');
      
      // The habit should be available for completion immediately
      expect(habit.shouldShowToday(), true);
      
      // Should also work for the current datetime
      expect(habit.shouldShowOnDate(creationTime), true);
      
      // Should work for today as a normalized date
      final today = DateTime(creationTime.year, creationTime.month, creationTime.day);
      expect(habit.shouldShowOnDate(today), true);
    });

    test('Edge case: habit created late at night', () {
      // Simulate creating a habit at 11:59 PM
      final lateNight = DateTime(2025, 8, 28, 23, 59, 0);
      
      final habit = Habit(
        name: 'Night Habit',
        description: 'Late night habit',
        categoryId: 1,
        priority: 'Do First',
        durationMinutes: 5,
        notificationTime: '23:00',
        repetitionPattern: 'Everyday',
        startDate: lateNight,
        createdAt: lateNight,
        updatedAt: lateNight,
      );
      
      // Should still be available for completion on the same day
      expect(habit.shouldShowOnDate(lateNight), true);
      
      // Should be available for the normalized day
      final sameDay = DateTime(2025, 8, 28);
      expect(habit.shouldShowOnDate(sameDay), true);
    });
  });
}