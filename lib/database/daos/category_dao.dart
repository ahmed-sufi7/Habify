import '../database_helper.dart';
import '../../models/category.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const String _tableName = 'categories';

  // Create
  Future<int> insertCategory(Category category) async {
    final categoryMap = category.toMap();
    categoryMap.remove('id'); // Remove id for auto-increment
    return await _dbHelper.insert(_tableName, categoryMap);
  }

  Future<List<int>> insertCategories(List<Category> categories) async {
    final List<int> ids = [];
    await _dbHelper.transaction((txn) async {
      for (final category in categories) {
        final categoryMap = category.toMap();
        categoryMap.remove('id');
        final id = await txn.insert(_tableName, categoryMap);
        ids.add(id);
      }
    });
    return ids;
  }

  // Read
  Future<List<Category>> getAllCategories() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      orderBy: 'is_default DESC, name ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<Category?> getCategoryByName(String name) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Category>> getDefaultCategories() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_default = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> getCustomCategories() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'is_default = ?',
      whereArgs: [0],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  // Update
  Future<int> updateCategory(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Category ID cannot be null for update');
    }

    final categoryMap = category.toMap();
    categoryMap['updated_at'] = DateTime.now().toIso8601String();
    
    return await _dbHelper.update(
      _tableName,
      categoryMap,
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> updateCategoryName(int id, String newName) async {
    return await _dbHelper.update(
      _tableName,
      {
        'name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCategoryColor(int id, String colorHex) async {
    return await _dbHelper.update(
      _tableName,
      {
        'color_hex': colorHex,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCategoryIcon(int id, String iconName) async {
    return await _dbHelper.update(
      _tableName,
      {
        'icon_name': iconName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete
  Future<int> deleteCategory(int id) async {
    // Check if category has habits before deleting
    final habitCount = await getHabitCountForCategory(id);
    if (habitCount > 0) {
      throw StateError('Cannot delete category with existing habits. Move or delete habits first.');
    }

    return await _dbHelper.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomCategories() async {
    return await _dbHelper.delete(
      _tableName,
      where: 'is_default = ?',
      whereArgs: [0],
    );
  }

  // Utility methods
  Future<bool> categoryExists(String name) async {
    final category = await getCategoryByName(name);
    return category != null;
  }

  Future<bool> categoryExistsById(int id) async {
    final category = await getCategoryById(id);
    return category != null;
  }

  Future<int> getCategoryCount() async {
    final result = await _dbHelper.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return result.first['count'] as int;
  }

  Future<int> getDefaultCategoryCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE is_default = ?',
      [1],
    );
    return result.first['count'] as int;
  }

  Future<int> getCustomCategoryCount() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE is_default = ?',
      [0],
    );
    return result.first['count'] as int;
  }

  Future<int> getHabitCountForCategory(int categoryId) async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM habits WHERE category_id = ?',
      [categoryId],
    );
    return result.first['count'] as int;
  }

  // Validation methods
  Future<bool> canDeleteCategory(int id) async {
    final habitCount = await getHabitCountForCategory(id);
    return habitCount == 0;
  }

  Future<bool> isDefaultCategory(int id) async {
    final category = await getCategoryById(id);
    return category?.isDefault ?? false;
  }

  // Search and filter
  Future<List<Category>> searchCategories(String query) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'is_default DESC, name ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  // Bulk operations
  Future<void> resetToDefaultCategories() async {
    await _dbHelper.transaction((txn) async {
      // Delete all categories
      await txn.delete(_tableName);
      
      // Insert default categories
      final defaultCategories = Category.getDefaultCategories();
      for (final category in defaultCategories) {
        final categoryMap = category.toMap();
        categoryMap.remove('id');
        await txn.insert(_tableName, categoryMap);
      }
    });
  }

  // Statistics
  Future<Map<String, dynamic>> getCategoryStats() async {
    final result = await _dbHelper.rawQuery('''
      SELECT 
        c.id,
        c.name,
        c.color_hex,
        c.is_default,
        COUNT(h.id) as habit_count
      FROM $_tableName c
      LEFT JOIN habits h ON c.id = h.category_id AND h.is_active = 1
      GROUP BY c.id, c.name, c.color_hex, c.is_default
      ORDER BY c.is_default DESC, c.name ASC
    ''');

    return {
      'total_categories': result.length,
      'default_categories': result.where((r) => r['is_default'] == 1).length,
      'custom_categories': result.where((r) => r['is_default'] == 0).length,
      'categories_with_habits': result.where((r) => (r['habit_count'] as int) > 0).length,
      'categories': result,
    };
  }
}