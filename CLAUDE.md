# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Habify is a Flutter-based habit tracking mobile application. The project is in its initial setup phase with a standard Flutter starter template and comprehensive design system documentation.

## Development Commands

### Essential Commands
- `flutter run` - Run the app in debug mode with hot reload
- `flutter analyze` - Run static analysis and linting (MUST pass before commits)
- `flutter test` - Run all widget tests
- `flutter pub get` - Install dependencies (run after pulling changes)
- `flutter clean && flutter pub get` - Clean rebuild when dependencies change

### Build Commands
- `flutter build apk` - Build debug APK for Android
- `flutter build apk --release` - Build release APK for Android
- `flutter build ios --release` - Build release for iOS

### Testing & Analysis
- `flutter test` - Run all widget tests 
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter test --coverage` - Run tests with coverage report

## Architecture Overview

### Project Structure
- `lib/` - Main Dart code (currently contains only starter template)
- `test/` - Test files
- `DesignFiles/` - JSON design system specifications
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` - Platform-specific code

### Design System
The project includes comprehensive design system documentation in JSON format located in `DesignFiles/`:
- `home_design.json` - Complete home screen design specification with color palette, typography, and component specs
- `add_habit_design.json` - Add habit form design with field layouts and category selection
- Additional design files for various screens (calendar, statistics, Pomodoro, etc.)

**IMPORTANT**: Always reference these JSON files when implementing UI components to maintain design consistency.

Key design system elements:
- **Colors**: Primary orange (#FF6B35) and green (#4CAF50) theme
- **Typography**: System fonts with specific weights and sizes defined per component
- **Components**: Habit cards, streak indicators, progress grids, bottom navigation with exact dimensions
- **Spacing**: Consistent spacing system (2-32px values)
- **Border Radius**: Rounded corners throughout (4-50px depending on component)

### Current State
- Basic Flutter template structure
- No custom features implemented yet
- Standard Material Design setup
- Includes flutter_lints for code quality

### Dependencies
- `cupertino_icons: ^1.0.8` - iOS-style icons
- `flutter_lints: ^5.0.0` - Linting rules (dev dependency)

## Development Guidelines

### Code Style
- Uses `analysis_options.yaml` with `package:flutter_lints/flutter.yaml`
- Follow Flutter/Dart conventions
- Material Design components preferred

### Design Implementation
- Reference design system JSON files when implementing UI components
- Maintain consistency with specified color palette and typography
- Use the defined spacing and border radius values

### App Features (Planned)
Based on design files, the app will include:
- Habit tracking with streak counters
- Category-based habit organization
- Progress visualization
- Notification system
- Statistics and analytics
- Calendar integration
- Pomodoro timer functionality

## Task Master AI Integration (Optional)

**Status**: Not yet initialized in this project.

To enable Task Master AI workflow management:

1. Initialize Task Master: `task-master init`
2. Create PRD document: `.taskmaster/docs/prd.txt`
3. Parse tasks: `task-master parse-prd .taskmaster/docs/prd.txt`
4. Configure models: `task-master models --setup`

Once initialized, Task Master provides:
- Structured task management with hierarchical IDs (1.1, 1.2, etc.)
- AI-powered task breakdown and complexity analysis
- Integration with Claude Code via MCP server
- Automated task tracking and status management

**Key Commands** (after initialization):
- `task-master next` - Get next available task
- `task-master show <id>` - View task details
- `task-master set-status --id=<id> --status=done` - Mark complete

**Integration**: Task Master guidelines will be automatically imported from `.taskmaster/CLAUDE.md` once initialized.

#Prompy
**Prompt Memory**:
Create a habit tracking mobile flutter app that helps to create track manage and build habits by tracking daily progress visualizing streaks and maintaining motivation. 


Key App features:
1\. Habit creation:  Habit creation with options like Habit priority, Habit duration,  reminding notification and alaram, repetition, Habit categories and habit description, Start date and end date.

2\. Habit tracking: Habit tracking using habits streak, Habit Calendar an hybrid calendar timeline, Dot calendar grid matrix For habit progress tracking And a toggle button go to mark the habit complete

3\. statistics screen: A statistics screen Showing total habits. total completed, Habit Statistics graph, Total missed habits etc

4\. reminders: Remainders in the form of notification and alarms To help the user stay on the track. And get reminder the habit

5\. No authentification

6.habit details: Habit details screen showing details like habit category, a habit streak, Habit completed missed and highest streaks and completion rate.

7\. A notification screen

8\. Pomodoro creation screen and Pomodoro timer screen: User can create pomodoro with name duration duration rest slot notification sessions etc And pomodoro timer screen With duration details and session history.

9\. Activity History screen showing Habit history and Pomodoro history.

10\. Google Ads

11\. Firebase push notification



**App creation Workflow: (start with the first continue to last)**
1\. App Launch

2\. Intro screen for the new users. (refer introdesign.json file for design of this screen)

3\. Add habit screen (refer  add\_habit\_design.json file for design of  this screen)

4\. Home screen  (refer  home\_design.json file for design of  this screen)

5\. Statistics screen (refer  statistic\_design.json file for design of  this screen)

6\. Habit details screen (refer  Habit\_details.json file for design of  this screen)

7\. Add Pomodaro screen (refer  pomodaro\_design.json file for design of  this screen)

8\. Pomodoro timer screen (refer  pomodaro\_design.json file for design of  this screen)

9\. Notification screen (refer  notification\_design.json file for design of  this screen)

10\. Menu sidebar

11\. Activity History screen (refer  activity\_history\_design.json file for design of  this screen)


**Key Points to remember:**
1\. For every screen there is a separate design Json file, You have to refer to the Particular attached design Json file for the every screen design.

2\. As the design json file is present for every screen you have to replicating the design from the referenced design json file and most important add the functionalities to the design
4. All the functionalities of the app should be build 

3\. This app is a complete flutter mobile android application
4. App Name is Habify - Habit tracking app
