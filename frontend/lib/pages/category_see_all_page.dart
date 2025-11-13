import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:frontend/models/category_summary.dart';
import 'package:frontend/pages/category_detail_page.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/filter_month_year.dart';
import 'package:frontend/widgets/home_page_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CategorySeeAll extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  const CategorySeeAll({
    super.key,
    required this.selectedMonth,
    required this.selectedYear

  });

  @override
  State<CategorySeeAll> createState() => _CategorySeeAllState();
}

class _CategorySeeAllState extends State<CategorySeeAll> {
  late int month;
  late int year;

  bool _didPop = false;
  
  final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  late Future<List<CategorySummary>> _future;

  final List<String> sortOptions = [
    "Sort by Amount", "Sort by Percentage", "Sort by Transactions", "Sort by Name"
  ];

  String? selectedSortOption = "Sort by Amount";

  void _popWithResult() {
    if (_didPop) return;
    _didPop = true;
    
  }

  @override
  void initState() {
    super.initState();
    month = widget.selectedMonth;
    year = widget.selectedYear;
    _future = ReceiptService().fetchCategorySummary(month: month, year: year);
  }

  void onMonthYearChange(int newMonth, int newYear) {
    if (kDebugMode) {
      print("Category_seeall -> newMonth: $newMonth, newYear: $newYear");
    }

    setState(() {
      month = newMonth;
      year = newYear;
      _future = ReceiptService().fetchCategorySummary(month: newMonth, year: newYear);
    });
  }
  
  String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }

  void _openCategoryDetail(CategorySummary c) {
    if (kDebugMode) {
      print('${c.categoryId}, ${c.categoryName}, ${month}, ${year}');
    }
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (ctx) => CategoryDetailPage(
          categoryId: c.categoryId,
          categoryName: c.categoryName,
          month: month,
          year: year
        )
      )
    );
  }

  void _sortCategories(
    List<CategorySummary> categories, String? sortOption) {
      switch (sortOption) {
        case "Sort by Amount":
          categories.sort((a, b) => b.total.compareTo(a.total));
          break;
        case "Sort by Percentage":
          categories.sort((a,b) => b.percent.compareTo(a.percent));
          break;
        case "Sort by Transactions":
          categories.sort((a,b) => b.itemCount.compareTo(a.itemCount));
          break;
        case "Sort by Name":
          categories.sort((a,b) => 
            a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase()));
          break;
        default:
          break;
      }
    }

  @override
  Widget build(BuildContext context) {

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                      onMonthYearChanged: onMonthYearChange
                    ),
                    const SizedBox(height: 12,), 
                    SummaryCard(
                      selectedMonth: month, 
                      selectedYear: year,
                      title: "Total Category for ${getMonthName(month)} $year",
                      isCategoryMode: true,
                    )
                  ],
                ),
              ),
              // SizedBox(height: 24,),
              Padding(
                padding: const EdgeInsets.all(24),
                child: FutureBuilder<List<CategorySummary>>(
                  future: _future, 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),);
                    }

                    final categories = List<CategorySummary>.from(snapshot.data ?? []);
        
                    if (categories.isEmpty) {
                      return const Center(child: Text('ไม่มีข้อมูล'));
                    }
        
                    _sortCategories(categories, selectedSortOption);
        
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text("Categories", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 50, 50, 50)),)),
                            // const SizedBox(width: 96,),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: DropdownButtonFormField<String>(
                                value: selectedSortOption,
                                isDense: true,
                                dropdownColor: Colors.white,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  // color: Color.fromARGB(255, 90, 70, 230),
                                  size: 20,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Sort Categories",
                                  hintStyle: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelText: null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.25)
                                    )
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.25)
                                    )
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                                ),
                                items: sortOptions.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option, style: GoogleFonts.prompt(),),
                                  );
                                }).toList(), 
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedSortOption = newValue;
                                  });
                                }
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24,),
        
                        // Column map -> widget list
                        ...categories.map((c) {
                          final catColor = colorForCategoryId(c.categoryId);
                          final catIcon = iconForCategoryId(c.categoryId);
                          final progress = (c.percent / 100).clamp(0.0, 1.0).toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openCategoryDetail(c),
                                // print("go page detail receitp category");
                              child: Container(
                              // margin: const EdgeInsets.only(bottom: 12),
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
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: colorForCategoryId(c.categoryId).withOpacity(0.2),
                                              child: Icon(
                                                catIcon,
                                                color: catColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12,),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(c.categoryName, style: GoogleFonts.prompt(),),
                                                const SizedBox(height: 4,),
                                                if (c.itemCount > 1)
                                                  Text("${c.itemCount} transactions", style: GoogleFonts.prompt(color: Colors.grey[600]),)
                                                else
                                                  Text("${c.itemCount} transaction", style: GoogleFonts.prompt(color: Colors.grey[600]),)
                                              ],
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
                  }
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}