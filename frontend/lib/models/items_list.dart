// import 'package:flutter/material.dart';

enum CategoryIcon {
  food(title:"food & Dining", image: "assets/images/icon_food.png"),
  transpot(title: "Transportation", image: "assets/images/icon_transpot.png"),
  health(title: "Health & Personal Care", image: "assets/images/icon_health.png");


  const CategoryIcon({required this.title, required this.image});
  final String title;
  final String image;
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
  ItemsList(title: "อาหารกลางวัน", price: 120.50, datetime: DateTime(2025, 8, 19, 12, 30), category: CategoryIcon.food, note: ""),
  ItemsList(title: "ฟิตเนส", price: 60, datetime: DateTime(2025, 8, 14, 18, 30), category: CategoryIcon.health, note: ""),
  ItemsList(title: "ค่ารถเมล์", price: 8, datetime: DateTime(2025, 8, 12, 08, 30), category: CategoryIcon.transpot, note: ""),
];