import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/category_provider.dart';
import '../../database/database_manager.dart';
import '../../services/notification_service.dart';

// Custom exception classes for better error handling
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
}

class ProviderException implements Exception {
  final String message;
  ProviderException(this.message);
}

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> with TickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // State variables - exact default values from new design system
  String _selectedPriority = 'High';
  int _selectedHours = 0;
  int _selectedMinutes = 10;
  int _selectedNotificationHour = 7;
  int _selectedNotificationMinute = 30;
  String _selectedRepetition = 'Daily';
  String _selectedCategory = 'Health & Fitness'; // First item selected by default
  
  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _chipController;
  late Animation<double> _buttonScale;
  
  // Options lists
  final List<String> _priorityOptions = ['High', 'Medium', 'Low'];
  final List<String> _repetitionOptions = [
    'Daily',
    'Weekly',
    'Weekdays',
    'Weekends',
    'Every Other Day'
  ];
  final List<String> _categoryOptions = ['Health & Fitness', 'Learning', 'Social', 'Productivity', 'Mindfulness', 'Other'];

  @override
  void initState() {
    super.initState();
    
    // Animation setup from new design system
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150), // animations.quick.duration
      vsync: this,
    );
    
    _chipController = AnimationController(
      duration: const Duration(milliseconds: 200), // animations.standard.duration
      vsync: this,
    );
    
    _buttonScale = Tween<double>(
      begin: 1.0,
      end: 0.98, // states.interactive.pressed.scale
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut, // animations.quick.curve
    ));
    
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    if (!mounted) return;
    
    try {
      // Initialize category provider
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.initialize();
      
      // Initialize habit provider
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await habitProvider.initialize();
      
    } catch (e) {
      debugPrint('Error initializing providers: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buttonController.dispose();
    _chipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // layout.screen.backgroundColor
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: _buildScrollableBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        height: 80,
        color: const Color(0xFFFFFFFF), // primary.background
        child: SafeArea(
          child: Row(
            children: [
              // Back button - minimal arrow with padding
              Padding(
                padding: const EdgeInsets.only(left: 8), // Add left padding to align with screen content
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios, // navigation.type: minimal_arrow
                    size: 18,
                    color: Color(0xFF000000), // primary.text
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Title - centered
              Expanded(
                child: Center(
                  child: Text(
                    'Add Habit',
                    style: const TextStyle(
                      fontSize: 20, // Decreased header font size
                      fontWeight: FontWeight.w600, // typography.hierarchy.pageTitle.fontWeight
                      color: Color(0xFF000000), // typography.hierarchy.pageTitle.color
                    ),
                  ),
                ),
              ),
              // Right spacer to balance the back button
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), // Reduced top padding from 20 to 8
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          _buildNameField(),
          const SizedBox(height: 24), // Reduced section gap
          
          // Priority/Duration row
          _buildPriorityDurationRow(),
          const SizedBox(height: 16), // Further reduced spacing between dropdown rows
          
          // Notification/Repetition row
          _buildNotificationRepetitionRow(),
          const SizedBox(height: 24), // Reduced section gap
          
          // Category section
          _buildCategorySection(),
          const SizedBox(height: 24), // Reduced section gap
          
          // Description field
          _buildDescriptionField(),
          const SizedBox(height: 24), // Spacing before button
          
          // Create button
          _buildCreateButton(),
          const SizedBox(height: 20), // Bottom spacing for scroll content
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name',
          style: const TextStyle(
            fontSize: 16, // typography.hierarchy.sectionLabel.fontSize
            fontWeight: FontWeight.w600, // Matched to Category title font weight
            color: Color(0xFF000000), // typography.hierarchy.sectionLabel.color
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        Container(
          height: 56, // components.textInput.height
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // components.textInput.backgroundColor
            borderRadius: BorderRadius.circular(12), // Decreased border radius
            border: Border.all(
              color: const Color(0xFF000000), // components.textInput.border
              width: 2,
            ),
          ),
          child: Center(
            child: Semantics(
              label: 'Habit name input field',
              hint: 'Enter the name of your habit',
              textField: true,
              child: TextFormField(
                controller: _nameController,
                textAlign: TextAlign.start,
                textAlignVertical: TextAlignVertical.center,
                maxLength: 50,
                maxLines: 1,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // Hide counter
                inputFormatters: [
                  // Filter out control characters as user types
                  FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]')),
                  // Limit to reasonable characters
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-_.,!?()&]')),
                ],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF000000),
                  height: 1.0, // Set line height to prevent extra spacing
                ),
                decoration: InputDecoration(
                  hintText: 'Enter habit name', // formStructure.sections[0].placeholder
                hintStyle: const TextStyle(
                  fontSize: 16, // typography.hierarchy.placeholderText.fontSize
                  fontWeight: FontWeight.w400, // typography.hierarchy.placeholderText.fontWeight
                  color: Color(0xFF999999), // typography.hierarchy.placeholderText.color
                  height: 1.0, // Match the text height
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0, // Let Center widget handle vertical centering
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true, // Remove default vertical padding
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDurationRow() {
    return Row( // gridSystem.dualColumn
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Priority',
            value: _selectedPriority,
            options: _priorityOptions,
            backgroundColor: const Color(0xFFF5F5A3), // colorPalette.accent.yellow
            onChanged: (value) => setState(() => _selectedPriority = value!),
          ),
        ),
        const SizedBox(width: 16), // gridSystem.dualColumn.gap
        Expanded(
          child: _buildDurationPicker(),
        ),
      ],
    );
  }

  Widget _buildNotificationRepetitionRow() {
    return Row( // gridSystem.dualColumn
      children: [
        Expanded(
          child: _buildNotificationField(),
        ),
        const SizedBox(width: 16), // gridSystem.dualColumn.gap
        Expanded(
          child: _buildDropdownField(
            label: 'Repetition',
            value: _selectedRepetition,
            options: _repetitionOptions,
            backgroundColor: const Color(0xFFD4B5E8), // colorPalette.accent.purple
            onChanged: (value) => setState(() => _selectedRepetition = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required Color backgroundColor,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16, // typography.hierarchy.sectionLabel.fontSize
            fontWeight: FontWeight.w600, // Matched to Category title font weight
            color: Color(0xFF000000), // typography.hierarchy.sectionLabel.color
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        Container(
          height: 56, // components.pillButton.height
          decoration: BoxDecoration(
            color: backgroundColor, // components.pillButton.variants colors
            borderRadius: BorderRadius.circular(12), // Decreased border radius
          ),
          child: Center(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              items: options.map((option) => DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(
                    fontSize: 16, // typography.hierarchy.buttonText.fontSize
                    fontWeight: FontWeight.w500, // typography.hierarchy.buttonText.fontWeight
                    color: Color(0xFF000000), // pillButton.states.default.textColor
                  ),
                ),
              )).toList(),
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(
                  left: 20, // Left padding for text
                  right: 10, // Reduced right padding to give more space for arrow
                  top: 4,   // Small top padding for better visual centering
                  bottom: 0, // No bottom padding
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              icon: Padding(
                padding: const EdgeInsets.only(right: 16), // Add padding to position arrow better
                child: const Icon(
                  Icons.keyboard_arrow_down, // interactions.dropdowns.indicator: chevron_down
                  size: 20,
                  color: Color(0xFF000000),
                ),
              ),
              dropdownColor: const Color(0xFFFFFFFF),
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: const TextStyle(
            fontSize: 16, // typography.hierarchy.sectionLabel.fontSize
            fontWeight: FontWeight.w600, // Matched to Category title font weight
            color: Color(0xFF000000), // typography.hierarchy.sectionLabel.color
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        GestureDetector(
          onTap: _showDurationPicker,
          child: Container(
            height: 56, // components.pillButton.height
            decoration: BoxDecoration(
              color: const Color(0xFFB8C5E8), // colorPalette.accent.blue
              borderRadius: BorderRadius.circular(12), // Decreased border radius
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20, // Left padding to match other dropdowns
                right: 16, // Right padding for arrow positioning
                top: 4,   // Small top padding for better alignment
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDuration(_selectedHours, _selectedMinutes),
                      style: const TextStyle(
                        fontSize: 16, // typography.hierarchy.buttonText.fontSize
                        fontWeight: FontWeight.w500, // typography.hierarchy.buttonText.fontWeight
                        color: Color(0xFF000000), // pillButton.states.default.textColor
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down, // Same as other dropdowns
                    size: 20,
                    color: Color(0xFF000000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int hours, int minutes) {
    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  void _showDurationPicker() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _DurationPickerDialog(
        initialHours: _selectedHours,
        initialMinutes: _selectedMinutes,
        onDurationChanged: (hours, minutes) {
          if (mounted) {
            setState(() {
              _selectedHours = hours;
              _selectedMinutes = minutes;
            });
          }
        },
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category', // formStructure.sections[3].label
          style: const TextStyle(
            fontSize: 16, // typography.hierarchy.sectionLabel.fontSize
            fontWeight: FontWeight.w600, // typography.hierarchy.sectionLabel.fontWeight
            color: Color(0xFF000000), // typography.hierarchy.sectionLabel.color
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        _buildCategoryGrid(), // gridSystem.categoryGrid
      ],
    );
  }
  
  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 10, // Horizontal spacing between tags
      runSpacing: 10, // Vertical spacing between rows
      children: _categoryOptions.map((category) => _buildCategoryTag(category)).toList(),
    );
  }

  Widget _buildCategoryTag(String text) {
    // Check if this is the "Other" tag and if a custom category is selected
    final bool isOtherTag = text == 'Other';
    final bool isCustomCategorySelected = !_categoryOptions.contains(_selectedCategory);
    final bool isSelected = isOtherTag ? isCustomCategorySelected : _selectedCategory == text;
    
    // Display text: show custom category name if "Other" is selected, otherwise show original text
    final String displayText = (isOtherTag && isCustomCategorySelected) ? _selectedCategory : text;
    
    return GestureDetector(
      onTap: () {
        if (text == 'Other') {
          _showCreateCategoryDialog();
        } else {
          setState(() => _selectedCategory = text);
          // Removed size animation - only color change animation remains
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), // Reduced vertical padding
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFF2C2C2C) // components.categoryTag.states.selected.backgroundColor (accent.black)
            : const Color(0xFFFFFFFF), // components.categoryTag.states.unselected.backgroundColor
          borderRadius: BorderRadius.circular(8), // Further decreased border radius for categories
          border: Border.all(
            color: isSelected 
              ? const Color(0xFF2C2C2C) // Same color as background when selected to hide border
              : const Color(0xFF000000), // Visible border when unselected
            width: 2, // Keep consistent border width
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 16, // typography.hierarchy.buttonText.fontSize
            fontWeight: FontWeight.w500, // typography.hierarchy.buttonText.fontWeight
            color: isSelected 
              ? const Color(0xFFFFFFFF) // components.categoryTag.states.selected.textColor
              : const Color(0xFF000000), // components.categoryTag.states.unselected.textColor
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: const TextStyle(
            fontSize: 16, // typography.hierarchy.sectionLabel.fontSize
            fontWeight: FontWeight.w600, // Matched to Category title font weight
            color: Color(0xFF000000), // typography.hierarchy.sectionLabel.color
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        Container(
          constraints: const BoxConstraints(
            minHeight: 100, // Increased from 80 to make it taller
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // components.textArea.backgroundColor
            borderRadius: BorderRadius.circular(12), // Decreased border radius
            border: Border.all(
              color: const Color(0xFF000000), // components.textArea.border
              width: 2,
            ),
          ),
          child: Semantics(
            label: 'Habit description input field',
            hint: 'Enter a description for your habit',
            textField: true,
            multiline: true,
            child: TextFormField(
              controller: _descriptionController,
              maxLines: null,
              maxLength: 500,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // Hide counter
              textAlignVertical: TextAlignVertical.top,
              inputFormatters: [
                // Only filter out dangerous control characters but allow normal text input
                FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]')),
              ],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
                height: 1.4, // Better line height for multiline text
              ),
            decoration: InputDecoration(
              hintText: 'Enter your description', // formStructure.sections[4].placeholder
              hintStyle: const TextStyle(
                fontSize: 16, // typography.hierarchy.placeholderText.fontSize
                fontWeight: FontWeight.w400, // typography.hierarchy.placeholderText.fontWeight
                color: Color(0xFF999999), // components.textArea.placeholder.color
                height: 1.4, // Match text height
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, // Match the name field horizontal padding
                vertical: 16, // Proper vertical padding for multiline text
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification',
          style: const TextStyle(
            fontSize: 16, // typography.hierarchy.sectionLabel.fontSize
            fontWeight: FontWeight.w600, // typography.hierarchy.sectionLabel.fontWeight
            color: Color(0xFF000000), // typography.hierarchy.sectionLabel.color
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        GestureDetector(
          onTap: _showNotificationTimePicker,
          child: Container(
            height: 56, // components.dropdown.height
            decoration: BoxDecoration(
              color: const Color(0xFFA8D0E6), // colorPalette.accent.lightBlue
              borderRadius: BorderRadius.circular(12), // Decreased border radius
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20, // Left padding to match other dropdowns
                right: 16, // Right padding for arrow positioning
                top: 4,   // Small top padding for better alignment
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatNotificationTime(_selectedNotificationHour, _selectedNotificationMinute),
                      style: const TextStyle(
                        fontSize: 16, // typography.hierarchy.buttonText.fontSize
                        fontWeight: FontWeight.w500, // typography.hierarchy.buttonText.fontWeight
                        color: Color(0xFF000000), // pillButton.states.default.textColor
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down, // Same as other dropdowns
                    size: 20,
                    color: Color(0xFF000000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatNotificationTime(int hour, int minute) {
    // Validate inputs
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      debugPrint('Invalid time values: hour=$hour, minute=$minute');
      return '12:00 AM'; // Safe fallback
    }
    
    final period = hour >= 12 ? 'PM' : 'AM';
    // Fix 12-hour conversion: 0->12, 1-12->1-12, 13-23->1-11
    final displayHour = hour == 0 ? 12 : (hour <= 12 ? hour : hour - 12);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  void _showNotificationTimePicker() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _NotificationTimePickerDialog(
        initialHour: _selectedNotificationHour,
        initialMinute: _selectedNotificationMinute,
        onTimeChanged: (hour, minute) {
          if (mounted) {
            setState(() {
              _selectedNotificationHour = hour;
              _selectedNotificationMinute = minute;
            });
          }
        },
      ),
    );
  }

  Widget _buildCreateButton() {
    return AnimatedBuilder(
      animation: _buttonScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScale.value,
          child: SizedBox(
            width: double.infinity, // components.primaryButton.fullWidth
            height: 56, // components.primaryButton.height
            child: Semantics(
              label: 'Create habit button',
              hint: 'Tap to create your new habit',
              button: true,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _createHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C), // components.primaryButton.backgroundColor (accent.black)
                foregroundColor: const Color(0xFFFFFFFF), // components.primaryButton.textColor
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Decreased border radius
                ),
              ),
              child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create',
                style: TextStyle(
                  fontSize: 18, // components.primaryButton.fontSize
                  fontWeight: FontWeight.w600, // components.primaryButton.fontWeight
                  color: Color(0xFFFFFFFF), // components.primaryButton.textColor
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  bool _isSaving = false;

  void _createHabit() async {
    if (_isSaving) return; // Prevent double-tap
    
    try {
      if (mounted) setState(() => _isSaving = true);
      
      // Button press animation with safety checks
      if (mounted && !_buttonController.isAnimating) {
        try {
          await _buttonController.forward();
          if (mounted) {
            await _buttonController.reverse();
          }
        } catch (e) {
          // Animation controller may be disposed, ignore
        }
      }
      
      // Comprehensive validation
      String? error = _validateForm();
      if (error != null) {
        _showErrorDialog(error);
        return;
      }
      
      // Create habit object with validated data
      final habit = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority,
        'duration': {'hours': _selectedHours, 'minutes': _selectedMinutes},
        'notification': {
          'hour': _selectedNotificationHour,
          'minute': _selectedNotificationMinute
        },
        'repetition': _selectedRepetition,
        'category': _selectedCategory,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Save habit to database
      final habitId = await _saveHabitToDatabase(habit);
      
      if (habitId != null) {
        // Show success and navigate back to home
        _navigateToHomeWithSuccess();
      } else {
        _showErrorDialog('Failed to save habit. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Failed to create habit: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _navigateToHomeWithSuccess() {
    // Navigate back with success result
    Navigator.of(context).pop({
      'success': true,
      'message': 'Habit created successfully!',
    });
  }

  String _sanitizeInput(String input) {
    return input
        // Remove control characters and null bytes
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        // Remove HTML/XML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Remove script tags specifically
        .replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '')
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsInappropriateContent(String input) {
    // Basic profanity filter - in production, use a proper filtering service
    final inappropriate = ['test_bad_word']; // Placeholder
    final lowerInput = input.toLowerCase();
    return inappropriate.any((word) => lowerInput.contains(word));
  }

  bool _isDuplicateHabitName(String name) {
    // Check if habit name already exists
    // This would need to check against existing habits in the database
    // For now, return false - implement with actual habit list check
    return false;
  }

  String? _validateForm() {
    final rawName = _nameController.text;
    final rawDescription = _descriptionController.text;
    
    // Sanitize inputs
    final name = _sanitizeInput(rawName);
    final description = _sanitizeInput(rawDescription);
    
    // Check for actual content after sanitization
    if (name.replaceAll(RegExp(r'\s+'), '').isEmpty) {
      return 'Habit name cannot be empty or only whitespace';
    }
    
    // Length validation on sanitized content
    if (name.length < 2) {
      return 'Habit name must be at least 2 characters';
    }
    if (name.length > 50) {
      return 'Habit name must be 50 characters or less';
    }
    
    // Check byte length to prevent Unicode bomb attacks
    if (name.codeUnits.length > 200) {
      return 'Habit name contains too many characters';
    }
    
    // Inappropriate content check
    if (_containsInappropriateContent(name)) {
      return 'Please enter an appropriate habit name';
    }
    
    // Duplicate name check
    if (_isDuplicateHabitName(name)) {
      return 'A habit with this name already exists';
    }
    
    // Validate description
    if (description.length > 500) {
      return 'Description must be 500 characters or less';
    }
    if (description.codeUnits.length > 2000) {
      return 'Description contains too many characters';
    }
    
    // Validate duration
    if (_selectedHours == 0 && _selectedMinutes == 0) {
      return 'Duration must be at least 1 minute';
    }
    if (_selectedHours > 23 || _selectedMinutes > 59) {
      return 'Invalid duration values';
    }
    
    // Validate category
    final sanitizedCategory = _sanitizeInput(_selectedCategory);
    if (sanitizedCategory.isEmpty) {
      return 'Please select a category';
    }
    
    // Update sanitized values back to controllers
    if (rawName != name) {
      _nameController.text = name;
    }
    if (rawDescription != description) {
      _descriptionController.text = description;
    }
    
    return null; // All validations passed
  }

  Future<int?> _saveHabitToDatabase(Map<String, dynamic> habitData) async {
    if (!mounted) return null;
    
    try {
      // Validate context is still valid
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Sanitize data before database operations
      final sanitizedName = _sanitizeInput(habitData['name'] ?? '');
      final sanitizedDescription = _sanitizeInput(habitData['description'] ?? '');
      final sanitizedCategory = _sanitizeInput(_selectedCategory);
      
      if (sanitizedName.isEmpty) {
        throw ValidationException('Invalid habit name after sanitization');
      }
      
      // Convert duration to minutes with validation
      int durationMinutes = (_selectedHours * 60) + _selectedMinutes;
      if (durationMinutes <= 0 || durationMinutes > (24 * 60)) {
        throw ValidationException('Invalid duration: $durationMinutes minutes');
      }
      
      // Format notification time with validation
      if (_selectedNotificationHour < 0 || _selectedNotificationHour > 23 ||
          _selectedNotificationMinute < 0 || _selectedNotificationMinute > 59) {
        throw ValidationException('Invalid notification time');
      }
      String notificationTime = _formatNotificationTimeForDB(_selectedNotificationHour, _selectedNotificationMinute);
      
      // Map repetition pattern
      String repetitionPattern = _mapRepetitionPattern(_selectedRepetition);
      if (repetitionPattern.isEmpty) {
        throw ValidationException('Invalid repetition pattern');
      }
      
      // Transaction-like approach: Get/create category first
      int categoryId;
      try {
        categoryId = await _getCategoryIdSafely(categoryProvider, sanitizedCategory);
      } catch (e) {
        throw DatabaseException('Failed to handle category: ${e.toString()}');
      }
      
      if (categoryId == -1) {
        throw DatabaseException('Failed to get or create category');
      }
      
      // Handle custom days for "Every Other Day" 
      List<int> customDays = [];
      if (_selectedRepetition == 'Every Other Day') {
        // For "Every Other Day", we'll implement it as a custom pattern
        // This is complex - it requires tracking last completion date
        // For now, let's implement it as "Custom" with alternating days
        customDays = [1, 3, 5, 7]; // Mon, Wed, Fri, Sun as example
      }

      // Create habit with all validated data
      final habitId = await habitProvider.createHabit(
        name: sanitizedName,
        description: sanitizedDescription,
        categoryId: categoryId,
        priority: habitData['priority'] ?? 'Medium',
        durationMinutes: durationMinutes,
        notificationTime: notificationTime,
        repetitionPattern: repetitionPattern,
        customDays: customDays,
        startDate: DateTime.now(),
      );
      
      if (habitId == null) {
        throw DatabaseException('Failed to create habit - database returned null');
      }
      
      // Schedule notifications for the habit
      await _scheduleHabitNotifications(habitId, sanitizedName, repetitionPattern);
      
      return habitId;
      
    } on ValidationException catch (e) {
      debugPrint('Validation error in _saveHabitToDatabase: ${e.message}');
      if (mounted) {
        _showErrorDialog('Invalid data: ${e.message}');
      }
      return null;
    } on DatabaseException catch (e) {
      debugPrint('Database error in _saveHabitToDatabase: ${e.message}');
      if (mounted) {
        _showErrorDialog('Database error: ${e.message}');
      }
      return null;
    } on ProviderException catch (e) {
      debugPrint('Provider error in _saveHabitToDatabase: $e');
      if (mounted) {
        _showErrorDialog('Service error: Please try again later');
      }
      return null;
    } catch (e) {
      debugPrint('Unexpected error in _saveHabitToDatabase: $e');
      if (mounted) {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      }
      return null;
    }
  }

  Future<int> _getCategoryIdSafely(CategoryProvider categoryProvider, String categoryName) async {
    // Validate input
    if (categoryName.isEmpty) {
      throw ValidationException('Category name cannot be empty');
    }
    
    try {
      // Ensure category provider is initialized with a retry mechanism
      if (categoryProvider.categories.isEmpty) {
        debugPrint('Categories not loaded, initializing...');
        await categoryProvider.initialize();
        
        // If still empty after initialization, there's a serious problem
        if (categoryProvider.categories.isEmpty) {
          debugPrint('No categories after initialization. Resetting database...');
          // Try to reset to default categories
          final dbManager = DatabaseManager();
          await dbManager.dbHelper.resetDatabase();
          await categoryProvider.loadCategories();
        }
      }
      
      // Try to find existing category first
      final existingCategory = categoryProvider.getCategoryByName(categoryName);
      if (existingCategory != null && existingCategory.id != null) {
        debugPrint('Found existing category: ${existingCategory.name} with id: ${existingCategory.id}');
        return existingCategory.id!;
      }
      
      // For default categories, they should exist, so this is an error
      final defaultCategoryNames = ['Health & Fitness', 'Learning', 'Social', 'Productivity', 'Mindfulness', 'Other'];
      if (defaultCategoryNames.contains(categoryName)) {
        // Try to reload categories once more
        await categoryProvider.loadCategories();
        final retryCategory = categoryProvider.getCategoryByName(categoryName);
        if (retryCategory != null && retryCategory.id != null) {
          return retryCategory.id!;
        }
        
        // This should never happen - default category missing
        throw DatabaseException('Default category "$categoryName" not found in database. Please restart the app.');
      }
      
      // Create new category for custom ones with validation
      debugPrint('Creating new custom category: $categoryName');
      final categoryId = await categoryProvider.createCategory(
        name: categoryName.length > 30 ? categoryName.substring(0, 30) : categoryName,
        colorHex: '#FF6B35', // Default color
        iconName: 'more_horiz', // Default icon for custom categories
      );
      
      if (categoryId == null) {
        throw DatabaseException('Category creation returned null');
      }
      
      debugPrint('Successfully created category with ID: $categoryId');
      return categoryId;
      
    } catch (e) {
      debugPrint('Error in _getCategoryIdSafely: $e');
      if (e is ValidationException || e is DatabaseException) {
        rethrow;
      }
      throw DatabaseException('Failed to get or create category: ${e.toString()}');
    }
  }


  String _formatNotificationTimeForDB(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _mapRepetitionPattern(String repetition) {
    // Map our UI repetition options to database patterns that match Habit.shouldShowToday()
    switch (repetition) {
      case 'Daily':
        return 'Everyday';
      case 'Weekly':
        return 'Weekly'; // Note: May need custom implementation for weekly
      case 'Weekdays':
        return 'Weekdays';
      case 'Weekends':
        return 'Weekends';
      case 'Every Other Day':
        return 'Custom'; // Will need custom days implementation
      default:
        return 'Everyday';
    }
  }



  void _showCreateCategoryDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CreateCategoryDialog(
        onCategoryCreated: (categoryName) {
          if (mounted) {
            setState(() {
              _selectedCategory = categoryName;
            });
          }
        },
        onError: _showErrorDialog,
      ),
    );
  }

  Future<void> _scheduleHabitNotifications(int habitId, String habitName, String repetitionPattern) async {
    try {
      final notificationHour = _selectedNotificationHour;
      final notificationMinute = _selectedNotificationMinute;
      
      // Convert repetition pattern to weekdays
      List<int> weekdays = _getWeekdaysFromPattern(repetitionPattern);
      
      if (weekdays.isNotEmpty) {
        await NotificationService.scheduleRepeatingHabitReminder(
          habitId: habitId,
          habitName: habitName,
          weekdays: weekdays,
          hour: notificationHour,
          minute: notificationMinute,
        );
        debugPrint('Scheduled notifications for habit: $habitName at $notificationHour:$notificationMinute on days: $weekdays');
      }
    } catch (e) {
      debugPrint('Failed to schedule notifications for habit: $habitName - $e');
      // Don't fail the habit creation if notifications fail
    }
  }
  
  List<int> _getWeekdaysFromPattern(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'daily':
        return [1, 2, 3, 4, 5, 6, 7]; // Monday to Sunday
      case 'weekly':
        return [1]; // Monday only
      case 'weekdays':
        return [1, 2, 3, 4, 5]; // Monday to Friday
      case 'weekends':
        return [6, 7]; // Saturday and Sunday
      case 'every other day':
        return [1, 3, 5, 7]; // Mon, Wed, Fri, Sun
      default:
        return [1, 2, 3, 4, 5, 6, 7]; // Default to daily
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    // Sanitize error message to prevent displaying sensitive information
    final sanitizedMessage = _sanitizeErrorMessage(message);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFE53E3E)),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SingleChildScrollView(
            child: Text(
              sanitizedMessage,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _sanitizeErrorMessage(String message) {
    // Remove sensitive information from error messages
    return message
        .replaceAll(RegExp(r'Error:\s*'), '') // Remove "Error:" prefix
        .replaceAll(RegExp(r'Exception:\s*'), '') // Remove "Exception:" prefix
        .replaceAll(RegExp(r'\b\d{4,}\b'), '****') // Hide numbers that could be IDs
        .replaceAll(RegExp(r'path[:\s]*[^\s,;]+', caseSensitive: false), 'path: ****') // Hide file paths
        .trim();
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  final Function(String) onCategoryCreated;
  final Function(String) onError;

  const _CreateCategoryDialog({
    required this.onCategoryCreated,
    required this.onError,
  });

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Custom Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter a name for your custom category:'),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              hintText: 'Category name',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000), width: 2),
              ),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final categoryName = _categoryController.text.trim();
            if (categoryName.isNotEmpty && categoryName.length <= 30) {
              widget.onCategoryCreated(categoryName);
              Navigator.of(context).pop();
            } else if (categoryName.isEmpty) {
              widget.onError('Category name cannot be empty');
            } else {
              widget.onError('Category name must be 30 characters or less');
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _DurationPickerDialog extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;
  final Function(int hours, int minutes) onDurationChanged;

  const _DurationPickerDialog({
    required this.initialHours,
    required this.initialMinutes,
    required this.onDurationChanged,
  });

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int currentHours;
  late int currentMinutes;

  @override
  void initState() {
    super.initState();
    currentHours = widget.initialHours;
    currentMinutes = widget.initialMinutes;
  }

  String _formatDuration(int hours, int minutes) {
    if (hours == 0) {
      return '${minutes}m';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2C2C2C),
                    Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set your habit duration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content area
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Modern time display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF8F9FF),
                          Color(0xFFF0F2F5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE1E5E9),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: const Color(0xFF2C2C2C).withValues(alpha: 0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDuration(currentHours, currentMinutes),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2C),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
            
                  // Modern picker cards
                  Row(
                    children: [
                      // Hours card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE1E5E9),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000).withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Card header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FF),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Hours',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C2C2C),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Picker area
                              Container(
                                height: 120,
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  children: [
                                    // Selection highlight
                                    Center(
                                      child: Container(
                                        height: 40,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2C2C2C),
                                              Color(0xFF1A1A1A),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    // Scroll view
                                    ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(initialItem: currentHours),
                                      diameterRatio: 2.0,
                                      perspective: 0.002,
                                      onSelectedItemChanged: (index) {
                                        setState(() {
                                          currentHours = index;
                                        });
                                      },
                                      childDelegate: ListWheelChildBuilderDelegate(
                                        builder: (context, index) {
                                          if (index < 0 || index > 23) return null;
                                          final isSelected = index == currentHours;
                                          return Container(
                                            alignment: Alignment.center,
                                            child: Text(
                                              index.toString().padLeft(2, '0'),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected 
                                                  ? const Color(0xFFFFFFFF) 
                                                  : const Color(0xFF6C757D),
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Modern separator
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        height: 60,
                        width: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFE1E5E9),
                              Color(0xFF2C2C2C),
                              Color(0xFFE1E5E9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Minutes card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE1E5E9),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000).withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Card header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FF),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Minutes',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C2C2C),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Picker area
                              Container(
                                height: 120,
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  children: [
                                    // Selection highlight
                                    Center(
                                      child: Container(
                                        height: 40,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF2C2C2C),
                                              Color(0xFF1A1A1A),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    // Scroll view
                                    ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(initialItem: currentMinutes ~/ 5),
                                      diameterRatio: 2.0,
                                      perspective: 0.002,
                                      onSelectedItemChanged: (index) {
                                        setState(() {
                                          currentMinutes = index * 5;
                                        });
                                      },
                                      childDelegate: ListWheelChildBuilderDelegate(
                                        builder: (context, index) {
                                          if (index < 0 || index > 11) return null;
                                          final minutes = index * 5;
                                          final isSelected = minutes == currentMinutes;
                                          return Container(
                                            alignment: Alignment.center,
                                            child: Text(
                                              minutes.toString().padLeft(2, '0'),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected 
                                                  ? const Color(0xFFFFFFFF) 
                                                  : const Color(0xFF6C757D),
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Modern action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE1E5E9), width: 1),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C757D),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onDurationChanged(currentHours, currentMinutes);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2C2C),
                            foregroundColor: const Color(0xFFFFFFFF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Set Duration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTimePickerDialog extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final Function(int hour, int minute) onTimeChanged;

  const _NotificationTimePickerDialog({
    required this.initialHour,
    required this.initialMinute,
    required this.onTimeChanged,
  });

  @override
  State<_NotificationTimePickerDialog> createState() => _NotificationTimePickerDialogState();
}

class _NotificationTimePickerDialogState extends State<_NotificationTimePickerDialog> {
  late int currentHour;
  late int currentMinute;
  late bool isAM;

  @override
  void initState() {
    super.initState();
    isAM = widget.initialHour < 12;
    currentHour = widget.initialHour == 0 ? 12 : (widget.initialHour > 12 ? widget.initialHour - 12 : widget.initialHour);
    currentMinute = widget.initialMinute;
  }

  String _formatTime(int hour, int minute) {
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$hour:$displayMinute';
  }

  int get _current24Hour {
    // Validate currentHour is in expected range (1-12)
    if (currentHour < 1 || currentHour > 12) {
      debugPrint('Invalid currentHour: $currentHour, defaulting to 12');
      currentHour = 12;
    }
    
    if (currentHour == 12) {
      return isAM ? 0 : 12;
    }
    
    final result = isAM ? currentHour : currentHour + 12;
    
    // Validate result is in 24-hour range
    if (result < 0 || result > 23) {
      debugPrint('Invalid 24-hour conversion: $result, defaulting to 0');
      return 0;
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2C2C2C),
                    Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Notification Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set your reminder time',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content area
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Time display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8F9FF), Color(0xFFF0F2F5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE1E5E9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_rounded, color: const Color(0xFF2C2C2C).withValues(alpha: 0.6), size: 20),
                        const SizedBox(width: 12),
                        Text(_formatTime(currentHour, currentMinute), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Picker cards
                  Row(
                    children: [
                      // Hour picker
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE1E5E9)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FF),
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                                ),
                                child: const Text('Hour', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C))),
                              ),
                              Container(
                                height: 120,
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Container(
                                        height: 40,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)]),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(initialItem: currentHour - 1),
                                      diameterRatio: 2.0,
                                      perspective: 0.002,
                                      onSelectedItemChanged: (index) => setState(() => currentHour = index + 1),
                                      childDelegate: ListWheelChildBuilderDelegate(
                                        builder: (context, index) {
                                          if (index < 0 || index > 11) return null;
                                          final hour = index + 1;
                                          final isSelected = hour == currentHour;
                                          return Container(
                                            alignment: Alignment.center,
                                            child: Text('$hour', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF6C757D))),
                                          );
                                        },
                                        childCount: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Minute picker
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE1E5E9)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F9FF),
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                                ),
                                child: const Text('Minute', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C))),
                              ),
                              Container(
                                height: 120,
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Container(
                                        height: 40,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)]),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(initialItem: currentMinute),
                                      diameterRatio: 2.0,
                                      perspective: 0.002,
                                      onSelectedItemChanged: (index) => setState(() => currentMinute = index),
                                      childDelegate: ListWheelChildBuilderDelegate(
                                        builder: (context, index) {
                                          if (index < 0 || index > 59) return null;
                                          final isSelected = index == currentMinute;
                                          return Container(
                                            alignment: Alignment.center,
                                            child: Text(index.toString().padLeft(2, '0'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF6C757D))),
                                          );
                                        },
                                        childCount: 60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // AM/PM picker
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE1E5E9)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F9FF),
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                              ),
                              child: const Text('Period', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C2C2C))),
                            ),
                            Container(
                              height: 120,
                              padding: const EdgeInsets.all(8),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Container(
                                      height: 40,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  ListWheelScrollView.useDelegate(
                                    itemExtent: 40,
                                    physics: const FixedExtentScrollPhysics(),
                                    controller: FixedExtentScrollController(initialItem: isAM ? 0 : 1),
                                    diameterRatio: 2.0,
                                    perspective: 0.002,
                                    onSelectedItemChanged: (index) => setState(() => isAM = index == 0),
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      builder: (context, index) {
                                        if (index < 0 || index > 1) return null;
                                        final period = index == 0 ? 'AM' : 'PM';
                                        final isSelected = (index == 0 && isAM) || (index == 1 && !isAM);
                                        return Container(
                                          alignment: Alignment.center,
                                          child: Text(period, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF6C757D))),
                                        );
                                      },
                                      childCount: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE1E5E9))),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6C757D))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onTimeChanged(_current24Hour, currentMinute);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C2C2C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Set Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}