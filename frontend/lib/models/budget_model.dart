import 'dart:convert';

class BudgetCategoryItem {
  final int categoryId;
  final String categoryName;
  final String? iconName;
  final String? colorHex;

  double limit;

  BudgetCategoryItem({
    required this.categoryId,
    required this.categoryName,
    required this.limit,
    this.iconName,
    this.colorHex
  });

  factory BudgetCategoryItem.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryItem(
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String, 
      iconName: json['icon_name'] as String?,
      colorHex: json['color_hex'] as String?,
      limit: (json['limit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'category_id': categoryId,
      'limit': limit
    };
  }
} 

class BudgetResponse {
  final int month;
  final int year;
  bool warningEnabled;
  int warningPercentage;
  bool overspendingEnabled;
  List<BudgetCategoryItem> items;

  BudgetResponse({
    required this.month,
    required this.year,
    required this.warningEnabled,
    required this.warningPercentage,
    required this.overspendingEnabled,
    required this.items,
  });

  factory BudgetResponse.fromJson(Map<String, dynamic> json) {
    return BudgetResponse(
      month: json['month'] as int, 
      year: json['year'] as int, 
      warningEnabled: json['warning_enabled'] as bool, 
      warningPercentage: json['warning_percentage'] as int, 
      overspendingEnabled: json['overspending_enabled'] as bool, 
      items: (json['items'] as List<dynamic>)
        .map((e) => BudgetCategoryItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'warning_enabled': warningEnabled,
      'warning_percentage': warningPercentage,
      'overspending_enabled': overspendingEnabled,
      'items': items.map((e) => e.toUpdateJson()).toList(),
    };
  }

  static BudgetResponse fromRawJson(String source) =>
    BudgetResponse.fromJson(jsonDecode(source) as Map<String, dynamic>);
}