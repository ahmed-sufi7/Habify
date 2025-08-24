class PomodoroCompletion {
  final int? id;
  final int sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;
  final int sessionNumber; // Which session in the sequence (1, 2, 3, 4...)
  final String sessionType; // 'work', 'short_break', 'long_break'
  final int actualDurationMinutes; // How long the session actually lasted
  final String? notes; // Optional notes about the session
  final DateTime createdAt;
  final DateTime updatedAt;

  const PomodoroCompletion({
    this.id,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.completed = false,
    this.sessionNumber = 1,
    this.sessionType = 'work',
    this.actualDurationMinutes = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PomodoroCompletion.fromMap(Map<String, dynamic> map) {
    return PomodoroCompletion(
      id: map['id']?.toInt(),
      sessionId: map['session_id']?.toInt() ?? 0,
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      completed: map['completed'] == 1,
      sessionNumber: map['session_number']?.toInt() ?? 1,
      sessionType: map['session_type'] ?? 'work',
      actualDurationMinutes: map['actual_duration_minutes']?.toInt() ?? 0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'completed': completed ? 1 : 0,
      'session_number': sessionNumber,
      'session_type': sessionType,
      'actual_duration_minutes': actualDurationMinutes,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PomodoroCompletion copyWith({
    int? id,
    int? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    bool? completed,
    int? sessionNumber,
    String? sessionType,
    int? actualDurationMinutes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PomodoroCompletion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      sessionType: sessionType ?? this.sessionType,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PomodoroCompletion(id: $id, sessionId: $sessionId, startTime: $startTime, endTime: $endTime, completed: $completed, sessionNumber: $sessionNumber, sessionType: $sessionType, actualDurationMinutes: $actualDurationMinutes, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PomodoroCompletion &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.completed == completed &&
        other.sessionNumber == sessionNumber &&
        other.sessionType == sessionType &&
        other.actualDurationMinutes == actualDurationMinutes &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        completed.hashCode ^
        sessionNumber.hashCode ^
        sessionType.hashCode ^
        actualDurationMinutes.hashCode ^
        notes.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // Helper methods
  bool get isWorkSession => sessionType == 'work';
  bool get isShortBreak => sessionType == 'short_break';
  bool get isLongBreak => sessionType == 'long_break';
  bool get isBreak => isShortBreak || isLongBreak;

  // Get the duration of this session
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  // Check if session is currently active (started but not ended)
  bool get isActive => endTime == null && !completed;

  // Get formatted start time
  String get formattedStartTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted end time
  String get formattedEndTime {
    if (endTime == null) return '--:--';
    return '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
  }

  // Get formatted duration
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get display name for session type
  String get sessionTypeDisplay {
    switch (sessionType) {
      case 'work':
        return 'Work Session';
      case 'short_break':
        return 'Short Break';
      case 'long_break':
        return 'Long Break';
      default:
        return sessionType;
    }
  }

  // Check if this completion is from today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
    );
    return today == sessionDay;
  }

  // Factory method to create a work session
  factory PomodoroCompletion.workSession({
    required int sessionId,
    required int sessionNumber,
    String? notes,
  }) {
    final now = DateTime.now();
    return PomodoroCompletion(
      sessionId: sessionId,
      startTime: now,
      sessionNumber: sessionNumber,
      sessionType: 'work',
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Factory method to create a break session
  factory PomodoroCompletion.breakSession({
    required int sessionId,
    required int sessionNumber,
    required bool isLongBreak,
    String? notes,
  }) {
    final now = DateTime.now();
    return PomodoroCompletion(
      sessionId: sessionId,
      startTime: now,
      sessionNumber: sessionNumber,
      sessionType: isLongBreak ? 'long_break' : 'short_break',
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }
}