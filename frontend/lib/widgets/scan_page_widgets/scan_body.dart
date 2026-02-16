import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/transaction_event.dart';
import 'package:frontend/widgets/Edit_Receipt_Item_Sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ScanBody extends StatefulWidget {
  const ScanBody({super.key});

  @override
  State<ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends State<ScanBody> {
  // ====== Mock data: เรียกใช้กับ modal (UI เท่านั้น) ======
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  bool _isSavingBatch = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isScanning) return;
    try {
      final XFile? photo = await _picker.pickImage(
        source: source, 
        imageQuality: 80,
        maxWidth: 1024
      );

      if (photo != null) {
        File imageFile = File(photo.path);
        await _uploadAndScanReceipt(imageFile);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _uploadAndScanReceipt(File imageFile) async {
    setState(() => _isScanning = true);

    try {
      const String scanApiUrl = "http://192.168.1.12:8000/scan-receipt";
      var uri = Uri.parse(scanApiUrl);
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        print("Server Response: $responseBody");

        final jsonResponse = jsonDecode(responseBody);
        

        if (jsonResponse['items'] is List) {
          final items = _parseItems(jsonResponse['items']);
          if (mounted) {
            _showScanResultSheet(context, items);
          }
        } else {
          print("ไม่พบ items ใน Response");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่พบรายการสินค้า'))
            );
          }
        }

      } else {
        print("Server Error: ${response.statusCode}");
        print("Body: ${utf8.decode(response.bodyBytes)}");
      }

    } catch (e) {
      print("Error Uploading $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการแสกน: $e'))
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  List<ReceiptScanResult> _parseItems(List<dynamic> jsonItems) {
    return jsonItems.map((item) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final qty = int.tryParse('${item['qty']}')?? 1;
      int catId = int.tryParse('${item['category_id']}') ?? 1;

      print("DEBUG: Item ${item['name']} -> catId: $catId");

      DateTime date;
      try {
        date = DateTime.parse('${item['date']}');
      } catch (_) {
        date = DateTime.now();
      }
      return ReceiptScanResult(
        title: item['name'], 
        icon: Icons.restaurant, 
        iconBg: const Color(0xFFE67E22), 
        date: date, 
        qty: qty, 
        amount: -(price * qty),
        // amount: -1.0 * (item['price'] as num).toDouble(),
        categoryId: catId
        // bbox: item['bounding_box'] // TODO เก็บไว้ใช้ทีหลัง
      );
    }).toList();
  }

  Future<void> _saveAllItems(List<ReceiptScanResult> items, BuildContext modalContext) async {

    if (items.isEmpty) return;

    setState(() => _isSavingBatch = true);

    try {
      double totalAmount = 0;

      final List<ReceiptItem> itemsToSave = items.map((scanRes) {
        final price = scanRes.amount.abs().toDouble();
        totalAmount += price;

        return ReceiptItem.fromScanResult(scanRes); 
      }).toList();

      await ReceiptService().createBatchReceipt(
        merchantName: "7-11", // TODO: ดึงจาก OR
        receiptDate: items.isNotEmpty ? items[0].date : DateTime.now(), 
        totalAmount: totalAmount, 
        items: itemsToSave
      );

      TransactionEvent.triggerRefresh();

      if (!mounted) return;

      // Navigator.pop(modalContext);
      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกรายการทั้งหมดเรียบร้อย'),
          backgroundColor: Colors.green,
        )
      );

      // setState(() {
      //   _isScanning = false;
      // });
    } catch (e) {
      print("Error saving batch: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBatch = false) ;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  radius: const Radius.circular(12),
                  strokeWidth: 2.5,
                  dashPattern: const [15, 5],
                  padding: EdgeInsets.zero,
                  color: Colors.grey.withOpacity(0.8),
                ),
              //   child: Container(
              //     decoration: BoxDecoration(
              //       color: Colors.grey.withOpacity(0.7),
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     height: 300,
              //   ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: Color(0xFF2563EB),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Photo or Select receipt",
                        style: GoogleFonts.prompt(
                            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Take a clear photo of the slip for best results.",
                        style: GoogleFonts.prompt(
                            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: InkWell(
                          onTap: () {
                            _pickImage(ImageSource.camera);
                            // _showScanResultSheet(context, _items);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 24),
                                const SizedBox(width: 12),
                                Text("Photo",
                                    style: GoogleFonts.prompt(
                                        color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: InkWell(
                          onTap: () {
                            _pickImage(ImageSource.gallery);
                            // _showScanResultSheet(context, _items);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image, color: Colors.black, size: 24),
                                const SizedBox(width: 12),
                                Text("Select from Gallery",
                                    style: GoogleFonts.prompt(
                                        color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _Tips(),
            ],
          ),
        ),

        if (_isScanning) 
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white
                  ),
                  const SizedBox(height: 16,),
                  Text("กำลังประมวลผล OCR...",
                    style: GoogleFonts.prompt(color: Colors.white, fontSize: 16),),
                ],
              ),
            )
          )
      ],
    );
  }

  // ====== UI: Modal Bottom Sheet (Scan Results) ======
  Future<void> _showScanResultSheet(BuildContext context, List<ReceiptScanResult> items) async {
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final dateFmt = DateFormat('dd/MM/yyyy');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModelState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollCtrl) {
                final cs = Theme.of(ctx).colorScheme;
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    // drag handle
                    Container(
                      width: 48, height: 5,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant, borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scan receipt',
                                    style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w700)),
                                Text('รายการที่ตรวจพบจากสลิป',
                                    style: GoogleFonts.prompt(
                                        fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Text('${items.length}',
                              style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w800, fontSize: 16, color: cs.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // List
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return _ReceiptTile(
                            icon: it.icon,
                            iconBg: it.iconBg,
                            title: it.title,
                            qtyText: 'x${it.qty}',
                            dateText: dateFmt.format(it.date),
                            amountText: currency.format(it.amount.abs()),
                            isExpense: it.amount < 0,
                            onTap: () async {
                              final updated = await showModalBottomSheet<dynamic>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(24)),
                                ),
                                builder: (_) {
                                  return EditReceiptItemSheet(
                                    item: ReceiptItem.fromScanResult(it),
                                    isScanMode: true,
                                  );
                                }
                              );
            
                              if (updated!= null && updated is ReceiptItem) {
                                setModelState(() {
                                  items[i] = ReceiptScanResult(
                                    title: updated.item_name, 
                                    icon: it.icon, 
                                    iconBg: it.iconBg, 
                                    date: updated.receiptDate, 
                                    qty: updated.quantity, 
                                    categoryId: updated.category_id,
                                    amount: updated.entryType == 'expense' ? -updated.total_price : updated.total_price
                                  );
                                });

                                if (mounted) setState(() {});
                              }
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: items.length,
                      ),
                    ),
                    // Bottom actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          // Expanded(
                          //   child: OutlinedButton.icon(
                          //     onPressed: () {
                          //       // TODO: ไปหน้าแก้ไขทั้งหมด
                          //     },
                          //     icon: const Icon(Icons.edit_outlined),
                          //     label: Text('Edit all', style: GoogleFonts.prompt()),
                          //     style: OutlinedButton.styleFrom(
                          //       padding: const EdgeInsets.symmetric(vertical: 14),
                          //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSavingBatch
                                ? null
                                : () {
                                  _saveAllItems(items, ctx);
                                },
                              icon: _isSavingBatch
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.check_rounded),
                              label: Text(
                                  _isSavingBatch ? 'Saving...' : 'Save All',
                                ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }
        );
      },
    );
  }
}

