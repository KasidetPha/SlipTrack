// lib/models/category_detail.dart
class CategoryDetail {
  final String itemName;
  final DateTime? receiptDate; // ยอมให้ว่างได้
  final int quantity;
  final double totalPrice;

  CategoryDetail({
    required this.itemName,
    required this.receiptDate,
    required this.quantity,
    required this.totalPrice,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    // รองรับทั้ง snake_case / camelCase และกัน null ทุกตัว
    final rawName = json['item_name'] ?? json['itemName'];
    final rawDate = json['receipt_date'] ?? json['receiptDate'];
    final rawQty  = json['quantity'];
    final rawAmt  = json['total_price'] ?? json['totalPrice'];

    // item_name: ถ้า null ให้เป็น "" (อย่างน้อยไม่พัง UI)
    final String itemName = (rawName ?? '').toString();

    // receipt_date: แปลงแบบปลอดภัย
    DateTime? receiptDate;
    if (rawDate != null && rawDate.toString().trim().isNotEmpty) {
      try {
        receiptDate = DateTime.parse(rawDate.toString());
      } catch (_) {
        receiptDate = null; // ถ้า parse ไม่ได้ก็ปล่อยให้ null
      }
    }

    // quantity: รองรับทั้ง int/num/string/null
    final int quantity = () {
      if (rawQty == null) return 0;
      if (rawQty is num) return rawQty.toInt();
      return int.tryParse(rawQty.toString()) ?? 0;
    }();

    // total_price: รองรับทั้ง num/string/null
    final double totalPrice = () {
      if (rawAmt == null) return 0.0;
      if (rawAmt is num) return rawAmt.toDouble();
      return double.tryParse(rawAmt.toString()) ?? 0.0;
    }();

    return CategoryDetail(
      itemName: itemName,
      receiptDate: receiptDate,
      quantity: quantity,
      totalPrice: totalPrice,
    );
  }
}
