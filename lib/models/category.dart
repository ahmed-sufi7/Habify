class Category {
  final int? id;
  final String name;
  final String colorHex; // Color value as hex string
  final String iconName; // Icon name for the category
  final bool isDefault; // Whether this is a default category
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      colorHex: map['color_hex'] ?? '#2C2C2C',
      iconName: map['icon_name'] ?? 'category',
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon_name': iconName,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? iconName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, colorHex: $colorHex, iconName: $iconName, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex &&
        other.iconName == iconName &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        colorHex.hashCode ^
        iconName.hashCode ^
        isDefault.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // Static method to create default categories
  static List<Category> getDefaultCategories() {
    final now = DateTime.now();
    return [
      Category(
        name: 'Health & Fitness',
        colorHex: '#4CAF50',
        iconName: 'fitness_center',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        name: 'Learning',
        colorHex: '#2C2C2C',
        iconName: 'book',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        name: 'Social',
        colorHex: '#E91E63',
        iconName: 'people',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        name: 'Productivity',
        colorHex: '#2196F3',
        iconName: 'work',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        name: 'Mindfulness',
        colorHex: '#FF9800',
        iconName: 'spa',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        name: 'Other',
        colorHex: '#607D8B',
        iconName: 'more_horiz',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}