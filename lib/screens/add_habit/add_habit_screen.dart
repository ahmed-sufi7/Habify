import 'package:flutter/material.dart';

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
  String _selectedNotification = '07.30 AM';
  String _selectedRepetition = 'Everyday';
  String _selectedCategory = 'Health & Fitness'; // First item selected by default
  
  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _chipController;
  late Animation<double> _buttonScale;
  
  // Options lists
  final List<String> _priorityOptions = ['High', 'Medium', 'Low'];
  final List<String> _notificationOptions = ['06.00 AM', '06.30 AM', '07.00 AM', '07.30 AM', '08.00 AM', '08.30 AM', '09.00 AM', 'Custom'];
  final List<String> _repetitionOptions = ['Everyday', 'Weekdays', 'Weekends', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', 'Custom'];
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
      body: _buildBody(),
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
                    size: 24,
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

  Widget _buildBody() {
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
          const SizedBox(height: 24), // Reduced section gap
          
          // Create button
          _buildCreateButton(),
          const SizedBox(height: 14), // Reduced bottom spacing to fix overflow
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
            fontSize: 18, // typography.hierarchy.sectionLabel.fontSize
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
          child: TextFormField(
            controller: _nameController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF000000),
            ),
            decoration: InputDecoration(
              hintText: 'Enter habit name', // formStructure.sections[0].placeholder
              hintStyle: const TextStyle(
                fontSize: 16, // typography.hierarchy.placeholderText.fontSize
                fontWeight: FontWeight.w400, // typography.hierarchy.placeholderText.fontWeight
                color: Color(0xFF999999), // typography.hierarchy.placeholderText.color
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, // components.textInput.padding
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
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
          child: _buildDropdownField(
            label: 'Notification',
            value: _selectedNotification,
            options: _notificationOptions,
            backgroundColor: const Color(0xFFA8D0E6), // colorPalette.accent.lightBlue
            onChanged: (value) => setState(() => _selectedNotification = value!),
          ),
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
            fontSize: 18, // typography.hierarchy.sectionLabel.fontSize
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
            fontSize: 18, // typography.hierarchy.sectionLabel.fontSize
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DurationPickerDialog(
        initialHours: _selectedHours,
        initialMinutes: _selectedMinutes,
        onDurationChanged: (hours, minutes) {
          setState(() {
            _selectedHours = hours;
            _selectedMinutes = minutes;
          });
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
            fontSize: 18, // typography.hierarchy.sectionLabel.fontSize
            fontWeight: FontWeight.w600, // Matched to Category title font weight
            color: Color(0xFF000000), // typography.hierarchy.sectionLabel.color
          ),
        ),
        const SizedBox(height: 6), // Reduced label to field spacing
        Container(
          constraints: const BoxConstraints(
            minHeight: 120, // components.textArea.minHeight
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // components.textArea.backgroundColor
            borderRadius: BorderRadius.circular(12), // Decreased border radius
            border: Border.all(
              color: const Color(0xFF000000), // components.textArea.border
              width: 2,
            ),
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF000000),
            ),
            decoration: InputDecoration(
              hintText: 'Enter your description', // formStructure.sections[4].placeholder
              hintStyle: const TextStyle(
                fontSize: 16, // typography.hierarchy.placeholderText.fontSize
                fontWeight: FontWeight.w400, // typography.hierarchy.placeholderText.fontWeight
                color: Color(0xFF999999), // components.textArea.placeholder.color
              ),
              contentPadding: const EdgeInsets.all(20), // components.textArea.padding
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
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
            child: ElevatedButton(
              onPressed: _createHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C), // components.primaryButton.backgroundColor (accent.black)
                foregroundColor: const Color(0xFFFFFFFF), // components.primaryButton.textColor
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Decreased border radius
                ),
                padding: const EdgeInsets.all(18), // components.primaryButton.padding
              ),
              child: const Text(
                'Create',
                style: TextStyle(
                  fontSize: 18, // components.primaryButton.fontSize
                  fontWeight: FontWeight.w600, // components.primaryButton.fontWeight
                  color: Color(0xFFFFFFFF), // components.primaryButton.textColor
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _createHabit() async {
    // Button press animation
    await _buttonController.forward();
    await _buttonController.reverse();
    
    // Validate form
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a habit name');
      return;
    }
    
    // Show success and navigate back
    _showSuccessDialog();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Habit created successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Custom Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for your custom category:'),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                hintText: 'Category name',
                border: OutlineInputBorder(),
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
              final categoryName = categoryController.text.trim();
              if (categoryName.isNotEmpty) {
                setState(() {
                  _selectedCategory = categoryName;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
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
              color: const Color(0xFF000000).withOpacity(0.1),
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
                      color: const Color(0xFFFFFFFF).withOpacity(0.7),
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
                          color: const Color(0xFF2C2C2C).withOpacity(0.6),
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
                                color: const Color(0xFF000000).withOpacity(0.04),
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
                                color: const Color(0xFF000000).withOpacity(0.04),
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