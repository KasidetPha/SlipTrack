import 'package:flutter/widgets.dart';

enum CategoryIcon {
  food(
      title: "Food & Dining",
      image: "assets/images/icons/icon_food.png",
      color: Color(0xFFE0F7FA)),
  transpot(
      title: "Transportation",
      image: "assets/images/icons/icon_transport.png",
      color: Color(0xFFE8F0FE)),
  health(
      title: "Health & Personal Care",
      image: "assets/images/icons/icon_health.png",
      color: Color(0xFFF0FFF4));

  const CategoryIcon(
      {required this.title, required this.image, required this.color});
  final String title;
  final String image;
  final Color color;
}

class ItemsList {
  ItemsList({
    required this.title,
    required this.price,
    required this.datetime,
    required this.category,
    required this.note,
  });

  String title;
  double price;
  DateTime datetime;
  CategoryIcon category;
  String? note;
}

List<ItemsList> data = [
  ItemsList(
      title: "อาหารกลางวัน",
      price: 120.50,
      datetime: DateTime(2025, 8, 19, 12, 30),
      category: CategoryIcon.food,
      note: ""),
  ItemsList(
      title: "ฟิตเนส",
      price: 60,
      datetime: DateTime(2025, 8, 14, 18, 30),
      category: CategoryIcon.health,
      note: ""),
  ItemsList(
      title: "ค่ารถเมล์",
      price: 1000,
      datetime: DateTime(2025, 8, 12, 08, 30),
      category: CategoryIcon.transpot,
      note: ""),
];
