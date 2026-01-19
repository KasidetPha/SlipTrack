import 'package:flutter/material.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/pages/category_see_all_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/Edit_Receipt_Item_Sheet.dart';
import 'package:frontend/widgets/filter_month_year.dart';
import 'package:frontend/widgets/home_page_widgets/items_recent.dart';
import 'package:frontend/widgets/month_year_dropdown.dart';
import 'package:frontend/widgets/home_page_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryDetailPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int month;
  final int year;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.month,
    required this.year,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late int month;
  late int year;
  
  // ใช้ key เพื่อ force reload เวลา pull-to-refresh
  Key _itemsKey = UniqueKey();

  // future สำหรับยอดรวมของหมวดนี้
  late Future<double> _futureCategoryTotal;

  @override
  void initState() {
    super.initState();
    month = widget.month;
    year = widget.year;
    _futureCategoryTotal = _loadCategoryTotal(month, year);
  }

  // final NumberFormat _currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  Future<double> _loadCategoryTotal(int m, int y) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      return 0.0;
    }

    ApiClient().setToken(token);

    final items = await ReceiptService().fetchReceiptItemsByCategory(categoryId: widget.categoryId, month: m, year: y);

    return items.fold<double>(
      0.0,
      (sum, item) => sum + item.total_price
    );
  }

  void onMonthYearChange(int newMonth, int newYear) {
    setState(() {
      month = newMonth;
      year = newYear;
      _itemsKey = UniqueKey();
      _futureCategoryTotal = _loadCategoryTotal(newMonth, newYear);
    });
  }

  String _monthName(int m) =>
    DateFormat.MMMM('en_US').format(DateTime(2000,m));

  @override
  Widget build(BuildContext context) {
    final safeMonth = month;
    final safeYear = year;

    Widget header = SafeArea(
      child:  Container(
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
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      // Navigator.push(context, MaterialPageRoute(builder: (ctx) => CategorySeeall(selectedMonth: safeMonth, selectedYear: safeYear)));
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24,),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text("${widget.categoryName} Details",
                      textAlign: TextAlign.center, 
                      style: GoogleFonts.prompt(fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white),
                    )
                  )
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                )
              ],
            ),
            SizedBox(height: 24),
            // MonthYearDropdown(
            //   initialMonth: safeMonth,
            //   initialYear: safeYear,
            //   onMonthYearChanged: onMonthYearChange
            // ),
            FilterMonthYear(
              initialMonth: safeMonth,
              initialYear: safeYear,
              onMonthYearChanged: onMonthYearChange,
            ),
            SizedBox(height: 12,), 
            // SummaryCard(
            //   selectedMonth: safeMonth, 
            //   selectedYear: safeYear,
            //   title: "Total Category for ${_monthName(safeMonth)} $safeYear",
            // )
            FutureBuilder<double>(
              future: _futureCategoryTotal, 
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0.0;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                return SummaryCard(
                  selectedMonth: safeMonth, 
                  selectedYear: safeYear,
                  title: "Total Category for ${_monthName(safeMonth)} $safeYear",
                  isCategoryMode: true,
                  totalOverride: total,
                );
              }
            )
          ],
        ),
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _itemsKey = UniqueKey();
          });
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              // const SizedBox(height:  12,),
              ItemsRecent(
                key: _itemsKey, 
                selectedMonth: safeMonth, 
                selectedYear: safeYear, 
                categoryId: 
                widget.categoryId,
              )
            ],
          ),
        )
      )
    );
  }
}