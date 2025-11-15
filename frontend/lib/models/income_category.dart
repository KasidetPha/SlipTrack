class IncomeCategory {
  final int incomeCategoryId;
  final String incomeCategoryName;
  final String iconName;
  final String colorHex;
  final int isDefault;
  final int? userId;

  IncomeCategory({
    required this.incomeCategoryId,
    required this.incomeCategoryName,
    required this.iconName,
    required this.colorHex,
    required this.isDefault,
    this.userId,
  });

  factory IncomeCategory.fromJson(Map<String, dynamic> json) {
    return IncomeCategory(
      incomeCategoryId: json['income_category_id'] as int,
      incomeCategoryName: json['income_category_name'] as String,
      iconName: json['icon_name'] as String,
      colorHex: json['color_hex'] as String,
      isDefault: json['is_default'] as int,
      userId: json['user_id'] as int?,
    );
  }
}