// ====== Tiles & Models ======

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.qtyText,
    required this.dateText,
    required this.amountText,
    required this.isExpense,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String qtyText;
  final String dateText;
  final String amountText;
  final bool isExpense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.onSurface.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
            border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // บรรทัดแรก: title + x1 + amount
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isExpense ? '-$amountText' : amountText,
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // บรรทัดสอง: date + x1
                    Row(
                      children: [
                        Text(dateText,
                            style: GoogleFonts.prompt(fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Text(qtyText,
                            style: GoogleFonts.prompt(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiptScanResult {
  final String title;
  final IconData icon;
  final Color iconBg;
  final DateTime date;
  final int qty;
  final num amount; // ติดลบ = รายจ่าย
  final int? categoryId;
  ReceiptScanResult({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.date,
    required this.qty,
    required this.amount,
    this.categoryId,
  });
}

// ====== Tips Box (เดิม) ======
class _Tips extends StatelessWidget {
  const _Tips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Colors.amber),
              const SizedBox(width: 12),
              Text("Tips for a better scan",
                  style: GoogleFonts.prompt(
                      fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
            ],
          ),
          const SizedBox(height: 12),
          Text('- Good lighting',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
          Text('- Full receipt in frame',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
          Text('- No shadows or glare',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
        ]),
      ),
    );
  }
}
