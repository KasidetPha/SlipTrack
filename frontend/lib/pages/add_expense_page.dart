import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/transaction_event.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CategoryMode { auto, manual }

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  static const Color kPrimary = Color(0xFFFB2966);
  static const Color kBorder = Color(0x1A000000);
  static const Color kFill = Colors.white;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const String _prefKeyMode = 'last_category_mode';

  bool _isLoading = false;

  CategoryMode _categoryMode = CategoryMode.auto;
  int? _autoCategoryIndex;
  int _selectedCategoryIndex = 0;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final NumberFormat _formatter = NumberFormat.decimalPattern('th_TH');

  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF64748B);
    
    // ลบเครื่องหมาย # ออกก่อน (ถ้ามี)
    hex = hex.replaceAll('#', '');
    
    // เติม 'FF' ข้างหน้าเพื่อให้สีทึบแสง 100% (Alpha)
    if (hex.length == 6) hex = 'FF$hex';
    
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF64748B);
  }

  // ปรับให้รับ categoryName มาช่วยเช็คด้วย เผื่อ icon_name ใน DB เป็น Null
IconData _parseIcon(String? iconName, String categoryName) {
    final icon = iconName?.trim().toLowerCase() ?? '';
    final cat = categoryName.trim().toLowerCase();

    // 1. แมตช์กับข้อมูลในคอลัมน์ icon_name จาก Database ตรงๆ เลย
    switch (icon) {
      case 'restaurant': return Icons.restaurant_rounded;
      case 'shopping_bag': return Icons.shopping_bag_rounded;
      case 'receipt_long': return Icons.receipt_long_rounded;
      case 'directions_bus': return Icons.directions_bus_filled_rounded;
      case 'payments': return Icons.account_balance_wallet_rounded;
      case 'work': return Icons.monetization_on_rounded;
      case 'card_giftcard': return Icons.redeem_rounded;
      case 'sell': return Icons.storefront_rounded;
      case 'category': return Icons.category_rounded;
    }

    // 2. ระบบสำรอง: ถ้าสร้างหมวดหมู่ใหม่แล้วไม่ได้ใส่ icon_name มา ให้เดาจากชื่อหมวดหมู่
    if (cat.contains('food') || cat.contains('อาหาร')) return Icons.restaurant_rounded;
    if (cat.contains('shop') || cat.contains('ช้อป')) return Icons.shopping_bag_rounded;
    if (cat.contains('bill') || cat.contains('บิล') || cat.contains('ค่า')) return Icons.receipt_long_rounded;
    if (cat.contains('transport') || cat.contains('รถ') || cat.contains('เดินทาง')) return Icons.directions_bus_filled_rounded;

    // 3. ค่า Default สุดท้าย ถ้านึกไม่ออกจริงๆ ให้ใช้รูปเรขาคณิต
    return Icons.category_rounded;
  }
  TextStyle _labelStyle() => GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w800);

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? padding,
    String? suffixText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: kFill,
      hintText: hint,
      hintStyle: GoogleFonts.prompt(color: Colors.black.withOpacity(0.35)),
      contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.55)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kBorder, width: 1.6),
        borderRadius: BorderRadius.circular(12)
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kPrimary, width: 1.6),
        borderRadius: BorderRadius.circular(12)
      )
    );
  }

  int _gridCrossAxisCount(double width) {
    if (width < 360) return 2;
    if (width < 430) return 3;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    // _loadSettings();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoadingCategories = true);
      final categories = await ReceiptService().getCategoryMaster();
      if (mounted) {
        setState(() {
          // กรองเอาเฉพาะฝั่งรายจ่าย
          _categories = categories.where((c) => c['entry_type'] == 'expense').toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _saveSettings(CategoryMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMode, mode == CategoryMode.manual);
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มหมวดหมู่ใหม่'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "ชื่อหมวดหมู่"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                bool success = await ReceiptService().addNewCategory(nameController.text.trim(), 'expense');
                if (success && mounted) {
                  Navigator.pop(context);
                  _fetchCategories(); // โหลดข้อมูลใหม่เพื่อรีเฟรชหน้าจอ
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {

      setState(() => _isLoading = true);

      try {
        final amountRaw = _amountController.text.replaceAll(',', '');
        final amount = double.parse(amountRaw);

        final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);

        String categoryName;
        if (_categoryMode == CategoryMode.auto) {
          categoryName = "Auto";
        } else {
          if (_categories.isNotEmpty && _selectedCategoryIndex < _categories.length) {
            categoryName = _categories[_selectedCategoryIndex]['category_name'];
          }
          else {
            categoryName = "Others";
          }
        }

        await ReceiptService().addExpense(
          amount: amount,
          itemName: _nameController.text,
          storeName: null,
          date: date,
          categoryName: categoryName,
          note: _notesController.text.isEmpty ? null : _notesController.text
        );

        final transaction = ExpenseTransaction(
          amount: amount,
          source: _nameController.text,
          date: DateFormat('dd/MM/yyyy').parse(_dateController.text),
          note: _notesController.text,
          categoryName: categoryName
        );

        debugPrint("บันทึกข้อมูล: $transaction");

        if (mounted) {
          TransactionEvent.triggerRefresh();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("บันทึกสำเร็จ!"), backgroundColor: Colors.green,)
          );

          Navigator.pop(context);
        }
      
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("บันทึกไม่สำเร็จ: $e"), backgroundColor: Colors.red,)
          );
        }
      } finally {
        if (mounted) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _gridCrossAxisCount(width);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
          toolbarHeight: 80,
          title: const Text('Add Expense'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              // borderRadius: BorderRadius.vertical(
              //   bottom: Radius.circular(30)
              // ),
              gradient: LinearGradient(
                colors: [Color(0xFFFF5E62), Color(0xFFFB2966)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24,24,24,96),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Amount", style: _labelStyle()),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                          _ThousandsFormatter(_formatter)
                        ],
                        style: GoogleFonts.prompt(
                          fontSize: 44,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: _inputDecoration(
                          hint: "0",
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right:14),
                            child: Center(
                              widthFactor: 0,
                              child: Text(
                                "฿",
                                style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.55)),
                              ),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาระบุจำนวนเงิน';
                          }
                  
                          return null;
                        },
                      ),
                      SizedBox(height: 12,),
                      Text("Title", style: _labelStyle(),),
                      SizedBox(height: 12,),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.prompt(),
                        decoration: _inputDecoration(
                          hint: "Expense name",
                          prefixIcon: const Icon(Icons.account_balance_wallet_rounded)
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาระบุที่มา';
                          } 
                  
                          return null;
                        },
                      ),
                      SizedBox(height: 12,),
                      Text("Date", style: _labelStyle()),
                      SizedBox(height: 12,),
                      TextFormField(
                        style: GoogleFonts.prompt(),
                        controller: _dateController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          hint: "Select a date",
                          suffixIcon: const Icon(Icons.calendar_today_rounded)
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                        
                          if (pickedDate != null) {
                            String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
                            setState(() {
                              _dateController.text = formattedDate;
                            });
                          }
                        },
                      ),
                        
                      SizedBox(height: 12,),
                        
                      Text("Notes", style: _labelStyle(),),
                      SizedBox(height: 12,),
                      TextFormField(
                        controller: _notesController,
                        style: GoogleFonts.prompt(),
                        minLines: 4,
                        maxLines: 6,
                        decoration: _inputDecoration(
                          hint: "What is this expense for?",
                          prefixIcon: const Icon(Icons.notes_rounded)
                        )
                      ),
                      SizedBox(height: 12,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Category", style: _labelStyle(),),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: SegmentedButton<CategoryMode>(
                              segments: const [
                                ButtonSegment(value: CategoryMode.auto, label: Text("Auto"), icon: Icon(Icons.auto_awesome_rounded)),
                                ButtonSegment(value: CategoryMode.manual, label: Text("Manual"), icon: Icon(Icons.touch_app_rounded))
                              ],
                              selected: {_categoryMode},
                              onSelectionChanged: (s) {
                                final newMode = s.first;
                                setState(() {
                                  _categoryMode = newMode;
                                });
                                _saveSettings(newMode);
                              },
                              style: ButtonStyle(
                                side: WidgetStateProperty.all(
                                  const BorderSide(color: kBorder)
                                ),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(14)),
                                )
                              ),
                            )
                          )
                        ],
                      ),
                      SizedBox(height: 12,),
                      // ===== Category Grid (แถวละ 4) =====
                      if (_categoryMode == CategoryMode.auto) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.5))
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded),
                              const SizedBox(width: 10,),
                              Expanded(
                                child: Text(
                                  _autoCategoryIndex == null || _categories.isEmpty
                                  ? "Auto: Not sure yet (switch to Manual)"
                                  : "Auto: ${_categories[_autoCategoryIndex!]['category_name']}",
                                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                                )
                              )
                            ],
                          ),
                        )
                      ] else ...[
                        if (_isLoadingCategories) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: kPrimary),
                            ),
                          ),
                        ] else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _categories.length + 1,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: crossAxisCount <= 2 ? 2.1 : 0.95,
                            ),
                            itemBuilder: (_, i) {
                              if (i == _categories.length) {
                                return _AddCategoryCard(onTap: _showAddCategoryDialog);
                              }

                              final c = _categories[i];
                              final selected = i == _selectedCategoryIndex;
                              final catName = c['category_name'] ?? 'Unknown';

                              return _CategoryCard(
                                name: c['category_name'] ?? 'Unknown', 
                                icon: _parseIcon(c['icon_name'], catName), 
                                color: _parseColor(c['color_hex']), 
                                selected: selected, 
                                onTap: () => setState(() => _selectedCategoryIndex = i)
                              );
                            },
                          ),
                      ],
                      SizedBox(height: 24,),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8), // กันชนกับขอบจอ
          child: SizedBox(
            width: 220,
            height: 56,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFF2563EB), // 🔵 สีน้ำเงินหลัก
              foregroundColor: Colors.white,             // ตัวอักษรเป็นสีขาว
              onPressed: _isLoading ? null : _onSave,
              label: Text(
                'Save',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              // icon: const Icon(Icons.check_rounded),
            ),
          ),
        ),
      ),
    );
  }
}

class ExpenseTransaction {
  final double amount;
  final String source;
  final DateTime date;
  final String? note;
  final String categoryName;

  ExpenseTransaction({
    required this.amount,
    required this.source,
    required this.date,
    this.note,
    required this.categoryName,
  });

  @override
  String toString() {
    return 'Expense: $amount | From: $source | Cate: $categoryName';
  }
}

class _ThousandsFormatter extends TextInputFormatter{
  final NumberFormat nf;
  _ThousandsFormatter(this.nf);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (raw.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final formatted = nf.format(int.parse(raw));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length)
    );
  }
}

// ===== category UI helpers =====

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  const _Category(this.name, this.icon, this.color);
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color.withOpacity(0.12) : cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : cs.outlineVariant.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCategoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_rounded, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                "เพิ่มหมวดหมู่",
                style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}