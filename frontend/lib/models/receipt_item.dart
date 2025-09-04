class ReceiptItem {
  final int item_id;
  final int receipt_id;
  final String item_name;
  final int quantity;
  final double unit_price;
  final double total_price;

  ReceiptItem({required this.item_id, required this.receipt_id, required this.item_name, required this.quantity, required this.unit_price, required this.total_price});

  factory ReceiptItem.fromJson(Map<String, dynamic>json) {
    return ReceiptItem(
      item_id: json['item_id'], 
      receipt_id: json['receipt_id'], 
      item_name: json['item_name'], 
      quantity: json['quantity'], 
      unit_price: double.parse(json['unit_price'].toString()), 
      total_price: double.parse(json['total_price'].toString())
    );
  }
}