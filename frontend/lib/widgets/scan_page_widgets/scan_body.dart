import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/transaction_event.dart';
import 'package:frontend/widgets/Edit_Receipt_Item_Sheet.dart';
import 'package:frontend/widgets/scan_page_widgets/receipt_preview_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  File? _lastPickedImage;
  double _imgWidth = 0;
  double _imgHeight = 0;

  String _detectedMerchant = "ไม่ทราบชื่อร้าน";
  DateTime _selectedReceiptDate = DateTime.now();

  Future<void> _pickImage(ImageSource source) async {
    if (_isScanning) return;
    try {
      final XFile? photo = await _picker.pickImage(
        source: source, 
        imageQuality: 100,
      );

      if (photo != null) {
        File imageFile = File(photo.path);
        final decodedImage = await decodeImageFromList(await imageFile.readAsBytes());

        setState(() {
          _lastPickedImage = imageFile;
          _imgWidth = decodedImage.width.toDouble();
          _imgHeight = decodedImage.height.toDouble();
        });
        
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

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      request.headers.addAll({
        'Authorization': 'Bearer $token'
      });

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        print("Server Response: $responseBody");

        final jsonResponse = jsonDecode(responseBody);
        _detectedMerchant = jsonResponse['merchant_name'] ?? "ไม่ทราบชื่อร้าน";

        if (jsonResponse['processed_image_base64'] != null) {
          String base64String = jsonResponse['processed_image_base64'];
          Uint8List decodedBytes = base64Decode(base64String);

          final tempDir = await getTemporaryDirectory();
          File processedFile = File('${tempDir.path}/processed_receipt_current.png');
          await processedFile.writeAsBytes(decodedBytes);

          PaintingBinding.instance.imageCache.evict(FileImage(processedFile));
          
          setState(() {
            _lastPickedImage = processedFile;
            _imgWidth = (jsonResponse['processed_width'] ?? 0).toDouble();
            _imgHeight = (jsonResponse['processed_height'] ?? 0).toDouble();
          });
        }

        if (jsonResponse['items'] is List) {
          final items = _parseItems(jsonResponse['items']);
          
          // 🌟 ดึงวันที่จาก OCR มาเป็นค่าเริ่มต้น 🌟
          if (items.isNotEmpty) {
            _selectedReceiptDate = items.first.date; 
          }

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
    // 1. แปลงข้อมูล JSON เป็น Object ตามปกติ
    final parsedList = jsonItems.map((item) {
      // รองรับทั้ง key 'price', 'unit_price' และ 'total_item_price'
      final priceStr = item['price'] ?? item['unit_price'] ?? item['total_item_price'] ?? '0';
      final price = double.tryParse(priceStr.toString()) ?? 0.0;
      
      final qty = int.tryParse('${item['qty']}') ?? 1;
      int catId = int.tryParse('${item['category_id']}') ?? 1;

      DateTime date;
      try {
        date = DateTime.parse('${item['date']}');
      } catch (_) {
        date = DateTime.now();
      }
      
      return ReceiptScanResult(
        id: UniqueKey().toString(),
        title: item['name'] ?? 'Unknown', 
        icon: Icons.restaurant, 
        iconBg: const Color(0xFFE67E22), 
        date: date, 
        qty: qty, 
        amount: -(price * qty), 
        categoryId: catId,
        boundingBox: item['bounding_box'] != null
          ? BoundingBox.fromJson(item['bounding_box'])
          : null
      );
    }).toList();

    return parsedList.where((item) => item.amount != 0).toList();
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
        merchantName: _detectedMerchant,
        receiptDate: _selectedReceiptDate, 
        totalAmount: totalAmount, 
        items: itemsToSave
      );

      TransactionEvent.triggerRefresh();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกรายการทั้งหมดเรียบร้อย'),
          backgroundColor: Colors.green,
        )
      );

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
      if (mounted) setState(() => _isSavingBatch = false);
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
              initialChildSize: 0.85, 
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollCtrl) {
                final cs = Theme.of(ctx).colorScheme;
                
                return CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    
// --- ส่วนที่ 1: Header และ รูปภาพ ---
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Drag handle
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // 🌟 ปรับปรุง UI ส่วน Header 🌟
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Receipt Image Preview
                                  if (_lastPickedImage != null)
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext ctx) {
                                            return Dialog.fullscreen(
                                              backgroundColor: Colors.black,
                                              child: Stack(
                                                children: [
                                                  SafeArea(
                                                    child: Center(
                                                      child: ReceiptPreviewOverlay(
                                                        imageFile: _lastPickedImage!,
                                                        items: items,
                                                        originalWidth: _imgWidth,
                                                        originalHeight: _imgHeight
                                                      ),
                                                    )
                                                  ),
                                                  Positioned(
                                                    top: 16,
                                                    right: 16,
                                                    child: SafeArea(
                                                      child: CircleAvatar(
                                                        backgroundColor: Colors.white.withOpacity(0.2),
                                                        child: IconButton(
                                                          onPressed: () => Navigator.of(ctx).pop(),
                                                          icon: const Icon(Icons.close_rounded, color: Colors.white)
                                                        ),
                                                      )
                                                    ),
                                                  )
                                                ],
                                              ),
                                            );
                                          }
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 160, // ลดความสูงรูปลงนิดหน่อยให้พอดี Card
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: IgnorePointer(
                                            child: ReceiptPreviewOverlay(
                                              imageFile: _lastPickedImage!,
                                              items: items,
                                              originalWidth: _imgWidth,
                                              originalHeight: _imgHeight,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Header Info (Scan receipt & Items count)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('สแกนใบเสร็จสำเร็จ',
                                                  style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                                              Text('พบ ${items.length} รายการ',
                                                  style: GoogleFonts.prompt(
                                                      fontSize: 13, color: cs.onSurfaceVariant)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: cs.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text('${items.length}',
                                              style: GoogleFonts.prompt(
                                                  fontWeight: FontWeight.w700, fontSize: 16, color: cs.primary)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),

                                  // Date Picker
                                  InkWell(
                                    onTap: () async {
                                      final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedReceiptDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: cs.primary,
                                                onPrimary: Colors.white,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null && picked != _selectedReceiptDate) {
                                        setModelState(() {
                                          _selectedReceiptDate = picked;
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today_rounded, color: cs.onSurfaceVariant, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'วันที่ใบเสร็จ',
                                              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  dateFmt.format(_selectedReceiptDate), 
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 14, 
                                                    color: Colors.black87, 
                                                    fontWeight: FontWeight.w600
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(Icons.edit_rounded, color: cs.primary, size: 14),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // --- สิ้นสุดส่วนที่ 1 ---

                    // --- ส่วนที่ 2: รายการสินค้า (List Items) ---
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final it = items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10), 
                              child: Dismissible(
                                key: Key(it.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(16)
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  setModelState(() {
                                    items.removeAt(i);
                                  });
                                  if (mounted) setState(() {});

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('ลบรายการ "${it.title}" ออกแล้ว', style: GoogleFonts.prompt()),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    )
                                  );
                                },
                                child: _ReceiptTile(
                                  icon: it.icon,
                                  iconBg: it.iconBg,
                                  title: it.title,
                                  qtyText: 'x${it.qty}',
                                  dateText: dateFmt.format(it.date), // รายการจะยังแสดงวันที่จาก OCR อยู่ (ถ้าต้องการเปลี่ยนให้โชว์เป็น _selectedReceiptDate ก็แก้ตรงนี้ได้ครับ)
                                  amountText: currency.format(it.amount.abs()),
                                  isExpense: it.amount < 0,
                                  onTap: () async {
                                    final updated = await showModalBottomSheet<dynamic>(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (_) => EditReceiptItemSheet(
                                        item: ReceiptItem.fromScanResult(it),
                                        isScanMode: true,
                                      ),
                                    );
                                            
                                    if (updated != null && updated is ReceiptItem) {
                                      setModelState(() {
                                        items[i] = ReceiptScanResult(
                                          id: it.id,
                                          title: updated.item_name, 
                                          icon: it.icon, 
                                          iconBg: it.iconBg, 
                                          date: updated.receiptDate, 
                                          qty: updated.quantity, 
                                          categoryId: updated.category_id,
                                          amount: updated.entryType == 'expense' ? -updated.total_price : updated.total_price,
                                          boundingBox: it.boundingBox,
                                        );
                                      });
                                      if (mounted) setState(() {});
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),

                    // --- ส่วนที่ 3: ปุ่มด้านล่างสุด ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSavingBatch ? null : () => _saveAllItems(items, ctx),
                            icon: _isSavingBatch 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded),
                            label: Text(_isSavingBatch ? 'Saving...' : 'บันทึกทั้งหมด', style: GoogleFonts.prompt()),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
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
  final String id;
  final String title;
  final IconData icon;
  final Color iconBg;
  final DateTime date;
  final int qty;
  final num amount; // ติดลบ = รายจ่าย
  final int? categoryId;
  final BoundingBox? boundingBox;
  ReceiptScanResult({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.date,
    required this.qty,
    required this.amount,
    this.categoryId,
    this.boundingBox
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