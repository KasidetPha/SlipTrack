import 'package:flutter/material.dart';
import 'package:frontend/models/category_master.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryFormResult {
  final String name;
  final Color color;
  final String iconName;

  const CategoryFormResult({
    required this.name,
    required this.color,
    required this.iconName,
  });
}

Future<CategoryFormResult?> showCategoryFormBottomSheet({
  required BuildContext context,
  required bool isIncome,
  CategoryMaster? category,
}) {
  return showModalBottomSheet<CategoryFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryFormBottomSheet(
      isIncome: isIncome,
      category: category,
    ),
  );
}

const List<Color> _availableColors = [
  Colors.blue,
  Colors.green,
  Colors.red,
  Colors.orange,
  Colors.purple,
  Colors.pink,
  Colors.teal,
  Colors.amber,
  Colors.cyan,
];

class CategoryFormBottomSheet extends StatefulWidget {
  final bool isIncome;
  final CategoryMaster? category;

  const CategoryFormBottomSheet({
    super.key,
    required this.isIncome,
    this.category,
  });

  @override
  State<CategoryFormBottomSheet> createState() =>
      _CategoryFormBottomSheetState();
}

class _CategoryFormBottomSheetState extends State<CategoryFormBottomSheet> {
  final TextEditingController _nameController = TextEditingController();

  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;

  String _hexFromColor(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();

    if (widget.category != null) {
      _nameController.text = widget.category!.categoryName;

      final existingColor = widget.category!.colorHex?.toUpperCase() ?? '';
      _selectedColorIndex = _availableColors.indexWhere(
        (c) => _hexFromColor(c) == existingColor,
      );
      if (_selectedColorIndex == -1) _selectedColorIndex = 0;

      final currentIconList =
          widget.isIncome ? kIncomeIcons : kExpenseIcons;

      _selectedIconIndex = currentIconList.indexWhere(
        (icon) => icon.key == widget.category!.iconName,
      );
      if (_selectedIconIndex == -1) _selectedIconIndex = 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mainColor = widget.isIncome ? Colors.blue : Colors.red;
    final currentIconList =
        widget.isIncome ? kIncomeIcons : kExpenseIcons;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        right: 20,
        left: 20,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          topLeft: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.category == null ? 'เพิ่ม' : 'แก้ไข'}หมวดหมู่${widget.isIncome ? "รายรับ" : "รายจ่าย"}',
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            "ชื่อหมวดหมู่",
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _nameController,
            autofocus: true,
            style: GoogleFonts.prompt(fontSize: 16),
            decoration: InputDecoration(
              hintText: widget.isIncome
                  ? "เช่น เงินเดือน, โบนัส, ขายของ"
                  : "เช่น ค่าน้ำ, ค่าไฟ",
              hintStyle: GoogleFonts.prompt(
                color: Colors.grey.withOpacity(0.7),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: mainColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: mainColor, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            "เลือกสี",
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 60,
              crossAxisSpacing: 8,
              mainAxisSpacing: 16,
            ),
            itemCount: _availableColors.length,
            itemBuilder: (context, index) {
              final color = _availableColors[index];
              final isSelected = index == _selectedColorIndex;

              return Center(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),
          Text(
            "เลือกไอคอน",
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 72,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: currentIconList.length,
            itemBuilder: (context, index) {
              final option = currentIconList[index];
              final isSelected = index == _selectedIconIndex;

              return InkWell(
                onTap: () => setState(() => _selectedIconIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? mainColor.withOpacity(0.12)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? mainColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected ? mainColor : Colors.grey.shade500,
                    size: 26,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;

                final color = _availableColors[_selectedColorIndex];
                final iconName = currentIconList[_selectedIconIndex].key;

                Navigator.pop(
                  context,
                  CategoryFormResult(
                    name: name,
                    color: color,
                    iconName: iconName,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'บันทึก',
                style: GoogleFonts.prompt(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}