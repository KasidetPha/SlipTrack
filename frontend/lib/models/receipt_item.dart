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
      if (v == null) {
        if (v == null) return DateTime(1970, 1, 1);
        try {
          return DateTime.parse(v.toString()).toLocal();
        } catch (_) {
          return DateTime(1970, 1, 1);
        }
      }

      return DateTime.parse(v.toString()).toLocal();
    }
    return ReceiptItem(
      item_id: _i(j['item_id'] ?? j['id']),
      item_name: j['item_name']?.toString() ?? '', 
      total_price: _d(j['total_price']),
      receiptDate: _dt(j['tx_date']),
      quantity: _i(j['quantity']), 
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
}