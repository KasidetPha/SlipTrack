class CategorySummary {
  final int categoryId;
  final String categoryName;
  final double total;
  final int itemCount;
  final double percent;

  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.itemCount,
    required this.percent
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '', 
      total: double.tryParse(json['total'].toString()) ?? 0.0, 
      itemCount: json['item_count'] ?? 0, 
      percent: double.tryParse(json['percent']?.toString() ?? '0') ?? 0.0
    );
  }
}
