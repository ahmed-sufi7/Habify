class HabitCompletion {
  final int? id;
  final int habitId;
  final DateTime completionDate; // Date when the habit was supposed to be completed (YYYY-MM-DD)
  final DateTime? completedAt; // Actual timestamp when marked as completed
  final int streakCount; // Streak count at the time of completion
  final String status; // 'completed', 'missed', 'skipped'
  final String? notes; // Optional notes about the completion
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitCompletion({
    this.id,
    required this.habitId,
    required this.completionDate,
    this.completedAt,
    this.streakCount = 0,
    this.status = 'completed',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id']?.toInt(),
      habitId: map['habit_id']?.toInt() ?? 0,
      completionDate: DateTime.parse(map['completion_date']),
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']) 
          : null,
      streakCount: map['streak_count']?.toInt() ?? 0,
      status: map['status'] ?? 'completed',
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'completion_date': completionDate.toIso8601String().split('T')[0], // Store as YYYY-MM-DD
      'completed_at': completedAt?.toIso8601String(),
      'streak_count': streakCount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HabitCompletion copyWith({
    int? id,
    int? habitId,
    DateTime? completionDate,
    DateTime? completedAt,
    int? streakCount,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      completionDate: completionDate ?? this.completionDate,
      completedAt: completedAt ?? this.completedAt,
      streakCount: streakCount ?? this.streakCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HabitCompletion(id: $id, habitId: $habitId, completionDate: $completionDate, completedAt: $completedAt, streakCount: $streakCount, status: $status, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HabitCompletion &&
        other.id == id &&
        other.habitId == habitId &&
        other.completionDate == completionDate &&
        other.completedAt == completedAt &&
        other.streakCount == streakCount &&
        other.status == status &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        habitId.hashCode ^
        completionDate.hashCode ^
        completedAt.hashCode ^
        streakCount.hashCode ^
        status.hashCode ^
        notes.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isMissed => status == 'missed';
  bool get isSkipped => status == 'skipped';

  // Check if this completion is for today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completionDay = DateTime(
      completionDate.year,
      completionDate.month,
      completionDate.day,
    );
    return today == completionDay;
  }

  // Get a formatted date string
  String get formattedDate {
    return '${completionDate.year}-${completionDate.month.toString().padLeft(2, '0')}-${completionDate.day.toString().padLeft(2, '0')}';
  }

  // Factory method to create a completion for today
  factory HabitCompletion.forToday({
    required int habitId,
    String status = 'completed',
    String? notes,
    int streakCount = 0,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return HabitCompletion(
      habitId: habitId,
      completionDate: today,
      completedAt: status == 'completed' ? now : null,
      status: status,
      notes: notes,
      streakCount: streakCount,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Factory method to create a missed completion
  factory HabitCompletion.missed({
    required int habitId,
    required DateTime date,
    String? notes,
  }) {
    final now = DateTime.now();
    
    return HabitCompletion(
      habitId: habitId,
      completionDate: date,
      completedAt: null,
      status: 'missed',
      notes: notes,
      streakCount: 0, // Reset streak when missed
      createdAt: now,
      updatedAt: now,
    );
  }
}