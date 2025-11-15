// lib/models/category_master.dart
class CategoryMaster {
  final int categoryId;
  final String categoryName;
  final String entryType; // 'income' | 'expense'
  final String? iconName;
  final String? colorHex;

  CategoryMaster({
    required this.categoryId,
    required this.categoryName,
    required this.entryType,
    this.iconName,
    this.colorHex,
  });

  factory CategoryMaster.fromJson(Map<String, dynamic> json) {
    return CategoryMaster(
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      entryType: json['entry_type'] as String,
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
    );
  }
}
