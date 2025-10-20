// lib/models/category_detail.dart
class CategoryDetail {
  final int? itemId;          // <- เพิ่ม
  final int? categoryId;      // <- เพิ่ม
  final String itemName;
  final DateTime? receiptDate;
  final int quantity;
  final double totalPrice;

  CategoryDetail({
    required this.itemId,      // <- เพิ่ม
    required this.categoryId,  // <- เพิ่ม
    required this.itemName,
    required this.receiptDate,
    required this.quantity,
    required this.totalPrice,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    // รองรับหลาย key ชื่อ
    final rawItemId = json['item_id'] ?? json['id'] ?? json['receipt_item_id'];
    final rawCateId = json['category_id'] ?? json['categoryId'];
    final rawName   = json['item_name'] ?? json['itemName'];
    final rawDate   = json['receipt_date'] ?? json['receiptDate'];
    final rawQty    = json['quantity'];
    final rawAmt    = json['total_price'] ?? json['totalPrice'];

    final int? itemId = () {
      if (rawItemId == null) return null;
      if (rawItemId is num) return rawItemId.toInt();
      return int.tryParse(rawItemId.toString());
    }();

    final int? categoryId = () {
      if (rawCateId == null) return null;
      if (rawCateId is num) return rawCateId.toInt();
      return int.tryParse(rawCateId.toString());
    }();

    final String itemName = (rawName ?? '').toString();

    DateTime? receiptDate;
    if (rawDate != null && rawDate.toString().trim().isNotEmpty) {
      try {
        receiptDate = DateTime.parse(rawDate.toString());
      } catch (_) {
        receiptDate = null;
      }
    }

    final int quantity = () {
      if (rawQty == null) return 0;
      if (rawQty is num) return rawQty.toInt();
      return int.tryParse(rawQty.toString()) ?? 0;
    }();

    final double totalPrice = () {
      if (rawAmt == null) return 0.0;
      if (rawAmt is num) return rawAmt.toDouble();
      return double.tryParse(rawAmt.toString()) ?? 0.0;
    }();

    return CategoryDetail(
      itemId: itemId,
      categoryId: categoryId,
      itemName: itemName,
      receiptDate: receiptDate,
      quantity: quantity,
      totalPrice: totalPrice,
    );
  }
}
