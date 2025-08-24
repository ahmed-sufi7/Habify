class PomodoroSession {
  final int? id;
  final String name;
  final int workDurationMinutes; // Work session duration
  final int shortBreakMinutes; // Short break duration
  final int longBreakMinutes; // Long break duration
  final int sessionsCount; // Total number of sessions planned
  final bool notificationEnabled;
  final bool alarmEnabled;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PomodoroSession({
    this.id,
    required this.name,
    this.workDurationMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsCount = 4,
    this.notificationEnabled = true,
    this.alarmEnabled = false,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      workDurationMinutes: map['work_duration_minutes']?.toInt() ?? 25,
      shortBreakMinutes: map['short_break_minutes']?.toInt() ?? 5,
      longBreakMinutes: map['long_break_minutes']?.toInt() ?? 15,
      sessionsCount: map['sessions_count']?.toInt() ?? 4,
      notificationEnabled: map['notification_enabled'] == 1,
      alarmEnabled: map['alarm_enabled'] == 1,
      description: map['description'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'work_duration_minutes': workDurationMinutes,
      'short_break_minutes': shortBreakMinutes,
      'long_break_minutes': longBreakMinutes,
      'sessions_count': sessionsCount,
      'notification_enabled': notificationEnabled ? 1 : 0,
      'alarm_enabled': alarmEnabled ? 1 : 0,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PomodoroSession copyWith({
    int? id,
    String? name,
    int? workDurationMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsCount,
    bool? notificationEnabled,
    bool? alarmEnabled,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      name: name ?? this.name,
      workDurationMinutes: workDurationMinutes ?? this.workDurationMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PomodoroSession(id: $id, name: $name, workDurationMinutes: $workDurationMinutes, shortBreakMinutes: $shortBreakMinutes, longBreakMinutes: $longBreakMinutes, sessionsCount: $sessionsCount, notificationEnabled: $notificationEnabled, alarmEnabled: $alarmEnabled, description: $description, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PomodoroSession &&
        other.id == id &&
        other.name == name &&
        other.workDurationMinutes == workDurationMinutes &&
        other.shortBreakMinutes == shortBreakMinutes &&
        other.longBreakMinutes == longBreakMinutes &&
        other.sessionsCount == sessionsCount &&
        other.notificationEnabled == notificationEnabled &&
        other.alarmEnabled == alarmEnabled &&
        other.description == description &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        workDurationMinutes.hashCode ^
        shortBreakMinutes.hashCode ^
        longBreakMinutes.hashCode ^
        sessionsCount.hashCode ^
        notificationEnabled.hashCode ^
        alarmEnabled.hashCode ^
        description.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // Helper methods
  String get workDurationDisplay {
    if (workDurationMinutes < 60) {
      return '${workDurationMinutes}m';
    } else {
      final hours = workDurationMinutes ~/ 60;
      final minutes = workDurationMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  String get shortBreakDisplay {
    return '${shortBreakMinutes}m';
  }

  String get longBreakDisplay {
    if (longBreakMinutes < 60) {
      return '${longBreakMinutes}m';
    } else {
      final hours = longBreakMinutes ~/ 60;
      final minutes = longBreakMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  // Calculate total time for all sessions including breaks
  int get totalMinutes {
    // Work sessions: workDurationMinutes * sessionsCount
    // Short breaks: shortBreakMinutes * (sessionsCount - 1)
    // Long breaks: Typically one long break after every 4 sessions
    final workTime = workDurationMinutes * sessionsCount;
    final shortBreaks = shortBreakMinutes * (sessionsCount - 1);
    final longBreaksCount = (sessionsCount / 4).floor();
    final longBreaks = longBreakMinutes * longBreaksCount;
    
    return workTime + shortBreaks + longBreaks;
  }

  String get totalTimeDisplay {
    final total = totalMinutes;
    if (total < 60) {
      return '${total}m';
    } else {
      final hours = total ~/ 60;
      final minutes = total % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  // Factory method for creating default pomodoro session
  factory PomodoroSession.defaultSession({String name = 'Default Session'}) {
    final now = DateTime.now();
    return PomodoroSession(
      name: name,
      workDurationMinutes: 25,
      shortBreakMinutes: 5,
      longBreakMinutes: 15,
      sessionsCount: 4,
      notificationEnabled: true,
      alarmEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}