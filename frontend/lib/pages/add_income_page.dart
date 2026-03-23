import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/transaction_event.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum CategoryMode { auto, manual }

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  static const Color kPrimary = Color(0xFF16A34A);
  static const Color kBorder = Color(0x1A000000);
  static const Color kFill = Colors.white;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  CategoryMode _categoryMode = CategoryMode.auto;
  int? _autoCategoryIndex; 
  int _selectedCategoryIndex = 0; 

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final NumberFormat _formatter = NumberFormat.decimalPattern('th_TH');
  final TextEditingController _dateController = TextEditingController();

  // เปลี่ยนจาก Hardcode เป็น List Dynamic สำหรับดึงจาก DB
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ===== Helper Methods (เหมือนหน้า Expense) =====
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF64748B);
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF64748B);
  }

  IconData _parseIcon(String? iconName, String categoryName) {
    final icon = iconName?.trim().toLowerCase() ?? '';
    final cat = categoryName.trim().toLowerCase();

    switch (icon) {
      case 'payments': return Icons.account_balance_wallet_rounded;
      case 'work': return Icons.monetization_on_rounded;
      case 'card_giftcard': return Icons.redeem_rounded;
      case 'sell': return Icons.storefront_rounded;
      case 'category': return Icons.category_rounded;
    }

    if (cat.contains('salary') || cat.contains('เงินเดือน')) return Icons.payments_rounded;
    if (cat.contains('freelance') || cat.contains('งาน')) return Icons.work_rounded;
    if (cat.contains('gift') || cat.contains('ให้')) return Icons.card_giftcard_rounded;
    if (cat.contains('sale') || cat.contains('ขาย')) return Icons.storefront_rounded;

    return Icons.category_rounded;
  }

  // ฟังก์ชันดึงหมวดหมู่ (กรองเฉพาะ income)
  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoadingCategories = true);
      final categories = await ReceiptService().getCategoryMaster();
      if (mounted) {
        setState(() {
          _categories = categories.where((c) => c['entry_type'] == 'income').toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  // ฟังก์ชันเพิ่มหมวดหมู่รายรับ
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มหมวดหมู่ใหม่'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "ชื่อหมวดหมู่รายรับ"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                // ระบุประเภทเป็น 'income'
                bool success = await ReceiptService().addNewCategory(nameController.text.trim(), 'income');
                if (success && mounted) {
                  Navigator.pop(context);
                  _fetchCategories(); 
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsetsGeometry? padding,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: kFill,
      hintText: hint,
      hintStyle: GoogleFonts.prompt(color: Colors.black.withOpacity(0.35)),
      contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kBorder, width: 1.6),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kPrimary, width: 1.6),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w800);

  int _gridCrossAxisCount(double width) {
    if (width < 360) return 2;
    if (width < 430) return 3;
    return 4;
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
          } else {
            categoryName = "Others";
          }
        }

        await ReceiptService().addIncome(
          amount: amount,
          source: _sourceController.text,
          date: date,
          categoryName: categoryName,
          note: _notesController.text.isEmpty ? null : _notesController.text
        );

        if (mounted) {
          TransactionEvent.triggerRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกยอด $amount บาท เรียบร้อย!'), 
              backgroundColor: Colors.green,
            )
          );
          Navigator.pop(context);
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red,)
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
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
          title: const Text('Add Income'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0CC27E), Color(0xFF24B36B)],
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
                      const SizedBox(height: 12),
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
                            padding: const EdgeInsets.only(right: 14),
                            child: Center(
                              widthFactor: 0,
                              child: Text(
                                "฿",
                                style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black.withOpacity(0.55)),
                              ),
                            ),
                          )
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาระบุจำนวนเงิน';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12,),
                      Text("Income Source", style: _labelStyle()),
                      const SizedBox(height: 12,),
                      TextFormField(
                        style: GoogleFonts.prompt(),
                        controller: _sourceController,
                        decoration: _inputDecoration(
                          hint: "Salary, Freelance",
                          prefixIcon: const Icon(Icons.work_outline_rounded)
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาระบุที่มา';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12,),
                      Text("Date", style: _labelStyle()),
                      const SizedBox(height: 12,),
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
                      const SizedBox(height: 12,),
                      Text("Notes", style: _labelStyle()),
                      const SizedBox(height: 12,),
                      TextFormField(
                        controller: _notesController,
                        style: GoogleFonts.prompt(),
                        minLines: 4,
                        maxLines: 6,
                        decoration: _inputDecoration(
                          hint: "What is this income for?",
                          prefixIcon: const Icon(Icons.notes_rounded)
                        )
                      ),
                      const SizedBox(height: 12,),
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
                                ButtonSegment(value: CategoryMode.auto, label: Text('Auto'), icon: Icon(Icons.auto_awesome_rounded)),
                                ButtonSegment(value: CategoryMode.manual, label: Text('Manual'), icon: Icon(Icons.touch_app_rounded)),
                              ],
                              selected: {_categoryMode},
                              onSelectionChanged: (s) {
                                setState(() {
                                  _categoryMode = s.first;
                                });
                              },
                              style: ButtonStyle(
                                side: WidgetStateProperty.all(
                                  const BorderSide(color: kBorder),
                                ),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                )
                              )
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12,),
                      // ===== Category Grid =====
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
                              childAspectRatio: crossAxisCount  <= 2 ? 2.1 : 0.95,
                            ),
                            itemBuilder: (_, i) {
                              if (i == _categories.length) {
                                return _AddCategoryCard(onTap: _showAddCategoryDialog, color: kPrimary);
                              }

                              final c = _categories[i];
                              final selected = i == _selectedCategoryIndex;
                              final catName = c['category_name'] ?? 'Unknown';

                              return _CategoryCard(
                                name: catName,
                                icon: _parseIcon(c['icon_name'], catName),
                                color: _parseColor(c['color_hex']),
                                selected: selected,
                                onTap: () => setState(() => _selectedCategoryIndex = i),
                              );
                            },
                          ),
                      ],
                      const SizedBox(height: 24,),
                    ]
                  ),
                ),
              )
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8), 
          child: SizedBox(
            width: 220,
            height: 56,
            child: FloatingActionButton.extended(
              backgroundColor: _isLoading ? Colors.grey.shade400 : const Color(0xFF2563EB), 
              foregroundColor: Colors.white,             
              onPressed: _isLoading ? null : _onSave,
              label: _isLoading 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== formatters & models =====

class IncomeTransaction {
  final double amount;
  final String source;
  final DateTime date;
  final String? note;
  final String categoryName;

  IncomeTransaction({
    required this.amount,
    required this.source,
    required this.date,
    this.note,
    required this.categoryName,
  });

  @override
  String toString() {
    return 'Income: $amount | From: $source | Cate: $categoryName';
  }
}

class _ThousandsFormatter extends TextInputFormatter {
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
  final Color color;
  const _AddCategoryCard({required this.onTap, required this.color});

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
            border: Border.all(color: color.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.add_rounded, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                "เพิ่มหมวดหมู่",
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}