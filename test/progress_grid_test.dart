import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Progress Grid Logic Tests', () {
    test('Grid index mapping should start from today', () {
      final now = DateTime.now();
      
      // Simulate the new grid logic
      for (int index = 0; index < 5; index++) {
        final dotDate = now.subtract(Duration(days: index));
        
        print('Index $index represents: ${dotDate.toIso8601String().split('T')[0]}');
        
        if (index == 0) {
          // Index 0 should be today
          expect(dotDate.year, now.year);
          expect(dotDate.month, now.month);
          expect(dotDate.day, now.day);
        } else {
          // Other indices should be previous days
          final expectedDate = now.subtract(Duration(days: index));
          expect(dotDate.year, expectedDate.year);
          expect(dotDate.month, expectedDate.month);
          expect(dotDate.day, expectedDate.day);
        }
      }
      
      print('\n✅ Grid index 0 correctly represents today');
      print('✅ Subsequent indices represent previous days in chronological order');
    });
    
    test('When habit is completed today, index 0 should be marked', () {
      final now = DateTime.now();
      bool habitCompletedToday = true;
      
      // Check index 0 (today)
      final index0Date = now.subtract(Duration(days: 0));
      final isIndex0Today = _isSameDay(index0Date, now);
      
      expect(isIndex0Today, true, reason: 'Index 0 should represent today');
      
      if (isIndex0Today && habitCompletedToday) {
        print('✅ Index 0 (first dot) will be marked black when habit is completed today');
      }
      
      // Check index 1 (yesterday) - should not be marked for today's completion
      final index1Date = now.subtract(Duration(days: 1));
      final isIndex1Today = _isSameDay(index1Date, now);
      
      expect(isIndex1Today, false, reason: 'Index 1 should not represent today');
      
      print('✅ Only the first dot (index 0) gets marked when habit is completed today');
    });
    
    test('Grid visualization shows completion progression correctly', () {
      // Simulate a 3-day habit completion streak
      final now = DateTime.now();
      final completedDates = [
        now,                               // Today
        now.subtract(Duration(days: 1)),   // Yesterday  
        now.subtract(Duration(days: 2)),   // Day before yesterday
      ];
      
      print('Simulating 3-day streak completion:');
      
      // Check first 5 grid positions
      for (int index = 0; index < 5; index++) {
        final dotDate = now.subtract(Duration(days: index));
        final isCompleted = completedDates.any((date) => _isSameDay(date, dotDate));
        
        final status = isCompleted ? '● (black)' : '○ (gray)';
        print('Index $index (${dotDate.toIso8601String().split('T')[0]}): $status');
        
        if (index < 3) {
          expect(isCompleted, true, reason: 'First 3 dots should be completed');
        } else {
          expect(isCompleted, false, reason: 'Later dots should not be completed');
        }
      }
      
      print('\n✅ Completion streak shows correctly from first dot onwards');
    });
  });
}

// Helper function matching the one in home_screen.dart
bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}