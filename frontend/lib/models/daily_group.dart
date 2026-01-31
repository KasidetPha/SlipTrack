import 'package:frontend/models/receipt_item.dart';

class DailyGroup {
  final DateTime date;
  final List<ReceiptItem> items;
  final double totalIncome;
  final double totalExpense;

  DailyGroup({
    required this.date,
    required this.items,
    required this.totalIncome,
    required this.totalExpense
  });
}