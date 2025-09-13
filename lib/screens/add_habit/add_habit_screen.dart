import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/category_provider.dart';
import '../../database/database_manager.dart';
import '../../services/notification_service.dart';
import '../../services/admob_service.dart';

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
  int _selectedNotificationHour = 19;
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
      // Store providers before async operations
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      
      // Initialize category provider
      await categoryProvider.initialize();
      
      // Initialize habit provider
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
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: _buildScrollableBody(),
            ),
          ),
          // Fixed button at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: _buildCreateButton(),
          ),
        ],
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
          const SizedBox(height: 24), // Bottom spacing for scroll content
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Name',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
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
              width: 1.5,
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
                  vertical: 16, // Proper vertical padding for easier touch
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        GestureDetector(
          onTap: () => _showDropdownPicker(label, value, options, onChanged),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
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

  void _showDropdownPicker(String label, String currentValue, List<String> options, void Function(String?) onChanged) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            'Select $label',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                'Choose your preferred ${label.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 16),
              // Options list with iOS-style separators
              ...options.asMap().entries.map((entry) {
                final int index = entry.key;
                final String option = entry.value;
                final bool isSelected = currentValue == option;
                final bool isLast = index == options.length - 1;
                
                return Column(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      onPressed: () {
                        onChanged(option);
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? CupertinoColors.systemBlue
                                  : CupertinoColors.label,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              CupertinoIcons.checkmark,
                              color: CupertinoColors.systemBlue,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        height: 0.5,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: CupertinoColors.separator,
                      ),
                  ],
                );
              }),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatDuration(_selectedHours, _selectedMinutes),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
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
    
    showCupertinoDialog<void>(
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
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
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
            width: 1.5, // Keep consistent border width
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
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
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
              width: 1.5,
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
        const Text(
          'Notification',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatNotificationTime(_selectedNotificationHour, _selectedNotificationMinute),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
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
    
    showCupertinoDialog<void>(
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
              child: CupertinoButton(
                onPressed: _isSaving ? null : _createHabit,
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isSaving ? CupertinoColors.inactiveGray : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Create Habit',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
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
    // Show interstitial ad after habit creation
    AdMobService().showAdAfterHabitCreation(
      onAdClosed: () {
        // Navigate back with success result after ad closes
        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'message': 'Habit created successfully!',
          });
        }
      },
    );
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
    
    showCupertinoDialog<void>(
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
    
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Error',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              sanitizedMessage,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.label,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),
          ],
        );
      },
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
    return CupertinoAlertDialog(
      title: const Text(
        'Create Custom Category',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        height: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter category name:',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _categoryController,
              placeholder: 'Category name',
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              scrollPhysics: const NeverScrollableScrollPhysics(),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: CupertinoColors.systemBlue,
              fontSize: 17,
            ),
          ),
        ),
        CupertinoDialogAction(
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
          isDefaultAction: true,
          child: const Text(
            'Create',
            style: TextStyle(
              color: CupertinoColors.systemBlue,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    return CupertinoAlertDialog(
      title: const Text(
        'Set Duration',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 280,
        height: 250,
        child: Column(
          children: [
            const SizedBox(height: 4),
            const Text(
              'Choose hours and minutes for your habit',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 20),
            // Current selection display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.time,
                    color: CupertinoColors.systemBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(currentHours, currentMinutes),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // iOS-style duration picker with vertical scrolling
            Expanded(
              child: Row(
                children: [
                  // Hour picker
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32.0,
                            scrollController: FixedExtentScrollController(
                              initialItem: currentHours,
                            ),
                            onSelectedItemChanged: (int value) {
                              setState(() {
                                currentHours = value;
                              });
                            },
                            children: List<Widget>.generate(24, (int index) {
                              return Center(
                                child: Text(
                                  '$index',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Minutes picker
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Minutes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32.0,
                            scrollController: FixedExtentScrollController(
                              initialItem: currentMinutes,
                            ),
                            onSelectedItemChanged: (int value) {
                              setState(() {
                                currentMinutes = value;
                              });
                            },
                            children: List<Widget>.generate(60, (int index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
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
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            widget.onDurationChanged(currentHours, currentMinutes);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Set Duration',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ),
      ],
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

  int get _current24Hour => isAM ? (currentHour == 12 ? 0 : currentHour) : (currentHour == 12 ? 12 : currentHour + 12);

  String _formatTime(int hour, int minute) {
    final displayHour = hour == 0 ? 12 : (hour <= 12 ? hour : hour - 12);
    final displayMinute = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$displayHour:$displayMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        'Set Notification Time',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 280,
        height: 250,
        child: Column(
          children: [
            const SizedBox(height: 4),
            const Text(
              'Choose when to receive habit reminders',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 20),
            // Current time display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.bell,
                    color: CupertinoColors.systemBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(_current24Hour, currentMinute),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // iOS-style time picker with vertical scrolling
            Expanded(
              child: Row(
                children: [
                  // Hour picker
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Hour',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32.0,
                            scrollController: FixedExtentScrollController(
                              initialItem: currentHour - 1,
                            ),
                            onSelectedItemChanged: (int value) {
                              setState(() {
                                currentHour = value + 1;
                              });
                            },
                            children: List<Widget>.generate(12, (int index) {
                              return Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Minute picker
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Minute',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32.0,
                            scrollController: FixedExtentScrollController(
                              initialItem: currentMinute,
                            ),
                            onSelectedItemChanged: (int value) {
                              setState(() {
                                currentMinute = value;
                              });
                            },
                            children: List<Widget>.generate(60, (int index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // AM/PM picker
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Period',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 32.0,
                            scrollController: FixedExtentScrollController(
                              initialItem: isAM ? 0 : 1,
                            ),
                            onSelectedItemChanged: (int value) {
                              setState(() {
                                isAM = value == 0;
                              });
                            },
                            children: const [
                              Center(
                                child: Text(
                                  'AM',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'PM',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
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
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            widget.onTimeChanged(_current24Hour, currentMinute);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Set Time',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ),
      ],
    );
  }
}

