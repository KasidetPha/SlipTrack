import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/transaction_event.dart';
import 'package:frontend/widgets/add_expense_page_widgets/add_expense_body.dart';
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

  // ===== Category data =====
  final List<_Category> _categories = const [
    _Category('Others', Icons.category_rounded, Color(0xFF64748B)),
    _Category('Food', Icons.restaurant_rounded, Color(0xFFF59E0B)),
    _Category('Shopping', Icons.shopping_bag_rounded, Color(0xFF8B5CF6)),
    _Category('Bills', Icons.receipt_long_rounded, Color(0xFF10B981)),
    _Category('Transportation', Icons.directions_bus_filled_rounded, Color(0xFF3B82F6)),
  ];

  int? _suggestCategoryIndex() {
    final name = _nameController.text.toLowerCase();
    final notes = _notesController.text.toLowerCase();
    final text = '$name $notes';

    bool has(List<String> keys) => keys.any(text.contains);

    if (has(['food', 'eat', 'dinner', 'lunch', 'rice', 'kfc', 'mk', 'กิน', 'ข้าว', 'อาหาร', 'หนม'])) return 1; // Food
    if (has(['shop', 'mall', 'lazada', 'shopee', 'clothes', 'ซื้อ', 'ของ', 'เสื้อ'])) return 2; // Shopping
    if (has(['bill', 'electric', 'water', 'internet', 'netflix', 'spotify', 'ค่าไฟ', 'ค่าน้ำ', 'เน็ต'])) return 3; // Bills
    if (has(['bus', 'train', 'bts', 'mrt', 'grab', 'taxi', 'gas', 'oil', 'รถ', 'เดินทาง', 'น้ำมัน'])) return 4; // Transportation

    return null; // Default or Others
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
    _loadSettings();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

    void refreshAuto() {
      if (_categoryMode != CategoryMode.auto) return;

      setState(() => _autoCategoryIndex = _suggestCategoryIndex());
    }

    _nameController.addListener(refreshAuto);
    _notesController.addListener(refreshAuto);
    _autoCategoryIndex = _suggestCategoryIndex();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isManual = prefs.getBool(_prefKeyMode) ?? false;
    if (mounted) {
      setState(() {
        _categoryMode = isManual ? CategoryMode.manual : CategoryMode.auto;
        if (_categoryMode == CategoryMode.auto) {
          _autoCategoryIndex = _suggestCategoryIndex();
        }
      });
    }
  }

  Future<void> _saveSettings(CategoryMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMode, mode == CategoryMode.manual);
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {

      setState(() => _isLoading = true);

      try {
      final amountRaw = _amountController.text.replaceAll(',', '');
      final amount = double.parse(amountRaw);

      final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);

      String categoryName;
      if (_categoryMode == CategoryMode.auto && _autoCategoryIndex != null) {
        categoryName = _categories[_autoCategoryIndex!].name;
      } else {
        categoryName = _categories[_selectedCategoryIndex].name;
      }

      await ReceiptService().addExpense(
        amount: amount,
        itemName: _nameController.text,
        storeName: null,
        date: date,
        categoryName: categoryName,
        note: _notesController.text.isEmpty ? null : _notesController.text
      );

      if (mounted) {
        TransactionEvent.triggerRefresh();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกสำเร็จ!"), backgroundColor: Colors.green,)
        );

        TransactionEvent.triggerRefresh();
        
        Navigator.pop(context);
      }

      final transaction = ExpenseTransaction(
        amount: amount,
        source: _nameController.text,
        date: DateFormat('dd/MM/yyyy').parse(_dateController.text),
        note: _notesController.text,
        categoryName: categoryName
      );

      debugPrint("บันทึกข้อมูล: $transaction");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกยอด ${transaction.amount} บาท เรียบร้อย!'),
          backgroundColor: Colors.green,
        )
      );
      
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
                      Text("Order Name", style: _labelStyle(),),
                      SizedBox(height: 12,),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.prompt(),
                        decoration: _inputDecoration(
                          hint: "Name",
                          prefixIcon: const Icon(Icons.person_outline_rounded)
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
                                  if (_categoryMode == CategoryMode.auto) {
                                    _autoCategoryIndex = _suggestCategoryIndex();
                                  }
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
                                  _autoCategoryIndex == null
                                  ? "Auto: Not sure yet (switch to Manual)"
                                  : "Auto: ${_categories[_autoCategoryIndex!].name}",
                                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                                )
                              )
                            ],
                          ),
                        )
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _categories.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: crossAxisCount <= 2 ? 2.1 : 0.95,
                          ),
                          itemBuilder: (_, i) {
                            final c = _categories[i];
                            final selected = i == _selectedCategoryIndex;
                            return _CategoryCard(
                              name: c.name,
                              icon: c.icon,
                              color: c.color,
                              selected: selected,
                              onTap: () => setState(() => _selectedCategoryIndex = i),
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
              onPressed: _onSave,
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