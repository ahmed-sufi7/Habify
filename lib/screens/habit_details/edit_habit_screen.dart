import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/habit.dart';
import '../../services/notification_service.dart';

class EditHabitScreen extends StatefulWidget {
  final Habit habit;

  const EditHabitScreen({
    super.key,
    required this.habit,
  });

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> with TickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // State variables
  late String _selectedPriority;
  late int _selectedHours;
  late int _selectedMinutes;
  late int _selectedNotificationHour;
  late int _selectedNotificationMinute;
  late String _selectedRepetition;
  late String _selectedCategory;
  
  // Animation controllers
  late AnimationController _buttonController;
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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize form with current habit data
    _nameController.text = widget.habit.name;
    _descriptionController.text = widget.habit.description;
    _selectedPriority = widget.habit.priority;
    _selectedHours = widget.habit.durationMinutes ~/ 60;
    _selectedMinutes = widget.habit.durationMinutes % 60;
    _selectedRepetition = _mapDbRepetitionToUI(widget.habit.repetitionPattern);
    _selectedCategory = _getCategoryName(widget.habit.categoryId);
    
    // Parse notification time
    final timeParts = widget.habit.notificationTime.split(':');
    _selectedNotificationHour = int.parse(timeParts[0]);
    _selectedNotificationMinute = int.parse(timeParts[1]);
    
    // Animation setup
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _buttonScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  String _mapDbRepetitionToUI(String dbPattern) {
    switch (dbPattern) {
      case 'Everyday':
        return 'Daily';
      case 'Weekdays':
        return 'Weekdays';
      case 'Weekends':
        return 'Weekends';
      case 'Weekly':
        return 'Weekly';
      case 'Custom':
        return 'Every Other Day';
      default:
        return 'Daily';
    }
  }

