class Habit {
  final int? id;
  final String name;
  final String description;
  final int categoryId;
  final String priority; // Do First, Schedule, Delegate, Eliminate
  final int durationMinutes;
  final String notificationTime; // Format: HH:mm
  final String? alarmTime; // Format: HH:mm (optional)
  final String repetitionPattern; // Everyday, Weekdays, Weekends, etc.
  final List<int> customDays; // [1,2,3,4,5] for custom day selection (1=Monday, 7=Sunday)
  final DateTime startDate;
  final DateTime? endDate; // null means no end date
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Habit({
    this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.priority,
    required this.durationMinutes,
    required this.notificationTime,
    this.alarmTime,
    required this.repetitionPattern,
    this.customDays = const [],
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['category_id']?.toInt() ?? 0,
      priority: map['priority'] ?? 'Do First',
      durationMinutes: map['duration_minutes']?.toInt() ?? 0,
      notificationTime: map['notification_time'] ?? '07:30',
      alarmTime: map['alarm_time'],
      repetitionPattern: map['repetition_pattern'] ?? 'Everyday',
      customDays: _parseCustomDays(map['custom_days']),
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'priority': priority,
      'duration_minutes': durationMinutes,
      'notification_time': notificationTime,
      'alarm_time': alarmTime,
      'repetition_pattern': repetitionPattern,
      'custom_days': _serializeCustomDays(customDays),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static List<int> _parseCustomDays(String? customDaysStr) {
    if (customDaysStr == null || customDaysStr.isEmpty) {
      return [];
    }
    try {
      return customDaysStr.split(',').map((e) => int.parse(e.trim())).toList();
    } catch (e) {
      return [];
    }
  }

  static String _serializeCustomDays(List<int> customDays) {
    return customDays.join(',');
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    String? priority,
    int? durationMinutes,
    String? notificationTime,
    String? alarmTime,
    String? repetitionPattern,
    List<int>? customDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notificationTime: notificationTime ?? this.notificationTime,
      alarmTime: alarmTime ?? this.alarmTime,
      repetitionPattern: repetitionPattern ?? this.repetitionPattern,
      customDays: customDays ?? this.customDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Habit(id: $id, name: $name, description: $description, categoryId: $categoryId, priority: $priority, durationMinutes: $durationMinutes, notificationTime: $notificationTime, alarmTime: $alarmTime, repetitionPattern: $repetitionPattern, customDays: $customDays, startDate: $startDate, endDate: $endDate, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Habit &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.categoryId == categoryId &&
        other.priority == priority &&
        other.durationMinutes == durationMinutes &&
        other.notificationTime == notificationTime &&
        other.alarmTime == alarmTime &&
        other.repetitionPattern == repetitionPattern &&
        other.customDays.toString() == customDays.toString() &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        categoryId.hashCode ^
        priority.hashCode ^
        durationMinutes.hashCode ^
        notificationTime.hashCode ^
        alarmTime.hashCode ^
        repetitionPattern.hashCode ^
        customDays.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // Helper methods for business logic
  bool shouldShowToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if habit has started
    if (today.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return false;
    }
    
    // Check if habit has ended
    if (endDate != null) {
      final endDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (today.isAfter(endDay)) {
        return false;
      }
    }
    
    // Check repetition pattern
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    
    switch (repetitionPattern) {
      case 'Everyday':
        return true;
      case 'Weekdays':
        return weekday >= 1 && weekday <= 5;
      case 'Weekends':
        return weekday == 6 || weekday == 7;
      case 'Monday':
        return weekday == 1;
      case 'Tuesday':
        return weekday == 2;
      case 'Wednesday':
        return weekday == 3;
      case 'Thursday':
        return weekday == 4;
      case 'Friday':
        return weekday == 5;
      case 'Saturday':
        return weekday == 6;
      case 'Sunday':
        return weekday == 7;
      case 'Custom':
        return customDays.contains(weekday);
      default:
        return false;
    }
  }

  bool shouldShowOnDate(DateTime date) {
    final targetDay = DateTime(date.year, date.month, date.day);
    
    // Check if habit has started
    if (targetDay.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return false;
    }
    
    // Check if habit has ended
    if (endDate != null) {
      final endDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (targetDay.isAfter(endDay)) {
        return false;
      }
    }
    
    // Check repetition pattern
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    
    switch (repetitionPattern) {
      case 'Everyday':
        return true;
      case 'Weekdays':
        return weekday >= 1 && weekday <= 5;
      case 'Weekends':
        return weekday == 6 || weekday == 7;
      case 'Monday':
        return weekday == 1;
      case 'Tuesday':
        return weekday == 2;
      case 'Wednesday':
        return weekday == 3;
      case 'Thursday':
        return weekday == 4;
      case 'Friday':
        return weekday == 5;
      case 'Saturday':
        return weekday == 6;
      case 'Sunday':
        return weekday == 7;
      case 'Custom':
        return customDays.contains(weekday);
      default:
        return false;
    }
  }

  String get durationDisplay {
    if (durationMinutes < 60) {
      return '${durationMinutes} min';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }
}