import 'package:frontend/widgets/scan_page_widgets/scan_body.dart';

class ReceiptItem {
  final int item_id;
  final String item_name;
  final double total_price;
  final DateTime receiptDate;
  final int quantity;
  final int category_id;
  final String entryType;
  final String? iconName;
  final String? colorHex;
  final String source;

  ReceiptItem({
    required this.item_id, 
    required this.item_name, 
    required this.total_price, 
    required this.receiptDate, 
    required this.quantity, 
    required this.category_id,
    required this.entryType,
    this.iconName,
    this.colorHex,

    required this.source,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic>j) {
    double _d(v) => v is num ? v.toDouble() : double.tryParse('${v}'.replaceAll(",", '')) ?? 0.0;
    int _i(v) => v is num ? v.toInt() : int.tryParse('${v}'.replaceAll(',', '')) ?? 0;
    DateTime _dt(v) {
      if (v == null) return DateTime(1970, 1, 1);
        try {
          return DateTime.parse(v.toString()).toLocal();
        } catch (_) {
          return DateTime(1970, 1, 1);
      }
    }

    return ReceiptItem(
      item_id: _i(j['item_id'] ?? j['id']),
      item_name: j['item_name']?.toString() ?? '', 
      total_price: _d(j['total_price']),
      receiptDate: _dt(j['tx_date']),
      quantity: _i(j['quantity'] ?? 1), 
      category_id: _i(j['category_id']),
      entryType: j['entry_type']?.toString() ?? '',
      iconName: j['icon_name'] != null ? j['icon_name'].toString() : null,
      colorHex: j['color_hex'] != null ? j['color_hex'].toString() : null,
      source: j['source']?.toString()
        ?? j['store_name']?.toString()
        ?? j['income_source']?.toString()
        ?? 'Unknown',
    );
  }

  ReceiptItem copyWith({
    int? item_id,
    String? item_name,
    double? total_price,
    DateTime? receiptDate,
    int? quantity,
    int? category_id,
    String?entryType,
    String?iconName,
    String?colorHex,
    String?source,
  }) {
    return ReceiptItem(
      item_id: item_id ?? this.item_id, 
      item_name: item_name ?? this.item_name, 
      total_price: total_price ?? this.total_price, 
      receiptDate: receiptDate ?? this.receiptDate, 
      quantity: quantity ?? this.quantity, 
      category_id: category_id ?? this.category_id, 
      entryType: entryType ?? this.entryType, 
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      source: source ?? this.source,
    );
  }

  factory ReceiptItem.fromScanResult(ReceiptScanResult r) {
    int finalCatId = (r.categoryId == null || r.categoryId == 0) ? 1 : r.categoryId!;
    return ReceiptItem(
      item_id: 0,
      item_name: r.title,
      total_price: r.amount.abs().toDouble(),
      receiptDate: r.date,
      quantity: r.qty,
      category_id: finalCatId,
      entryType: r.amount < 0 ? 'expense' : 'income',
      source: 'scan',
    );
  }
}