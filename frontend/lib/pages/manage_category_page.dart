import 'package:flutter/material.dart';
import 'package:frontend/models/category_master.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/category_form_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/category_provider.dart';

class ManageCategoryPage extends ConsumerStatefulWidget {
  const ManageCategoryPage({super.key});

  @override
  ConsumerState<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends ConsumerState<ManageCategoryPage> {

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);

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
        body: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'โหลดหมวดหมู่ไม่สำเร็จ',
              style: GoogleFonts.prompt(),
            ),
          ),
          data: (_) => TabBarView(
            children: [
              _buildCategoryGrid(incomeCategories, isIncome: true),
              _buildCategoryGrid(expenseCategories, isIncome: false),
            ],
          ),
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
              final result = await showCategoryFormBottomSheet(
                context: context,
                isIncome: isIncome,
              );

              if (result != null) {
                final String name = result.name;
                final Color color = result.color;
                final String iconName = result.iconName;

                String hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                String entryType = isIncome ? 'income' : 'expense';

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังบันทึกข้อมูล...'), duration: Duration(seconds: 1)),
                );

                final success = await ref.read(categoryControllerProvider).addCategory(
                  categoryName: name,
                  entryType: entryType,
                  iconName: iconName,
                  colorHex: hexColor,
                );

                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เพิ่มหมวดหมู่สำเร็จ'), backgroundColor: Colors.green),
                    );
                  }
                } else {
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
            final result = await showCategoryFormBottomSheet(
              context: context,
              isIncome: isIncome,
              category: category,
            );

            if (result != null) {
              final String name = result.name;
              final Color color = result.color;
              final String iconName = result.iconName;

              String hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              String entryType = isIncome ? 'income' : 'expense';

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังแก้ไขข้อมูล...'), duration: Duration(seconds: 1),), 
              );

              final success = await ref.read(categoryControllerProvider).updateCategory(
                categoryId: category.categoryId, 
                categoryName: name, 
                entryType: entryType, 
                iconName: iconName, 
                colorHex: hexColor,
              );

              if (!success) {
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

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังลบข้อมูล....'), duration: Duration(seconds: 1),)
              );

              final success = await ref.read(categoryControllerProvider).deleteCategory(
                categoryId: category.categoryId,
              );

              if (success) {
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

