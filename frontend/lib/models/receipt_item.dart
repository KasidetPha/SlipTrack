class ReceiptItem {
  final String item_name;
  final double total_price;
  final DateTime receiptDate;
  final int quantity;

  ReceiptItem({required this.item_name, required this.total_price, required this.receiptDate, required this.quantity,});

  factory ReceiptItem.fromJson(Map<String, dynamic>j) {
    double _d(v) => v is num ? v.toDouble() : double.tryParse('${v}'.replaceAll(",", '')) ?? 0.0;
    int _i(v) => v is num ? v.toInt() : int.tryParse('${v}'.replaceAll(',', '')) ?? 0;
    DateTime _dt(v) => DateTime.tryParse('${v}')?.toLocal() ?? DateTime.now();
    return ReceiptItem(
      item_name: j['item_name']?.toString() ?? '', 
      total_price: _d(j['total_price']),
      receiptDate: _dt(j['receipt_date']),
      quantity: _i(j['quantity']), 
    );
  }
}