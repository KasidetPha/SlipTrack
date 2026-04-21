import 'package:flutter/material.dart';
import 'package:frontend/models/category_master.dart';
import 'package:frontend/services/category_service.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/utils/transaction_event.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageCategoryPage extends StatefulWidget {
  const ManageCategoryPage({super.key});

  @override
  State<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends State<ManageCategoryPage> {

  List<CategoryMaster> incomeCategories = [];
  List<CategoryMaster> expenseCategories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    TransactionEvent.refresher.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() async {
    print('Global Refresh Triggered!');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    CategoryService().clearCache(token: token);

    if (mounted) {
      await _loadCategories();
    }
  }

  @override
  void dispose() {
    TransactionEvent.refresher.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Token not found');
      }

      final categories = await CategoryService().fetchCategories(token: token);
      setState(() {
        incomeCategories = categories.where((c) => c.entryType.toLowerCase() == 'income').toList();
        expenseCategories = categories.where((c) => c.entryType.toLowerCase() == 'expense').toList();

        isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCategoriesSilently({bool forceRefresh = false}) async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('token');

      if (token == null) return;

      final categories = await CategoryService().fetchCategories(token: token, forceRefresh: forceRefresh);
      
      if (mounted) {
        setState(() {
          incomeCategories = categories.where((c) => c.entryType.toLowerCase() == 'income').toList();
          expenseCategories = categories.where((c) => c.entryType.toLowerCase() == 'expense').toList();
        });
      }
    } catch (e) {
      print('slint load error');
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

  Widget _buildCategoryGrid(List<CategoryMaster> categories, {required bool isIncome}) {
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
                String iconName = result['icon'];

                String hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                String entryType = isIncome ? 'income' : 'expense';

                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');

                if (token == null || token.isEmpty) {
                  throw Exception('Token not found');
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังบันทึกข้อมูล...'), duration: Duration(seconds: 1)),
                );

                bool success = await CategoryService().addNewCategory(
                  categoryName: name, 
                  entryType: entryType, 
                  iconName: iconName, 
                  colorHex: hexColor,
                  token: token,
                );

                if (success) {
                  final newCategory = CategoryMaster(
                    categoryId: 0, // temp id
                    categoryName: name,
                    entryType: entryType,
                    iconName: iconName,
                    colorHex: hexColor,
                  );

                  setState(() {
                    if (entryType == 'income') {
                      incomeCategories = [...incomeCategories, newCategory];
                    } else {
                      expenseCategories = [...expenseCategories, newCategory];
                    }
                  });

                  // TransactionEvent.triggerRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เพิ่มหมวดหมู่สำเร็จ'), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  setState(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('เกิดข้อผิดพลาดในการเพิ่มหมวดหมู่'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
              print('กดเพิ่มหมวดหมู่');
            },
          );
        }

        final category = categories[index];
        return _CategoryItemCard(
          category: category,
          onTap: () async {
            final result = await _showAddCategoryForm(context, isIncome, category: category);

            if (result != null) {
              String name = result['name'];
              Color color = result['color'];
              String iconName = result['icon'];

              String hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              String entryType = isIncome ? 'income' : 'expense';

              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');

              if (token == null || token.isEmpty) throw Exception('Token not found');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังแก้ไขข้อมูล...'), duration: Duration(seconds: 1),), 
              );

              final oldIncome = List<CategoryMaster>.from(incomeCategories);
              final oldExpense = List<CategoryMaster>.from(expenseCategories);

              setState(() {
                final updated = CategoryMaster(
                  categoryId: category.categoryId,
                  categoryName: name,
                  entryType: entryType,
                  iconName: iconName,
                  colorHex: hexColor,
                );

                if (entryType == 'income') {
                  incomeCategories = incomeCategories.map((c) {
                    return c.categoryId == category.categoryId ? updated : c;
                  }).toList();
                } else {
                  expenseCategories = expenseCategories.map((c) {
                    return c.categoryId == category.categoryId ? updated : c;
                  }).toList();
                }
              });

              final success = await CategoryService().updateCategory(
                categoryId: category.categoryId, 
                categoryName: name, 
                entryType: entryType, 
                iconName: iconName, 
                colorHex: hexColor,
                token: token
              );

              if (!success) {
                setState(() {
                  incomeCategories = oldIncome;
                  expenseCategories = oldExpense;
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('แก้ไขไม่สำเร็จ'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } else {
                _loadCategoriesSilently(forceRefresh: true);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('แก้ไขหมวดหมู่สำเร็จ'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            }
            print('แก้ไข ${category.categoryName}');
          },
          onLongPress: () {
            _showDeleteConfirmDialog(category, index, categories);
          }
        );
      },
    );
  }

  void _showDeleteConfirmDialog(CategoryMaster category, int index, List<CategoryMaster> listRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบหมวดหมู่', style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
        content: Text('คุณต้องการลบ "${category.categoryName}" ใช่หรือไม่', style: GoogleFonts.prompt(),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.blue[400]),)
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');

              if (token == null || token.isEmpty) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังลบข้อมูล....'), duration: Duration(seconds: 1),)
              );

              bool success = await CategoryService().deleteCategory(categoryId: category.categoryId, token: token);

              if (success) {
                setState(() {
                  incomeCategories.removeWhere((c) => c.categoryId == category.categoryId);
                  expenseCategories.removeWhere((c) => c.categoryId == category.categoryId);
                });
                // await _loadCategoriesSilently(forceRefresh: true);

                // TransactionEvent.triggerRefresh();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ลบหมวดหมู่สำเร็จ'), backgroundColor: Colors.green,)
                  );
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ'), backgroundColor: Colors.redAccent,)
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ลบไม่สำเร็จ (อาจมีรายการบัญชีที่ใช้หมวดหมู่นี้อยู่)'), 
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }, 
            child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.red),)
          )
        ],
      )
    );
  }

  Future<dynamic> _showAddCategoryForm(BuildContext context, bool isIncome, {CategoryMaster? category}) {
    return showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _AddCategoryForm(isIncome: isIncome, category: category,);
      }
    );
  }
}

