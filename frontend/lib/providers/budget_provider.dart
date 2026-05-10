import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/budget_model.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/services/receipt_service.dart';

final budgetProvider = FutureProvider.family<BudgetResponse, ({int month, int year})>((ref, filter) async {
  return ReceiptService().fetchBudgets(
    month: filter.month,
    year: filter.year,
  );
});

final budgetControllerProvider = Provider((ref) {
  return BudgetController(ref);
});

class BudgetController {
  final Ref ref;

  BudgetController(this.ref);

  Future<void> saveBudget(BudgetResponse budget) async {
    await ReceiptService().updateBudget(budget: budget);

    ref.invalidate(budgetProvider);
    ref.read(transactionControllerProvider).refreshData();
  }
}