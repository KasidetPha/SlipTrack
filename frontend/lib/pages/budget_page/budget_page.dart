import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/widgets/filter_month_year.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/models/budget_model.dart';

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

// อัปเดตชุดสีให้ละมุนขึ้น สอดคล้องกับหน้าหลัก
class _AppColors {
  static const primary = Color(0xFF5046E8);
  static const background = Color(0xFFFAFAFA); // พื้นหลังสว่างแบบหน้าหลัก
  static const cardColor = Colors.white;
  static const text = Color(0xFF1E1E1E);
  static const subtleText = Color(0xFF8A8A8E);
  static const inputBg = Color(0xFFF3F4F6); // สีพื้นหลังช่องกรอกเงิน
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  // final BudgetService _budgetService = BudgetService();
  
  bool _isSaving = false;

  late int _selectedMonth;
  late int _selectedYear;

  // เก็บ Controllers ของแต่ละ Category
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  Future<void> _saveBudgets(BudgetResponse budgetData) async {

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      for (var item in budgetData.items) {
        final text = _controllers[item.categoryId]?.text.replaceAll(',', '') ?? '0';
        item.limitAmount = double.tryParse(text) ?? 0.0;
      }

      await ref.read(budgetControllerProvider).saveBudget(budgetData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกงบประมาณเรียบร้อย', style: GoogleFonts.prompt()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _syncControllers(BudgetResponse budgetData) {
    for (final item in budgetData.items) {
      _controllers.putIfAbsent(
        item.categoryId,
        () => TextEditingController(
          text: item.limitAmount > 0 ? item.limitAmount.toStringAsFixed(0) : '',
        ),
      );
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'receipt_long': return Icons.receipt_long;
      case 'directions_bus': return Icons.directions_bus;
      case 'category': return Icons.category;
      default: return Icons.category;
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetProvider((
      month: _selectedMonth,
      year: _selectedYear,
    )));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _AppColors.background,
        appBar: AppBar(
          backgroundColor: _AppColors.background,
          foregroundColor: _AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0, // ป้องกันสีเพี้ยนตอน Scroll
          centerTitle: true,
          title: Text(
            'ตั้งค่างบประมาณ',
            style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilterMonthYear(
                initialMonth: _selectedMonth,
                initialYear: _selectedYear,
                onMonthYearChanged: (month, year) {
                  setState(() {
                    _selectedMonth = month;
                    _selectedYear = year;
                  });
                },
                color: _AppColors.primary,
              ),
            ),
            Expanded(
              child: budgetAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'โหลดข้อมูลงบประมาณไม่สำเร็จ',
                    style: GoogleFonts.prompt(color: _AppColors.subtleText),
                  ),
                ),
                data: (budgetData) {
                  _syncControllers(budgetData);

                  return _buildForm(budgetData);
                },
              ),
            ),
            _buildBottomBar(budgetAsync.value),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BudgetResponse budgetData) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // --- Card 1: ตั้งค่าการแจ้งเตือน ---
        Container(
          decoration: BoxDecoration(
            color: _AppColors.cardColor,
            borderRadius: BorderRadius.circular(20), // มุมโค้งมนเหมือนหน้าหลัก
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
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                title: Text('แจ้งเตือนเมื่อใกล้ถึงงบ', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('ให้ระบบเตือนเมื่อยอดใช้จ่ายใกล้เต็ม', style: GoogleFonts.prompt(fontSize: 13, color: _AppColors.subtleText)),
                value: budgetData.warningEnabled,
                activeColor: _AppColors.primary,
                onChanged: (val) => setState(() => budgetData.warningEnabled = val),
              ),
              
              if (budgetData.warningEnabled) ...[
                Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('แจ้งเตือนเมื่อยอดถึง', style: GoogleFonts.prompt(fontSize: 14, color: _AppColors.text)),
                      Text('${budgetData.warningPercentage}%', style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: _AppColors.primary)),
                    ],
                  ),
                ),
                Slider(
                  value: budgetData.warningPercentage.toDouble(),
                  min: 50,
                  max: 100,
                  divisions: 10,
                  activeColor: _AppColors.primary,
                  inactiveColor: _AppColors.primary.withOpacity(0.15),
                  onChanged: (val) {
                    setState(() => budgetData.warningPercentage = val.toInt());
                  },
                ),
                const SizedBox(height: 8),
              ]
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        Text('หมวดหมู่รายจ่าย', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold, color: _AppColors.text)),
        const SizedBox(height: 16),

        // --- Card 2: รายการหมวดหมู่ (แยกทีละชิ้นแบบหน้าหลัก) ---
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: budgetData.items.length,
          itemBuilder: (context, index) {
            final item = budgetData.items[index];
            final color = Color(int.parse((item.colorHex ?? '#7F8C8D').replaceFirst('#', '0xFF')));
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _AppColors.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // ไอคอนหมวดหมู่
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_getIconData(item.iconName), color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  
                  // ชื่อหมวดหมู่
                  Expanded(
                    child: Text(
                      item.categoryName, 
                      style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: _AppColors.text)
                    ),
                  ),
                  
                  // ช่องกรอกเงิน (ดีไซน์ใหม่)
                  Container(
                    width: 110,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _controllers[item.categoryId],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            textAlign: TextAlign.right,
                            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: _AppColors.primary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.prompt(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('฿', style: GoogleFonts.prompt(color: _AppColors.subtleText, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBottomBar(BudgetResponse? budgetData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), // เผื่อที่ว่างด้านล่างสำหรับขอบจอโทรศัพท์
      decoration: BoxDecoration(
        color: _AppColors.background,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: (_isSaving || budgetData == null)
          ? null
          : () => _saveBudgets(budgetData),
          style: ElevatedButton.styleFrom(
            backgroundColor: _AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text('บันทึกการตั้งค่า', style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}