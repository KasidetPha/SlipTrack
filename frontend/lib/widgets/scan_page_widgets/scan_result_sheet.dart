import 'package:flutter/material.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/widgets/Edit_Receipt_Item_Sheet.dart';

class ScanResultSheet extends StatelessWidget {
  final List<ReceiptItem> items;
  const ScanResultSheet({super.key, required this.items});

@override
Widget build(BuildContext context) {
  // ใช้ ListView.builder แทน Column.map เพื่อประสิทธิภาพที่ดีกว่า
  return ListView.builder(
    shrinkWrap: true, // ทำให้ ListView มีขนาดเท่ากับจำนวนของที่มี (สำคัญมาก)
    physics: const NeverScrollableScrollPhysics(), // ปิดการ scroll ของตัวเองถ้ามีตัวแม่คุมอยู่แล้ว
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return ListTile(
        title: Text(item.item_name),
        trailing: Text('${item.total_price}'),
        onTap: () async {
          final updated = await showModalBottomSheet(
            context: context, 
            isScrollControlled: true,
            builder: (_) => EditReceiptItemSheet(item: item)
          );

          if (updated != null) {
            // update list logic
          }
        },
      );
    },
  );
}}