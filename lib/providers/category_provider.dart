import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database/habit_service.dart';

class CategoryProvider extends ChangeNotifier {
  final HabitService _habitService = HabitService();
  
  // State variables
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Computed properties
  List<Category> get defaultCategories => _categories.where((cat) => cat.isDefault).toList();
  List<Category> get customCategories => _categories.where((cat) => !cat.isDefault).toList();
  int get totalCategoriesCount => _categories.length;
  int get customCategoriesCount => customCategories.length;
  
  // Popular category colors
  static const List<String> popularColors = [
    '#FF6B35', // Orange (Primary)
    '#4CAF50', // Green (Secondary)
    '#2196F3', // Blue
    '#9C27B0', // Purple
    '#F44336', // Red
    '#FF9800', // Amber
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#E91E63', // Pink
    '#00BCD4', // Cyan
    '#8BC34A', // Light Green
    '#FF5722', // Deep Orange
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#009688', // Teal
  ];
  
  // Popular category icons
  static const List<String> popularIcons = [
    'fitness_center', 'book', 'water_drop', 'restaurant', 'bedtime',
    'work', 'school', 'music_note', 'palette', 'spa',
    'sports', 'language', 'volunteer_activism', 'savings', 'eco',
    'local_pharmacy', 'psychology', 'family_restroom', 'pets', 'garden',
  ];
  
  // Initialize provider
  Future<void> initialize() async {
    await loadCategories();
  }
  