class _CategoryItemCard extends StatelessWidget {
  final CategoryMaster category;
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

    final String title = category.categoryName;
    final Color color = colorFromHex(category.colorHex ?? '#7F8C8D');
    final IconData iconData = getIconFromKey(category.iconName ?? 'category');

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
  final CategoryMaster? category;
  const _AddCategoryForm({Key? key, required this.isIncome, this.category}) : super(key:key);

  @override
  State<_AddCategoryForm> createState() => __AddCategoryFormState();
}

class __AddCategoryFormState extends State<_AddCategoryForm> {
  final TextEditingController _nameController = TextEditingController();

  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.categoryName;

      String existingColor = widget.category!.colorHex?.toUpperCase() ?? '';
      _selectedColorIndex = _availableColors.indexWhere((c) =>
        '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}' == existingColor
      );
      if (_selectedColorIndex == -1) _selectedColorIndex = 0;

      final currentIconList = widget.isIncome ? kIncomeIcons : kExpenseIcons;
      _selectedIconIndex = currentIconList.indexWhere((icon) => icon.key == widget.category!.iconName);
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

    final screenWidth = MediaQuery.of(context).size.width;
    final mainColor = widget.isIncome ? Colors.blue : Colors.red;

    final List<CategoryIconOption> currentIconList = widget.isIncome ? kIncomeIcons : kExpenseIcons;

    

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        right: 20,
        left: 20
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          topLeft: Radius.circular(28)
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, -2))
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
              hintText: widget.isIncome ? "เช่น เงินเดือน, โบนัส, ขายของ" : "เช่น ค่าน้ำ, ค่าไฟ",
              hintStyle: GoogleFonts.prompt(color: Colors.grey.withOpacity(0.7)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: mainColor.withOpacity(0.4), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: mainColor, width: 2.0))
            ),
          ),
          const SizedBox(height: 8,),
          Text(
            "เลือกสี",
            style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)
          ),
          const SizedBox(height: 8,),
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
            itemBuilder: (content, index) {
              final color = _availableColors[index];
              final bool isSelected = index == _selectedColorIndex;
            
              return Center(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      // shape: BoxShape.circle,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                        : null,
                    ),
                  ),
              );
            }
          ),
          const SizedBox(height: 8,),
          Text(
            "เลือกไอคอน",
            style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)
          ),
          const SizedBox(height: 8,),
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
              final bool isSelected = index == _selectedIconIndex;
          
              return InkWell(
                onTap: () => setState(() => _selectedIconIndex = index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? mainColor.withOpacity(0.12) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: mainColor, width: 2) : Border.all(color: Colors.grey.shade300, width: 1.5)
                  ),
                  child: Icon(option.icon, color: isSelected ? mainColor : Colors.grey.shade500, size: 26,),
                ),
              );
            }
          ),
          const SizedBox(height: 24,),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  final String name = _nameController.text.trim();
                  if (name.isNotEmpty) {
                    final Color color = _availableColors[_selectedColorIndex];
                    final String iconName = currentIconList[_selectedIconIndex].key;
                    Navigator.pop(context, {'name': name, 'color': color, 'icon': iconName});
                  }
                }, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('บันทึก', style: GoogleFonts.prompt(fontWeight: FontWeight.w700)
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
