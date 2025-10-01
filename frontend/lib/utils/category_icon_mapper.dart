import 'package:flutter/material.dart';

const Map<int, IconData> kIconByCategoryId = {
  4: Icons.receipt_long,
  2: Icons.restaurant,
  3: Icons.shopping_bag,
  5: Icons.directions_bus,
  1: Icons.category
};

const Map<int, Color> kColorByCategoryId = {
  4: Color(0xFF27AE60), // Bills  (เขียว)
  2: Color(0xFFE67E22), // Food   (ส้ม)
  3: Color(0xFF2980B9), // Shop   (ฟ้า)
  5: Color(0xFF8E44AD), // Transp (ม่วง)
  1: Color(0xFF7F8C8D), // Others (เทา)
};

const IconData kDefaultCategoryIcon = Icons.label_important_outline;
const Color kDefaultCategoryColor = Colors.grey;

IconData iconForCategoryId(int? id) => 
  id != null && kIconByCategoryId.containsKey(id)
  ? kIconByCategoryId[id]!
  : kDefaultCategoryIcon;

Color colorForCategoryId(int? id) =>
  id != null && kColorByCategoryId.containsKey(id)
  ? kColorByCategoryId[id]!
  : kDefaultCategoryColor;