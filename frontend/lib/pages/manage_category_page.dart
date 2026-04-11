import 'package:flutter/material.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageCategoryPage extends StatefulWidget {
  const ManageCategoryPage({super.key});

  @override
  State<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends State<ManageCategoryPage> {

  List<Map<String, dynamic>> incomeCategories = [];
  List<Map<String, dynamic>> expenseCategories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    try {
      final categories = await ReceiptService().getCategoryMaster();
      setState(() {
        incomeCategories = categories.where((c) => c['entry_type'] == 'income').toList();
        expenseCategories = categories.where((c) => c['entry_type'] == 'expense').toList();

        isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: Text('จัดการหมวดหมู่', style: GoogleFonts.prompt(fontWeight: FontWeight.w600),),
          bottom: TabBar(
            labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.prompt(),
            tabs: const [
              Tab(text: 'รายรับ',),
              Tab(text: 'รายจ่าย')
            ],
          ),
        ),
        body: isLoading 
         ? const Center(child: CircularProgressIndicator())
          : TabBarView(
            children: [
              _buildCategoryGrid(incomeCategories, isIncome: true),
              _buildCategoryGrid(expenseCategories, isIncome: false)
            ]
          ),
      )
    );
  }

  Widget _buildCategoryGrid(List<Map<String, dynamic>> categories, {required bool isIncome}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9
      ),
      itemCount: categories.length + 1,
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return _AddCategoryCard(
            onTap: () async {
              final result = await _showAddCategoryForm(context, isIncome);

              if (result != null) {
                String name = result['name'];
                Color color = result['color'];

                String hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                String entryType = isIncome ? 'income' : 'expense';

                bool success = await ReceiptService().addNewCategory(
                  categoryName: name, 
                  entryType: entryType, 
                  iconName: 'category', 
                  colorHex: hexColor
                );

                if (success) {
                  _loadCategories();
                }
              }
              print('กดเพิ่มหมวดหมู่');
            },
          );
        }

        final category = categories[index];
        return _CategoryItemCard(
          category: category,
          onTap: () {
            print('แก้ไข ${category['category_name']}');
          },
          onLongPress: () {
            _showDeleteConfirmDialog(category['category_name'], index, categories);
          }
        );
      },
    );
  }

  void _showDeleteConfirmDialog(String category, int index, List<Map<String, dynamic>> listRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบหมวดหมู่', style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
        content: Text('คุณต้องการลบ "$category" ใช่หรือไม่', style: GoogleFonts.prompt(),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.blue[400]),)
          ),
          TextButton(
            onPressed: () {
              setState(() {
                listRef.removeAt(index);
              },);
              Navigator.pop(context);
            }, 
            child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.red),)
          )
        ],
      )
    );
  }

  Future<dynamic> _showAddCategoryForm(BuildContext context, bool isIncome) {
    return showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _AddCategoryForm(isIncome: isIncome);
      }
    );
  }
}

class _CategoryItemCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CategoryItemCard({
    required this.category,
    required this.onTap,
    required this.onLongPress
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final String title = category['category_name'] ?? 'ไม่มีชื่อ';
    final Color color = hexToColor(category['color_hex'] ?? '#7F8C8D');
    final IconData iconData = getIconData(category['icon_name'] ?? 'category');

    return Material(
      color: cs.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  color: color,
                ),
              ),
              const SizedBox(height: 8,),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCategoryCard({
    required this.onTap,
  });

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
            border: Border.all(color: Colors.blue.withOpacity(0.6), width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: const Icon(Icons.add_rounded, color: Colors.blue,),
              ),
              const SizedBox(height: 8,),
              Text('เพิ่มหมวดหมู่', style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue),)
            ],
          ),
        ),
      ),
    );
  }
}

const List<Color> _availableColors = [
  Colors.blue, Colors.green, Colors.red, Colors.orange, 
  Colors.purple, Colors.pink, Colors.teal, Colors.amber, 
  Colors.cyan,
];

class _AddCategoryForm extends StatefulWidget {
  final bool isIncome;
  const _AddCategoryForm({Key? key, required this.isIncome}) : super(key:key);

  @override
  State<_AddCategoryForm> createState() => __AddCategoryFormState();
}

class __AddCategoryFormState extends State<_AddCategoryForm> {
  final TextEditingController _nameController = TextEditingController();

  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;
    final mainColor = widget.isIncome ? Colors.blue : Colors.red;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        right: 16,
        left: 16
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          topLeft: Radius.circular(24)
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
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
                'เพิ่มหมวดหมู่${widget.isIncome ? "รายรับ" : "รายจ่าย"}', 
                style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.grey)
              )
            ],
          ),
          const SizedBox(height: 16,),

          Text(
            "ชื่อหมวดหมู่", 
            style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 8,),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: GoogleFonts.prompt(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'เช่น ค่าน้ำ ค่าไฟ',
              hintStyle: GoogleFonts.prompt(color: Colors.grey.withOpacity(0.7)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: mainColor.withOpacity(0.4), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: mainColor, width: 2.0))
            ),
          ),
          const SizedBox(height: 8,),
          Row(
            children: [
              ..._availableColors.map((color) {
                final int index = _availableColors.indexOf(color);
                final bool isSelected = index == _selectedColorIndex;

                return InkWell(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: cs.onSurface, width: 2.5) : Border.all(color: Colors.transparent)
                    ),
                  ),
                );
              }).toList()
            ],
          ),
          const SizedBox(height: 24,),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.grey)),
                )
              ),
              const SizedBox(width: 12,),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final String name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      final Color color = _availableColors[_selectedColorIndex];

                      Navigator.pop(context, {'name': name, 'color': color});
                    }
                  }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    child: Text('บันทึก', style: GoogleFonts.prompt(fontWeight: FontWeight.w700)
                  )
                )
              ),
            ],
          ),
          const SizedBox(height: 16,)
        ],
      ),
    );
  }
}

// ฟังก์ชันแปลง String Hex เป็น Color 
Color hexToColor(String hex) {
  String sanitizedHex = hex.replaceAll('#', '');
  if (sanitizedHex.length == 6) {
    sanitizedHex = 'FF$sanitizedHex';
  }
  return Color(int.parse(sanitizedHex, radix: 16));
}

// ฟังก์ชันจับคู่ชื่อที่ได้จาก DB มาเป็นไอคอน
IconData getIconData(String iconName) {
  switch (iconName) {
    case 'restaurant': return Icons.restaurant;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'receipt_long': return Icons.receipt_long;
    case 'directions_bus': return Icons.directions_bus;
    case 'payments': return Icons.payments;
    case 'work': return Icons.work;
    case 'card_giftcard': return Icons.card_giftcard;
    case 'sell': return Icons.sell;
    case 'category':
    default:
      return Icons.category;
  }
}