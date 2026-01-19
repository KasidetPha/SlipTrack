import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class AddIncomeBody extends StatefulWidget {
  const AddIncomeBody({super.key});
  @override
  State<AddIncomeBody> createState() => _AddIncomeBodyState();
}

enum CategoryMode { auto, manual }

class _AddIncomeBodyState extends State<AddIncomeBody> {

  static const Color kPrimary = Color(0xFF16A34A);
  static const Color kBorder = Color(0x1A000000);
  static const Color kFill = Colors.white;

  CategoryMode _categoryMode = CategoryMode.auto;
  int? _autoCategoryIndex; // หมวดที่ระบบเดาให้ (null ได้)
  int _selectedCategoryIndex = 0; // manual pick

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final NumberFormat _formatter = NumberFormat.decimalPattern('th_TH');
  final TextEditingController _dateController = TextEditingController();

  int? _suggestCategoryIndex() {
    final source = _sourceController.text.toLowerCase();
    final notes = _notesController.text.toLowerCase();
    final text = '$source $notes';

    bool has(List<String> keys) => keys.any(text.contains);

    if (has(['salary', 'payroll', 'เงินเดือน'])) return 0;
    if (has(['wage', 'job', 'freelance', 'ค่าจ้าง', 'รับจ๊อบ'])) return 1;
    if (has(['gift', 'present', 'donate', 'ให้', 'ของขวัญ'])) return 2;
    if (has(['sale', 'business', 'store', 'ขาย', 'ค้าขาย'])) return 3;

    return null;
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

  // ===== Category data =====
  final List<_Category> _categories = const [
    _Category('Salary', Icons.payments_rounded, Color(0xFF64748B)), // เงินเดือน
    _Category('Wages', Icons.work_rounded, Color(0xFFF59E0B)), // ค่าจ้าง/รับจ๊อบ
    _Category('Gift', Icons.card_giftcard_rounded, Color(0xFF8B5CF6)), // มีคนให้
    _Category('Business Sales',Icons.storefront_rounded, Color(0xFF10B981)), // ค้าขาย
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

    void refreshAuto() {
      if (_categoryMode != CategoryMode.auto) return;
      setState(() => _autoCategoryIndex = _suggestCategoryIndex());
    }
    _sourceController.addListener(refreshAuto);
    _notesController.addListener(refreshAuto);

    _autoCategoryIndex = _suggestCategoryIndex();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dateController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _gridCrossAxisCount(double width) {
    if (width < 360) return 2;
    if (width < 430) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = _gridCrossAxisCount(width);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24,24,24,24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Amount", style: _labelStyle()),
          SizedBox(height: 12),
          TextFormField(
            controller: _controller,
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
          ),
          SizedBox(height: 12,),
          Text("Income source", style: _labelStyle()),
          SizedBox(height: 12,),
          TextFormField(
            style: GoogleFonts.prompt(),
            controller: _sourceController,
            decoration: _inputDecoration(
              hint: "Name",
              prefixIcon: const Icon(Icons.person_outline_rounded)
            )
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

          Text("Notes", style: _labelStyle()),
          SizedBox(height: 12,),
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
          SizedBox(height: 12,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Category", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700),),
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
                      if (_categoryMode == CategoryMode.auto) {
                        _autoCategoryIndex = _suggestCategoryIndex();
                      }
                    });
                  },
                  style: ButtonStyle(
                    side: WidgetStateProperty.all(
                      const BorderSide(color: kBorder),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(14)),
                    )
                  )
                ),
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
                childAspectRatio: crossAxisCount  <= 2 ? 2.1 : 0.95,
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
            SizedBox(height: 24,),
          ],
        ]
      ),
    );
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
                maxLines: 2,
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