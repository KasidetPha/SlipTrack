import 'package:flutter/material.dart';
import 'package:frontend/pages/category_seeall_page.dart';
import 'package:frontend/widgets/home_page_widgets/expense_card.dart';
import 'package:frontend/widgets/home_page_widgets/home_header.dart';
import 'package:frontend/widgets/home_page_widgets/income_card.dart';
import 'package:frontend/widgets/home_page_widgets/items_recent.dart';
import 'package:frontend/widgets/home_page_widgets/month_year_dropdown.dart';
import 'package:frontend/widgets/home_page_widgets/most_category.dart';
import 'package:frontend/widgets/home_page_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// import 'package:frontend/models/items_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  Key itemsRecentKey = UniqueKey(); // ใช้เพื่อ force rebuild ItemsRecent
  bool _hasCategoryData = false;

  void onMonthYearChanged(int month, int year) {
    setState(() {
      selectedMonth = month;
      selectedYear = year;
      itemsRecentKey = UniqueKey(); // สร้าง key ใหม่เพื่อ force rebuild
      _hasCategoryData = false;
    });
  }

  String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // padding: const EdgeInsets.only(bottom: 76),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              // height: 280,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 37, 98, 235),
                    Color.fromARGB(144, 76, 52, 234)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Column(
                children: [
                  HomeHeader(),
                  SizedBox(height: 24),
                  MonthYearDropdown(
                    onMonthYearChanged: onMonthYearChanged,
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: IncomeCard(
                          selectedMonth: selectedMonth,
                          selectedYear: selectedYear,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ExpenseCard(                          
                          selectedMonth: selectedMonth,
                          selectedYear: selectedYear,
                        )
                      )
                    ],
                  ),
                  SizedBox(height: 16),
                  SummaryCard(
                    selectedMonth: selectedMonth, 
                    selectedYear: selectedYear,
                    title: "Total Expenses for ${getMonthName(selectedMonth)} $selectedYear",
                    // isCategoryMode: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.fromLTRB(24,0,24,24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Spending by Categories", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold )),
                  if (_hasCategoryData) 
                    TextButton.icon(
                      style: TextButton.styleFrom(iconAlignment: IconAlignment.end),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (ctx) => CategorySeeall(
                            selectedMonth: selectedMonth,
                            selectedYear: selectedYear
                          )
                        ));
                      },
                      label: Text("See All", style: GoogleFonts.prompt(color: Colors.grey,),),
                      icon: Icon(Icons.chevron_right_outlined, color: Colors.grey, size: 18,),
                    )
                ],
              ),
            ),
            MostCategory(
              selectedMonth: selectedMonth, 
              selectedYear: selectedYear,
              onHasDataChanged: (hasData) {
                setState(() => _hasCategoryData = hasData);
              },
            ),

            // const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.fromLTRB(24,24,24,24),
              child: Text("Recent Transactions", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold ),),
            ),

            // const SizedBox(height: 24),

            ItemsRecent(
              key: itemsRecentKey,
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
            )
          ],
        ),
      ),
      
    );
  }
}
