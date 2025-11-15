// services/category_service.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/category_master.dart';

class CategoryService {
  CategoryService._internal();
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;

  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://localhost:8000'), // เปลี่ยนเป็นของคุณ
  );

  // cache
  List<CategoryMaster> _categories = [];

  // ====== ICON / COLOR MAP (config ส่วน UI) ======
  static const Map<String, Map<int, IconData>> _iconMap = {
    "expense": {
      1: Icons.category,       // Others
      2: Icons.restaurant,     // Food
      3: Icons.shopping_bag,   // Shopping
      4: Icons.receipt_long,   // Bills
    },
    "income": {
      1: Icons.payments,       // Salary
      2: Icons.wallet,         // Wages / Freelance (ตัวอย่าง)
    },
  };

  static const Map<String, Map<int, Color>> _colorMap = {
    "expense": {
      1: Color(0xFF7F8C8D),
      2: Color(0xFFE67E22),
      3: Color(0xFF2980B9),
      4: Color(0xFF27AE60),
    },
    "income": {
      1: Color(0xFF2ECC71),
      2: Color(0xFF3498DB),
    },
  };

  static const IconData defaultIcon = Icons.label_important_outline;
  static const Color defaultColor = Colors.grey;

  // ====== โหลด categories จาก API ======
  Future<List<CategoryMaster>> fetchCategories({String? token}) async {
    if (_categories.isNotEmpty) return _categories; // ใช้ cache ก่อน

    final res = await _dio.get(
      '/categories/master',
      options: Options(
        headers: token != null
            ? {'Authorization': 'Bearer $token'}
            : null,
      ),
    );

    final data = res.data as List;
    _categories = data
        .map((e) => CategoryMaster.fromJson(e as Map<String, dynamic>))
        .toList();

    return _categories;
  }

  // ====== helper: icon / color จาก categoryId + entryType ======

  IconData iconFor(int? categoryId, String? entryType) {
    if (categoryId == null || entryType == null) return defaultIcon;
    final mapByType = _iconMap[entryType];
    if (mapByType == null) return defaultIcon;
    return mapByType[categoryId] ?? defaultIcon;
  }

  Color colorFor(int? categoryId, String? entryType) {
    if (categoryId == null || entryType == null) return defaultColor;
    final mapByType = _colorMap[entryType];
    if (mapByType == null) return defaultColor;
    return mapByType[categoryId] ?? defaultColor;
  }
}
