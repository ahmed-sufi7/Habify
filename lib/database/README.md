# Habify Database Schema Documentation

This document provides comprehensive information about the Habify app's SQLite database implementation.

## Overview

The database is designed to support all features mentioned in the app requirements:
- Habit creation with categories, priorities, schedules, and notifications
- Habit tracking with streak calculations and completion status
- Pomodoro sessions with timer functionality and history
- Notification management for reminders and celebrations
- Comprehensive statistics and analytics

## Database Architecture

### Core Components

1. **DatabaseHelper** (`database_helper.dart`)
   - Manages SQLite database connection and lifecycle
   - Handles table creation, migrations, and maintenance
   - Provides low-level database operations

2. **Models** (`models/`)
   - Data models for all entities
   - Includes validation and serialization methods
   - Supports business logic helpers

3. **DAOs** (`daos/`)
   - Data Access Objects for each entity
   - Comprehensive CRUD operations
   - Advanced querying and analytics

4. **Services** (`services/database/`)
   - High-level business logic operations
   - Cross-entity workflows
   - Data integrity and validation

5. **DatabaseManager** (`database_manager.dart`)
   - Centralized access point
   - Initialization and cleanup
   - Health monitoring and maintenance

## Database Schema

### Tables

#### 1. Categories
```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  color_hex TEXT NOT NULL DEFAULT '#2C2C2C',
  icon_name TEXT NOT NULL DEFAULT 'category',
  is_default INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Purpose**: Store habit categories (Knowledge, Health, Professional, etc.)
**Default Data**: 6 pre-defined categories from design specifications

#### 2. Habits
```sql
CREATE TABLE habits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category_id INTEGER NOT NULL,
  priority TEXT NOT NULL DEFAULT 'Do First',
  duration_minutes INTEGER NOT NULL DEFAULT 10,
  notification_time TEXT NOT NULL DEFAULT '07:30',
  alarm_time TEXT,
  repetition_pattern TEXT NOT NULL DEFAULT 'Everyday',
  custom_days TEXT DEFAULT '',
  start_date TEXT NOT NULL,
  end_date TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id)
)
```

**Purpose**: Store habit definitions with scheduling and notification preferences
**Features**: 
- Priority levels (Do First, Schedule, Delegate, Eliminate)
- Flexible repetition patterns (Daily, Weekdays, Custom days)
- Optional end dates for time-bound habits

#### 3. Habit Completions
```sql
CREATE TABLE habit_completions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habit_id INTEGER NOT NULL,
  completion_date TEXT NOT NULL,
  completed_at TEXT,
  streak_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'completed',
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
  UNIQUE (habit_id, completion_date)
)
```

**Purpose**: Track daily habit completion status
**Features**:
- Streak counting and tracking
- Status: completed, missed, skipped
- Optional notes for each completion

#### 4. Pomodoro Sessions
```sql
CREATE TABLE pomodoro_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  work_duration_minutes INTEGER NOT NULL DEFAULT 25,
  short_break_minutes INTEGER NOT NULL DEFAULT 5,
  long_break_minutes INTEGER NOT NULL DEFAULT 15,
  sessions_count INTEGER NOT NULL DEFAULT 4,
  notification_enabled INTEGER NOT NULL DEFAULT 1,
  alarm_enabled INTEGER NOT NULL DEFAULT 0,
  description TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Purpose**: Define Pomodoro timer configurations
**Features**:
- Customizable work and break durations
- Session sequences with long break intervals
- Notification and alarm preferences

#### 5. Pomodoro Completions
```sql
CREATE TABLE pomodoro_completions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  session_number INTEGER NOT NULL DEFAULT 1,
  session_type TEXT NOT NULL DEFAULT 'work',
  actual_duration_minutes INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES pomodoro_sessions (id)
)
```

**Purpose**: Track individual Pomodoro session executions
**Features**:
- Work sessions and break tracking
- Actual vs planned duration tracking
- Session sequencing and completion status