  String _getCategoryName(int categoryId) {
    switch (categoryId) {
      case 1:
        return 'Health & Fitness';
      case 2:
        return 'Learning';
      case 3:
        return 'Social';
      case 4:
        return 'Productivity';
      case 5:
        return 'Mindfulness';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
        color: const Color(0xFFFFFFFF),
        child: SafeArea(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 18,
                    color: Color(0xFF000000),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Edit Habit',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameField(),
          const SizedBox(height: 24),
          
          _buildPriorityDurationRow(),
          const SizedBox(height: 16),
          
          _buildNotificationRepetitionRow(),
          const SizedBox(height: 24),
          
          _buildCategorySection(),
          const SizedBox(height: 24),
          
          _buildDescriptionField(),
          const SizedBox(height: 24),
          
          _buildUpdateButton(),
          const SizedBox(height: 20),
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF000000),
              width: 1.5,
            ),
          ),
          child: Center(
            child: TextFormField(
              controller: _nameController,
              textAlign: TextAlign.start,
              textAlignVertical: TextAlignVertical.center,
              maxLength: 50,
              maxLines: 1,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]')),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-_.,!?()&]')),
              ],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
                height: 1.0,
              ),
              decoration: InputDecoration(
                hintText: 'Enter habit name',
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF999999),
                  height: 1.0,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDurationRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            label: 'Priority',
            value: _selectedPriority,
            options: _priorityOptions,
            backgroundColor: const Color(0xFFF5F5A3),
            onChanged: (value) => setState(() => _selectedPriority = value!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDurationPicker(),
        ),
      ],
    );
  }

  Widget _buildNotificationRepetitionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildNotificationField(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdownField(
            label: 'Repetition',
            value: _selectedRepetition,
            options: _repetitionOptions,
            backgroundColor: const Color(0xFFD4B5E8),
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
        const SizedBox(height: 6),
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
        Text(
          'Duration',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showDurationPicker,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFB8C5E8),
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildNotificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showNotificationTimePicker,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFA8D0E6),
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        _buildCategoryGrid(),
      ],
    );
  }
  
  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categoryOptions.map((category) => _buildCategoryTag(category)).toList(),
    );
  }

  Widget _buildCategoryTag(String text) {
    final bool isOtherTag = text == 'Other';
    final bool isCustomCategorySelected = !_categoryOptions.contains(_selectedCategory);
    final bool isSelected = isOtherTag ? isCustomCategorySelected : _selectedCategory == text;
    final String displayText = (isOtherTag && isCustomCategorySelected) ? _selectedCategory : text;
    
    return GestureDetector(
      onTap: () {
        if (text == 'Other') {
          _showCreateCategoryDialog();
        } else {
          setState(() => _selectedCategory = text);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? const Color(0xFF2C2C2C)
              : const Color(0xFF000000),
            width: 1.5,
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected 
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF000000),
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(
            minHeight: 100,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF000000),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: null,
            maxLength: 500,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            textAlignVertical: TextAlignVertical.top,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]')),
            ],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF000000),
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your description',
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
                height: 1.4,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return AnimatedBuilder(
      animation: _buttonScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScale.value,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _updateHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: const Color(0xFFFFFFFF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
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
                    'Update Habit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
            ),
          ),
        );
      },
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

  String _formatNotificationTime(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return '12:00 AM';
    }
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour <= 12 ? hour : hour - 12);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
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

  void _updateHabit() async {
    if (_isSaving) return;
    
    try {
      if (mounted) setState(() => _isSaving = true);
      
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
      
      String? error = _validateForm();
      if (error != null) {
        _showErrorDialog(error);
        return;
      }
      
      if (!mounted) return;
      
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      
      // Get category ID
      int categoryId = await _getCategoryId(categoryProvider, _selectedCategory);
      
      // Calculate duration in minutes
      int durationMinutes = (_selectedHours * 60) + _selectedMinutes;
      
      // Format notification time
      String notificationTime = '${_selectedNotificationHour.toString().padLeft(2, '0')}:${_selectedNotificationMinute.toString().padLeft(2, '0')}';
      
      // Map repetition pattern
      String repetitionPattern = _mapRepetitionPattern(_selectedRepetition);
      
      // Update habit
      final success = await habitProvider.updateHabitById(
        id: widget.habit.id!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: categoryId,
        priority: _selectedPriority,
        durationMinutes: durationMinutes,
        notificationTime: notificationTime,
        repetitionPattern: repetitionPattern,
      );
      
      if (success) {
        // Update notifications with new time and repetition pattern
        await _updateHabitNotifications(
          widget.habit.id!,
          _nameController.text.trim(),
          repetitionPattern,
        );
        _navigateBackWithSuccess();
      } else {
        _showErrorDialog('Failed to update habit. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Failed to update habit: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateHabitNotifications(int habitId, String habitName, String repetitionPattern) async {
    try {
      // First, cancel all existing notifications for this habit
      await NotificationService.cancelHabitNotifications(habitId);
      
      // Then schedule new notifications with updated time and pattern
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
        debugPrint('Updated notifications for habit: $habitName at $notificationHour:$notificationMinute on days: $weekdays');
      }
    } catch (e) {
      debugPrint('Failed to update notifications for habit: $habitName - $e');
      // Don't fail the habit update if notifications fail
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

  void _navigateBackWithSuccess() {
    Navigator.of(context).pop({
      'success': true,
      'message': 'Habit updated successfully!',
    });
  }

  String? _validateForm() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    
    if (name.isEmpty) {
      return 'Habit name cannot be empty';
    }
    
    if (name.length < 2) {
      return 'Habit name must be at least 2 characters';
    }
    if (name.length > 50) {
      return 'Habit name must be 50 characters or less';
    }
    
    if (description.length > 500) {
      return 'Description must be 500 characters or less';
    }
    
    if (_selectedHours == 0 && _selectedMinutes == 0) {
      return 'Duration must be at least 1 minute';
    }
    if (_selectedHours > 23 || _selectedMinutes > 59) {
      return 'Invalid duration values';
    }
    
    return null;
  }

  Future<int> _getCategoryId(CategoryProvider categoryProvider, String categoryName) async {
    final existingCategory = categoryProvider.getCategoryByName(categoryName);
    if (existingCategory != null && existingCategory.id != null) {
      return existingCategory.id!;
    }
    
    // For custom categories, create them
    final categoryId = await categoryProvider.createCategory(
      name: categoryName.length > 30 ? categoryName.substring(0, 30) : categoryName,
      colorHex: '#FF6B35',
      iconName: 'more_horiz',
    );
    
    return categoryId ?? 1; // Default to first category if creation fails
  }

  String _mapRepetitionPattern(String repetition) {
    switch (repetition) {
      case 'Daily':
        return 'Everyday';
      case 'Weekly':
        return 'Weekly';
      case 'Weekdays':
        return 'Weekdays';
      case 'Weekends':
        return 'Weekends';
      case 'Every Other Day':
        return 'Custom';
      default:
        return 'Everyday';
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
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
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Reuse the dialog components from add_habit_screen.dart
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