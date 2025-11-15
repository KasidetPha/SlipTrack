class CategorySummary {
  final int categoryId;
  final String categoryName;
  final double total;
  final int itemCount;
  final double percent;
  final String? iconName;
  final String? colorHex;

  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.itemCount,
    required this.percent,
    this.iconName,
    this.colorHex
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '', 
      total: double.tryParse(json['total'].toString()) ?? 0.0, 
      itemCount: json['item_count'] ?? 0, 
      percent: double.tryParse(json['percent']?.toString() ?? '0') ?? 0.0,
      iconName: json['icon_name']?.toString(),
      colorHex: json['color_hex']?.toString(),
    );
  }
}
