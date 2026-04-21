// services/category_service.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/category_master.dart';

class CategoryService {
  CategoryService._internal();
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.12:8000',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5)
    ), // เปลี่ยนเป็นของคุณ
  );

  // cache
  Map<String, List<CategoryMaster>> _cacheByUser = {};

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
  Future<List<CategoryMaster>> fetchCategories({required String token, bool forceRefresh = false}) async {
    if (!forceRefresh && _cacheByUser[token] != null) return _cacheByUser[token]!;

    final res = await _dio.get(
      '/categories/master',
      options: Options(
        headers: {'Authorization': 'Bearer $token'}
      ),
    );

    final data = res.data as List;

    final categories = data
    .map((e) => CategoryMaster.fromJson(e as Map<String, dynamic>))
    .toList();

    _cacheByUser[token] = categories;
    return categories;
  }

  Future<bool> addNewCategory({
    required String categoryName,
    required String entryType,
    required String iconName,
    required String colorHex,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/categories/',
        data: {
          'category_name': categoryName,
          'entry_type': entryType,
          'icon_name': iconName,
          'color_hex': colorHex,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'}
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _cacheByUser.remove(token);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error adding category: $e");
      return false;
    }
  }

  Future<bool> updateCategory({
    required int categoryId,
    required String categoryName,
    required String entryType,
    required String iconName,
    required String colorHex,
    String? token,
  }) async {
    try {
      final response = await _dio.put(
        '/categories/$categoryId',
        data: {
          'category_name': categoryName,
          'entry_type': entryType,
          'icon_name': iconName,
          'color_hex': colorHex
        },
        options: Options(
          headers: token != null ? {"Authorization": "Bearer $token"} : null
        )
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _cacheByUser.clear();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error updating category: $e");
      return false;
    }
  }

  Future<bool> deleteCategory({
    required int categoryId,
    required String token,
  }) async {
    try {
      final response = await _dio.delete(
        '/categories/$categoryId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'}
        )
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        clearCache(token: token);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error delteing category: $e");
      return false;
    }
  }

  void clearCache({String? token}) {
    if (token != null) {
      _cacheByUser.remove(token);
    } else {
      _cacheByUser.clear();
    }
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
