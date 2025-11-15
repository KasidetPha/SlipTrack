import 'package:flutter/material.dart';

class CategoryIconOption {
  final String key;
  final IconData icon;

  const CategoryIconOption(this.key, this.icon);
}

const List<CategoryIconOption> kCategoryIconOptions = [
  // --- expense ---
  CategoryIconOption('category', Icons.category_rounded),
  CategoryIconOption('restaurant', Icons.restaurant_rounded),
  CategoryIconOption('shopping_bag', Icons.shopping_bag_rounded),
  CategoryIconOption('receipt_long', Icons.receipt_long_rounded),
  CategoryIconOption('directions_bus', Icons.directions_bus_rounded),

  // --- income ---
  CategoryIconOption('payments', Icons.payments_rounded),
  CategoryIconOption('work', Icons.work_rounded),
  CategoryIconOption('card_giftcard', Icons.card_giftcard_rounded),
  CategoryIconOption('sell', Icons.sell_rounded),
];

IconData getIconFromKey(String key) {
  final match = kCategoryIconOptions.where((o) => o.key == key);
  if (match.isNotEmpty) return match.first.icon;
  return Icons.category_rounded; // default ถ้าหา key ไม่เจอ
}

Color colorFromHex(String hex) {
  var cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  return Color(int.parse(cleaned, radix: 16));
}