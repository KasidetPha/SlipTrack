import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/category_summary.dart';
import 'package:frontend/pages/category_detail_page.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/filter_month_year.dart';
import 'package:frontend/widgets/home_page_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CategorySeeAll extends ConsumerStatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  const CategorySeeAll({
    super.key,
    required this.selectedMonth,
    required this.selectedYear

  });

  @override
  ConsumerState<CategorySeeAll> createState() => _CategorySeeAllState();
}

class _CategorySeeAllState extends ConsumerState<CategorySeeAll> {
  late int month;
  late int year;

  final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  final List<String> typeOptions = [
    "รายจ่าย",
    "รายรับ",
  ];

String selectedTypeOption = "รายจ่าย";

  @override
  void initState() {
    super.initState();
    month = widget.selectedMonth;
    year = widget.selectedYear;
  }

  void onMonthYearChange(int newMonth, int newYear) {
    if (kDebugMode) {
      print("Category_seeall -> newMonth: $newMonth, newYear: $newYear");
    }

    setState(() {
      month = newMonth;
      year = newYear;
    });
  }
  
  String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }

  Future<void> _openCategoryDetail(CategorySummary c) async {
    final entryType = selectedTypeOption == "รายรับ" ? "income" : "expense";

    debugPrint("OPEN DETAIL entryType: $entryType category=${c.categoryName}");

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CategoryDetailPage(
          categoryId: c.categoryId,
          categoryName: c.categoryName,
          month: month,
          year: year,
          entryType: entryType,
        ),
      ),
    );

    if (updated == true) {
      ref.invalidate(categorySummaryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {

    final cs = Theme.of(context).colorScheme;
    final entryType = selectedTypeOption == "รายรับ" ? "income" : "expense";

    final categorySummaryAsync = ref.watch(categorySummaryProvider((
      month: month,
      year: year,
      entryType: entryType,
    )));

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 80, 70, 229),
                    Color.fromARGB(255, 146, 52, 234)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0,2)
                  )
                ],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30)
                )
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: InkWell(
                          onTap: () {
                            // Navigator.maybePop(context);
                            Navigator.pop(context, {
                              "month": month,
                              "year": year
                            });
                            // Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BottomNavPage()));
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24,),
                          )
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text("Spending Categories",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(fontSize: 23, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white),
                          )
                        )
                      ),
                      const SizedBox(width: 48, height: 48,)
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilterMonthYear(
                    initialMonth: month,
                    initialYear: year,
                    onMonthYearChanged: onMonthYearChange,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12,),
                  categorySummaryAsync.when(
                    loading: () => const SizedBox(
                      height: 150,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    error: (err, stack) => SizedBox(
                      height: 150,
                      child: Center(
                        child: Text(
                          "Error loading categories",
                          style: GoogleFonts.prompt(color: Colors.white),
                        ),
                      ),
                    ),
                    data: (categories) {
                      if (categories.isEmpty) {
                        return SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              'No categories',
                              style: GoogleFonts.prompt(color: Colors.white),
                            ),
                          ),
                        );
                      }
      
                      final double totalCategoryAmount = categories.fold<double>(
                        0.0,
                        (sum, c) => sum + c.total,
                      );
      
                      return SummaryCard(
                        selectedMonth: month,
                        selectedYear: year,
                        title: "Total Category for ${getMonthName(month)} $year",
                        isCategoryMode: true,
                        totalOverride: totalCategoryAmount,
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: categorySummaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('เกิดข้อผิดพลาด: $err'),
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text('ไม่มีข้อมูล'));
                  }

                  final sortedCategories = List<CategorySummary>.from(data);
                  sortedCategories.sort((a, b) => b.total.compareTo(a.total));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          children: [
                            Expanded(
                            child: Text(
                            selectedTypeOption == "รายรับ" ? "หมวดหมู่รายรับ" : "หมวดหมู่รายจ่าย",style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 50, 50, 50)),)),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _TypeSegmentButton(
                                    label: 'รายจ่าย',
                                    selected: selectedTypeOption == 'รายจ่าย',
                                    color: Colors.redAccent,
                                    onTap: () {
                                      setState(() {
                                        selectedTypeOption = 'รายจ่าย';
                                      });
                                    },
                                  ),
                                  _TypeSegmentButton(
                                    label: 'รายรับ',
                                    selected: selectedTypeOption == 'รายรับ',
                                    color: Colors.green,
                                    onTap: () {
                                      setState(() {
                                        selectedTypeOption = 'รายรับ';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24,),
                                      
                        // Column map -> widget list
                        ...sortedCategories.map((c) {
                          if (kDebugMode) {
                            debugPrint(
                              'CategorySeeAll: ${c.categoryName} icon=${c.iconName} color=${c.colorHex}',
                            );
                          }
                          final catColor = (c.colorHex != null && c.colorHex!.isNotEmpty)
                            ? colorFromHex(c.colorHex!)
                            : const Color.fromARGB(255, 80, 70, 229);
                        
                          final catIcon = (c.iconName != null && c.iconName!.isNotEmpty)
                            ? getIconFromKey(c.iconName!)
                            : Icons.category_rounded;
                          final progress = (c.percent / 100).clamp(0.0, 1.0).toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openCategoryDetail(c),
                              child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:  BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1.5,
                              
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2)
                                  )
                                ]
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: catColor.withOpacity(0.2),
                                              child: Icon(catIcon, color: catColor),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c.categoryName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.prompt(),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    c.itemCount > 1
                                                        ? "${c.itemCount} transactions"
                                                        : "${c.itemCount} transaction",
                                                    style: GoogleFonts.prompt(color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(currencyTh.format(c.total), style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),),
                                          Text("${c.percent.toStringAsFixed(2)}%", style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey[600]),),
                                        ],
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value:  progress,
                                      minHeight: 10,
                                      backgroundColor: catColor.withOpacity(0.2),
                                      color: catColor
                                    ),
                                  )
                                ],
                              ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeSegmentButton extends StatelessWidget {
  const _TypeSegmentButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selected ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.prompt(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}