  // Loading states management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  // Category management
  Future<void> loadCategories() async {
    try {
      _setLoading(true);
      _clearError();
      _categories = await _habitService.getAllCategories();
      
      // Set default selected category if none selected
      if (_selectedCategory == null && _categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<int?> createCategory({
    required String name,
    required String colorHex,
    required String iconName,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Validate input
      if (name.trim().isEmpty) {
        throw ArgumentError('Category name cannot be empty');
      }
      
      if (!colorHex.startsWith('#') || colorHex.length != 7) {
        throw ArgumentError('Invalid color format. Use #RRGGBB format');
      }
      
      if (iconName.trim().isEmpty) {
        throw ArgumentError('Icon name cannot be empty');
      }
      
      // Check for duplicate names
      if (_categories.any((cat) => cat.name.toLowerCase() == name.toLowerCase())) {
        throw ArgumentError('Category with this name already exists');
      }
      
      final categoryId = await _habitService.createCustomCategory(name.trim(), colorHex, iconName);
      
      // Reload categories to update the UI
      await loadCategories();
      
      return categoryId;
    } catch (e) {
      _setError('Failed to create category: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> deleteCategory(int categoryId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Check if it's a default category
      final category = getCategoryById(categoryId);
      if (category?.isDefault == true) {
        throw ArgumentError('Cannot delete default categories');
      }
      
      await _habitService.deleteCustomCategory(categoryId);
      
      // Remove from local state
      _categories.removeWhere((cat) => cat.id == categoryId);
      
      // Update selected category if it was deleted
      if (_selectedCategory?.id == categoryId) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete category: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Category selection
  void selectCategory(Category? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }
  
  void selectCategoryById(int categoryId) {
    final category = getCategoryById(categoryId);
    selectCategory(category);
  }
  
  void clearSelection() {
    if (_selectedCategory != null) {
      _selectedCategory = null;
      notifyListeners();
    }
  }
  
  // Category utilities
  Category? getCategoryById(int categoryId) {
    try {
      return _categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }
  
  Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  List<Category> searchCategories(String query) {
    if (query.trim().isEmpty) {
      return _categories;
    }
    
    final searchTerm = query.toLowerCase().trim();
    return _categories.where((category) {
      return category.name.toLowerCase().contains(searchTerm);
    }).toList();
  }
  
  List<Category> getCategoriesWithHabits() {
    // This would require integration with HabitProvider to know which categories have habits
    // For now, return all categories
    return _categories;
  }
  
  List<Category> getEmptyCategories() {
    // This would require integration with HabitProvider to know which categories are empty
    // For now, return empty list
    return [];
  }
  
  // Category validation
  bool isCategoryNameAvailable(String name) {
    return !_categories.any(
      (cat) => cat.name.toLowerCase() == name.toLowerCase(),
    );
  }
  
  bool isColorInUse(String colorHex) {
    return _categories.any((cat) => cat.colorHex == colorHex);
  }
  
  bool isIconInUse(String iconName) {
    return _categories.any((cat) => cat.iconName == iconName);
  }
  
  // Category statistics
  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    
    for (final category in _categories) {
      // This would require integration with HabitProvider to get actual habit counts
      // For now, return placeholder data
      stats[category.name] = 0;
    }
    
    return stats;
  }
  
  // Color and icon helpers
  Color getColorFromHex(String hexColor) {
    final color = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$color', radix: 16));
  }
  
  String getRandomColor() {
    final availableColors = popularColors.where((color) => !isColorInUse(color)).toList();
    if (availableColors.isEmpty) {
      return popularColors.first;
    }
    
    availableColors.shuffle();
    return availableColors.first;
  }
  
  String getRandomIcon() {
    final availableIcons = popularIcons.where((icon) => !isIconInUse(icon)).toList();
    if (availableIcons.isEmpty) {
      return popularIcons.first;
    }
    
    availableIcons.shuffle();
    return availableIcons.first;
  }
  
  // Category suggestions
  List<Map<String, String>> getCategorySuggestions() {
    final suggestions = [
      {'name': 'Health & Fitness', 'color': '#4CAF50', 'icon': 'fitness_center'},
      {'name': 'Learning', 'color': '#2196F3', 'icon': 'school'},
      {'name': 'Reading', 'color': '#795548', 'icon': 'book'},
      {'name': 'Hydration', 'color': '#00BCD4', 'icon': 'water_drop'},
      {'name': 'Nutrition', 'color': '#8BC34A', 'icon': 'restaurant'},
      {'name': 'Sleep', 'color': '#673AB7', 'icon': 'bedtime'},
      {'name': 'Work', 'color': '#607D8B', 'icon': 'work'},
      {'name': 'Music', 'color': '#E91E63', 'icon': 'music_note'},
      {'name': 'Art & Creativity', 'color': '#FF9800', 'icon': 'palette'},
      {'name': 'Mindfulness', 'color': '#9C27B0', 'icon': 'spa'},
      {'name': 'Sports', 'color': '#FF5722', 'icon': 'sports'},
      {'name': 'Languages', 'color': '#3F51B5', 'icon': 'language'},
      {'name': 'Volunteering', 'color': '#F44336', 'icon': 'volunteer_activism'},
      {'name': 'Savings', 'color': '#009688', 'icon': 'savings'},
      {'name': 'Environment', 'color': '#8BC34A', 'icon': 'eco'},
    ];
    
    // Filter out suggestions that already exist
    return suggestions.where((suggestion) {
      return !_categories.any(
        (cat) => cat.name.toLowerCase() == suggestion['name']!.toLowerCase(),
      );
    }).toList();
  }
  
  // Import/Export
  Map<String, dynamic> exportCategories() {
    return {
      'categories': _categories.map((cat) => cat.toMap()).toList(),
      'export_date': DateTime.now().toIso8601String(),
      'total_count': _categories.length,
      'custom_count': customCategories.length,
    };
  }
  
  // Backup and restore
  List<Map<String, dynamic>> getCustomCategoriesForBackup() {
    return customCategories.map((cat) => cat.toMap()).toList();
  }
  
  // Refresh data
  Future<void> refresh() async {
    await loadCategories();
  }
  
  // Reset to defaults
  Future<void> resetSelection() async {
    _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    notifyListeners();
  }
  
  // Validation helpers
  String? validateCategoryName(String name) {
    if (name.trim().isEmpty) {
      return 'Category name cannot be empty';
    }
    
    if (name.trim().length < 2) {
      return 'Category name must be at least 2 characters';
    }
    
    if (name.trim().length > 50) {
      return 'Category name must be less than 50 characters';
    }
    
    if (!isCategoryNameAvailable(name)) {
      return 'Category name already exists';
    }
    
    return null;
  }
  
  String? validateColorHex(String colorHex) {
    if (!colorHex.startsWith('#')) {
      return 'Color must start with #';
    }
    
    if (colorHex.length != 7) {
      return 'Color must be in #RRGGBB format';
    }
    
    final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!hexPattern.hasMatch(colorHex)) {
      return 'Invalid color format';
    }
    
    return null;
  }
  
  String? validateIconName(String iconName) {
    if (iconName.trim().isEmpty) {
      return 'Icon name cannot be empty';
    }
    
    if (!popularIcons.contains(iconName)) {
      return 'Invalid icon name';
    }
    
    return null;
  }
  
}