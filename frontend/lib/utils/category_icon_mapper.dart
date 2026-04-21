import 'package:flutter/material.dart';

class CategoryIconOption {
  final String key;
  final IconData icon;

  const CategoryIconOption(this.key, this.icon);
}

// ==========================================
// 🔴 1. เซ็ตไอคอนสำหรับ "รายจ่าย" (Expense)
// ==========================================
const List<CategoryIconOption> kExpenseIcons = [
  // CategoryIconOption('category', Icons.category_rounded),
  CategoryIconOption('restaurant', Icons.restaurant_rounded), // อาหาร
  CategoryIconOption('shopping_bag', Icons.shopping_bag_rounded), // ช้อปปิ้ง
  CategoryIconOption('receipt_long', Icons.receipt_long_rounded), // บิล/ค่าใช้จ่าย
  CategoryIconOption('directions_bus', Icons.directions_bus_rounded), // เดินทาง
  CategoryIconOption('local_hospital', Icons.local_hospital_rounded), // สุขภาพ/ยา
  CategoryIconOption('home', Icons.home_rounded), // บ้าน/ค่าเช่า
  CategoryIconOption('electrical_services', Icons.electrical_services_rounded), // ค่าไฟ
  CategoryIconOption('water_drop', Icons.water_drop_rounded), // ค่าน้ำ
  CategoryIconOption('phone_android', Icons.phone_android_rounded), // ค่าโทรศัพท์/เน็ต
  CategoryIconOption('sports_esports', Icons.sports_esports_rounded), // เกม/บันเทิง
  CategoryIconOption('pets', Icons.pets_rounded), // สัตว์เลี้ยง
  CategoryIconOption('school', Icons.school_rounded), // การศึกษา
  CategoryIconOption('flight', Icons.flight_rounded), // ท่องเที่ยว
];

// ==========================================
// 🟢 2. เซ็ตไอคอนสำหรับ "รายรับ" (Income)
// ==========================================
const List<CategoryIconOption> kIncomeIcons = [
  CategoryIconOption('payments', Icons.payments_rounded), // เงินเดือน
  CategoryIconOption('work', Icons.work_rounded), // ค่าจ้าง/ฟรีแลนซ์
  CategoryIconOption('card_giftcard', Icons.card_giftcard_rounded), // ของขวัญ/ให้เสน่หา
  CategoryIconOption('sell', Icons.sell_rounded), // ขายของ
  CategoryIconOption('account_balance', Icons.account_balance_rounded), // ดอกเบี้ย/ธนาคาร
  CategoryIconOption('trending_up', Icons.trending_up_rounded), // ลงทุน/ปันผล
  CategoryIconOption('real_estate_agent', Icons.real_estate_agent_rounded), // ค่าเช่ารับ
  CategoryIconOption('monetization_on', Icons.monetization_on_rounded), // โบนัส
  CategoryIconOption('savings', Icons.savings_rounded), // เงินเก็บ
  CategoryIconOption('volunteer_activism', Icons.volunteer_activism_rounded), // เงินสนับสนุน
];

// ==========================================
// 🟡 3. รวม List ไว้ใช้สำหรับตอนแสดงผลหน้า Grid
// ==========================================
final List<CategoryIconOption> kAllCategoryIconOptions = [
  ...kExpenseIcons,
  ...kIncomeIcons,
];

// ฟังก์ชันแปลง String เป็น Icon (ค้นหาจาก List รวม)
IconData getIconFromKey(String key) {
  final match = kAllCategoryIconOptions.where((o) => o.key == key);
  if (match.isNotEmpty) return match.first.icon;
  return Icons.category_rounded; // default ถ้าหา key ไม่เจอ
}

// ฟังก์ชันแปลงสี
Color colorFromHex(String hex) {
  var cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  return Color(int.parse(cleaned, radix: 16));
}