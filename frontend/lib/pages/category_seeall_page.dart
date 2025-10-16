import 'package:flutter/material.dart';
import 'package:frontend/models/category_summary.dart';
import 'package:frontend/pages/category_detail_page.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/bottom_nav_page.dart';
import 'package:frontend/widgets/home_page_widgets/month_year_dropdown.dart';
import 'package:frontend/widgets/home_page_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CategorySeeall extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  const CategorySeeall({
    super.key,
    required this.selectedMonth,
    required this.selectedYear

  });

  @override
  State<CategorySeeall> createState() => _CategorySeeallState();
}

class _CategorySeeallState extends State<CategorySeeall> {
  int? month;
  int? year;
  final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  late Future<List<CategorySummary>> _future;

  final List<String> sortOptions = [
    "Sort by Amount", "Sort by Percentage", "Sort by Transactions", "Sort by Name"
  ];

  String? selectedSortOption;

  @override
  void initState() {
    super.initState();
    month = widget.selectedMonth;
    year = widget.selectedYear;
    _future = ReceiptService().fetchCategorySummary(month: month!, year: year!);
  }

  void onMonthYearChange(int newMonth, int newYear) {
    setState(() {
      month = newMonth;
      year = newYear;
      _future = ReceiptService().fetchCategorySummary(month: newMonth, year: newYear);
    });

    print("Category_seeall -> newMonth: $newMonth, newYear: $newYear");

    // fetch ข้อมูลตามที่เลือก month/year
  }
  
  String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }

  void _openCategoryDetail(CategorySummary c) {
    print('${c.categoryId}, ${c.categoryName}, ${month}, ${year}');
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (ctx) => CategoryDetailPage(
          categoryId: c.categoryId,
          categoryName: c.categoryName,
          month: month!,
          year: year!
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 2,
                    offset: const Offset(0,1)
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
                            // Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BottomNavPage()));
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
                            style: GoogleFonts.prompt(fontSize: 26, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white),
                          )
                        )
                      ),
                      SizedBox(width: 48, height: 48,)
                    ],
                  ),
                  SizedBox(height: 24),
                  MonthYearDropdown(
                    initialMonth: month,
                    initialYear: year,
                    onMonthYearChanged: (newMonth, newYear) {
                      onMonthYearChange(newMonth, newYear);
                      // setState(() {
                      //   month = newMonth;
                      //   year = newYear;
                        
                      //   _future = ReceiptService().fetchCategorySummary(month: newMonth, year: newYear);
                      // });
                    print("category_seeall -> newMonth: $newMonth, newYear: $newYear");
                    },
                  ),
                  SizedBox(height: 24,), 
                  
                  SummaryCard(
                    selectedMonth: month!, 
                    selectedYear: year!,
                    title: "Total Category for ${getMonthName(month!)} $year",
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
                  // final list = snapshot.data ?? [];


                  // if (list.isEmpty) {
                  //   return const Center(child: Text('ไม่มีข้อมูล'),);
                  // }

                  // final categories = snapshot.data ?? [];
                  final categories = List<CategorySummary>.from(snapshot.data ?? []);

                  if (categories.isEmpty) {
                    return const Center(child: Text('ไม่มีข้อมูล'));
                  }

                  _sortCategories(categories, selectedSortOption);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text("Categories", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 50, 50, 50)),),
                          const SizedBox(width: 96,),
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedSortOption,
                                dropdownColor: Colors.white,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color.fromARGB(255, 90, 70, 230),
                                  size: 24,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Sort Categories",
                                  hintStyle: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[500]),
                                  labelText: null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)
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
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24,),

                      // Column map -> widget list
                      ...categories.map((c) {
                        final progress = (c.percent / 100).clamp(0, 1).toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
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
                                              iconForCategoryId(c.categoryId),
                                              color: colorForCategoryId(c.categoryId),
                                            ),
                                          ),
                                          SizedBox(width: 12,),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.categoryName, style: GoogleFonts.prompt(),),
                                              SizedBox(height: 4,),
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
                                SizedBox(height: 12,),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value:  progress,
                                    minHeight: 10,
                                    // backgroundColor: Colors.grey[200],
                                    backgroundColor: colorForCategoryId(c.categoryId).withOpacity(0.2),
                                    color: colorForCategoryId(c.categoryId)
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
    );
  }
}