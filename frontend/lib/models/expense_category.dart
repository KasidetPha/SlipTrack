class ExpenseCategory {
  final int categoryId;
  final String categoryName;
  final String iconName;
  final String colorHex;
  final int isDefault;
  final int? userId;

  ExpenseCategory({
    required this.categoryId,
    required this.categoryName,
    required this.iconName,
    required this.colorHex,
    required this.isDefault,
    this.userId
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      categoryId: json['category_id'] as int, 
      categoryName: json['category_name'] as String, 
      iconName: ['icon_name'] as String, 
      colorHex: ['color_hex'] as String, 
      isDefault: ['is_default'] as int,
      userId: json['user_id'] as int?,
    );
  }
}