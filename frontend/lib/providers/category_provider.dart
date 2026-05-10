import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/category_master.dart';
import 'package:frontend/services/category_service.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final categoriesProvider = FutureProvider<List<CategoryMaster>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) {
    throw Exception('Token not found');
  }

  return CategoryService().fetchCategories(
    token: token,
    forceRefresh: true,
  );
});

final incomeCategoriesProvider = Provider<List<CategoryMaster>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories
      .where((c) => c.entryType.toLowerCase() == 'income')
      .toList();
});

final expenseCategoriesProvider = Provider<List<CategoryMaster>>((ref) {
  final categories = ref.watch(categoriesProvider).value ?? [];
  return categories
      .where((c) => c.entryType.toLowerCase() == 'expense')
      .toList();
});

final categoryControllerProvider = Provider((ref) {
  return CategoryController(ref);
});

class CategoryController {
  final Ref ref;

  CategoryController(this.ref);

  Future<bool> addCategory({
    required String categoryName,
    required String entryType,
    required String iconName,
    required String colorHex,
  }) async {
    final token = await _getToken();

    final success = await CategoryService().addNewCategory(
      categoryName: categoryName,
      entryType: entryType,
      iconName: iconName,
      colorHex: colorHex,
      token: token,
    );

    if (success) {
      CategoryService().clearCache(token: token);
      refreshAll();
    }

    return success;
  }

  Future<bool> updateCategory({
    required int categoryId,
    required String categoryName,
    required String entryType,
    required String iconName,
    required String colorHex,
  }) async {
    final token = await _getToken();

    final success = await CategoryService().updateCategory(
      categoryId: categoryId,
      categoryName: categoryName,
      entryType: entryType,
      iconName: iconName,
      colorHex: colorHex,
      token: token,
    );

    if (success) {
      CategoryService().clearCache(token: token);
      refreshAll();
    }

    return success;
  }

  Future<bool> deleteCategory({
    required int categoryId,
  }) async {
    final token = await _getToken();

    final success = await CategoryService().deleteCategory(
      categoryId: categoryId,
      token: token,
    );

    if (success) {
      CategoryService().clearCache(token: token);
      refreshAll();
    }

    return success;
  }

  void refreshAll() {
    ref.invalidate(categoriesProvider);
    ref.read(transactionControllerProvider).refreshData();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token not found');
    }

    return token;
  }
}