class CategoryTotal {
  final int? categoryId;
  final String categoryName;
  final double totalSpent;

  const CategoryTotal({required this.categoryName, required this.totalSpent, this.categoryId});

  factory CategoryTotal.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) => 
      v is num ? v.toDouble() : double.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0.0;

    return CategoryTotal(
      categoryId: json['category_id'] as int?,
      categoryName: (json['category_name'] ?? '').toString(),
      totalSpent: _toDouble(json['total_spent'])
    );
  }
}