#### 6. Notifications
```sql
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  scheduled_time TEXT NOT NULL,
  is_sent INTEGER NOT NULL DEFAULT 0,
  is_read INTEGER NOT NULL DEFAULT 0,
  habit_id INTEGER,
  pomodoro_session_id INTEGER,
  data TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (habit_id) REFERENCES habits (id),
  FOREIGN KEY (pomodoro_session_id) REFERENCES pomodoro_sessions (id)
)
```

**Purpose**: Manage scheduled notifications and alerts
**Features**:
- Multiple notification types (habit reminders, streak celebrations, Pomodoro alerts)
- Scheduling and delivery tracking
- Rich notification data support

## Performance Features

### Indexes
- Optimized queries for common operations
- Efficient filtering by date ranges
- Fast category and status lookups

### Database Maintenance
- Automatic cleanup of old data
- Health monitoring and integrity checks
- Export/import capabilities

## Usage Examples

### Basic Setup
```dart
// Initialize database
final dbManager = DatabaseManager();
await dbManager.initialize();

// Create a habit
final habitId = await dbManager.habitService.createHabit(
  name: 'Morning Exercise',
  description: '30 minutes of cardio',
  categoryId: healthCategoryId,
  priority: 'Do First',
  durationMinutes: 30,
  notificationTime: '07:00',
  repetitionPattern: 'Weekdays',
  startDate: DateTime.now(),
);

// Complete the habit
await dbManager.habitService.completeHabit(habitId);

// Get today's habits
final todayHabits = await dbManager.habitService.getTodayHabits();
```

### Advanced Operations
```dart
// Get comprehensive dashboard data
final dashboard = await dbManager.getDashboardData();

// Run database health check
final health = await dbManager.checkDatabaseHealth();

// Export all data
final exportData = await dbManager.exportAllData();

// Run maintenance
await dbManager.performMaintenance();
```

## Testing

The database includes comprehensive testing via `DatabaseTestService`:

```dart
final testService = DatabaseTestService();
final results = await testService.runAllTests();
```

Test coverage includes:
- CRUD operations for all entities
- Business logic validation
- Data integrity checks
- Integration scenarios
- Performance validation

## Migration Strategy

The database uses version-based migrations:
- Current version: 1
- Future migrations handled in `_onUpgrade` method
- Backward compatibility support

## Data Validation

Comprehensive validation at multiple levels:
- Model-level validation (required fields, data types)
- Business logic validation (date ranges, dependencies)
- Database constraints (foreign keys, unique constraints)

## Security Considerations

- SQL injection prevention through parameterized queries
- Data sanitization for user inputs
- Proper foreign key constraints for data integrity

## Performance Characteristics

- Optimized for mobile device constraints
- Efficient indexing for common query patterns
- Minimal memory footprint
- Fast startup and initialization

## File Structure

```
lib/
├── database/
│   ├── database_helper.dart          # Core database management
│   ├── database_manager.dart         # Centralized access point
│   └── daos/                        # Data Access Objects
│       ├── category_dao.dart
│       ├── habit_dao.dart
│       ├── habit_completion_dao.dart
│       ├── pomodoro_dao.dart
│       └── notification_dao.dart
├── models/                          # Data models
│   ├── category.dart
│   ├── habit.dart
│   ├── habit_completion.dart
│   ├── pomodoro_session.dart
│   ├── pomodoro_completion.dart
│   └── notification.dart
└── services/database/               # Business logic services
    ├── habit_service.dart
    ├── pomodoro_service.dart
    ├── notification_service.dart
    └── database_test_service.dart
```

## Integration Points

The database integrates with:
- Flutter Local Notifications for reminders
- Firebase for push notifications (planned)
- State management providers
- Analytics and statistics screens
- Data export/import features

## Future Enhancements

Planned improvements:
- Cloud synchronization support
- Advanced analytics and insights
- Data backup and restore
- Performance optimizations
- Additional notification types

---

This database implementation provides a robust foundation for the Habify app, supporting all current requirements while being extensible for future features.