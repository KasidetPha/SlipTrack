import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/category_summary.dart';
import 'package:frontend/models/category_total.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/receipt_service.dart';
import '../models/receipt_item.dart';
import '../models/stats_summary.dart';
import '../models/monthly_kind.dart';
import '../models/user_profile.dart';


// --- ตัวจัดการ Filter เดือน/ปี ---
final calendarFiltersProvider = StateProvider<Map<String, int>>((ref) {
  final now = DateTime.now();
  return {'month': now.month, 'year': now.year};
});

Future<void> _ensureToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  // final token = await ref.watch(tokenProvider.future);
  if (token.isNotEmpty) {
    ApiClient().setToken(token);
  }
}

// --- ตัวจัดการข้อมูลโปรไฟล์ (จุดที่เกิด Error) ---
// final userProfileProvider = FutureProvider<UserProfile>((ref) async {
//   await _ensureToken();
//   return ProfileService().fetchUserProfile();
// });

// --- ตัวจัดการรายการธุรกรรม ---
final transactionsProvider = FutureProvider.family<
    List<ReceiptItem>,
    ({int? categoryId, int month, int year, String? entryType})>((ref, params) async {
  
  await _ensureToken();

  if (params.categoryId != null) {
    return ReceiptService().fetchReceiptItemsByCategory(
      categoryId: params.categoryId!,
      month: params.month,
      year: params.year,
      entryType: params.entryType ?? 'expense',
    );
  }

  return ReceiptService().fetchReceiptItems(
    month: params.month,
    year: params.year,
  );
});

final transactionControllerProvider = Provider((ref) => TransactionController(ref));

class TransactionController {
  final Ref ref;
  TransactionController(this.ref);

  void refreshData() {
    refreshTransactionData();
  }

  void refreshTransactionData() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(summaryProvider);
    ref.invalidate(categoryTotalsProvider);
    ref.invalidate(categorySummaryProvider);
    ref.invalidate(categoryDetailTotalProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<bool> deleteTransaction(int id, String entryType) async {
    await _ensureToken();
    final success = await ReceiptService().deleteTransaction(id, entryType);
    if (success) {
      await Future.delayed(const Duration(milliseconds: 300));
      refreshTransactionData();
    }

    return success;
  }
}

Future<StatsSummary> _fetchSummary(Ref ref, MonthlyKind type) async {
  await _ensureToken();
  final filters = ref.watch(calendarFiltersProvider);
  return ReceiptService().getMonthlyComparison(
    month: filters['month']!,
    year: filters['year']!,
    type: type,
  );
}

final FutureProviderFamily<StatsSummary, MonthlyKind> summaryProvider = 
    FutureProvider.family<StatsSummary, MonthlyKind>((ref, type) async {
  
  await _ensureToken();
  final filters = ref.watch(calendarFiltersProvider);

  if (type == MonthlyKind.net) {
    final StatsSummary inc = await ref.watch(summaryProvider(MonthlyKind.income).future);
    final StatsSummary exp = await ref.watch(summaryProvider(MonthlyKind.expense).future);
    
    final netThisMonth = (inc.thisMonth ?? 0.0) - (exp.thisMonth ?? 0.0);
    final netLastMonth = (inc.lastMonth ?? 0.0) - (exp.lastMonth ?? 0.0);
    
    double pct = 0.0;
    if (netLastMonth == 0) {
      pct = netThisMonth == 0 ? 0.0 : 100.0;
    } else {
      pct = ((netThisMonth - netLastMonth) / netLastMonth.abs()) * 100.0;
    }
    
    return StatsSummary(
      thisMonth: netThisMonth, 
      lastMonth: netLastMonth, 
      percentChange: pct
    );
  }

  // กรณีปกติ (income/expense) ให้ดึงข้อมูลจาก Service ตามปกติ
  return ReceiptService().getMonthlyComparison(
    month: filters['month']!,
    year: filters['year']!,
    type: type,
  );
});

final categoryTotalsProvider =
    FutureProvider.family<List<CategoryTotal>, ({int month, int year})>((ref, filter) async {
  await _ensureToken();

  return ReceiptService().fetchCategoryTotals(
    month: filter.month,
    year: filter.year,
  );
});

final dashboardProvider =
    FutureProvider.family<Map<String, dynamic>, ({int month, int year})>(
  (ref, filter) async {
    await _ensureToken();

    return ReceiptService().getDashboardSummary(
      month: filter.month,
      year: filter.year,
    );
  },
);

final categorySummaryProvider =
    FutureProvider.family<List<CategorySummary>, ({int month, int year, String entryType})>(
  (ref, filter) async {
    await _ensureToken();

    return ReceiptService().fetchCategorySummary(
      month: filter.month,
      year: filter.year,
      entryType: filter.entryType,
    );
  },
);

final categoryDetailTotalProvider =
    FutureProvider.family<double, ({int categoryId, int month, int year, String entryType})>(
  (ref, filter) async {
    await _ensureToken();

    final items = await ReceiptService().fetchReceiptItemsByCategory(
      categoryId: filter.categoryId,
      month: filter.month,
      year: filter.year,
      entryType: filter.entryType,
    );

    return items.fold<double>(
      0.0,
      (sum, item) => sum + item.total_price,
    );
  },
);