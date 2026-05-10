import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/filter_month_year.dart';
import 'package:frontend/widgets/home_page_widgets/items_recent.dart';
import 'package:frontend/widgets/home_page_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:frontend/providers/transaction_provider.dart';

class CategoryDetailPage extends ConsumerStatefulWidget {
  final int categoryId;
  final String categoryName;
  final int month;
  final int year;
  final String entryType;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.month,
    required this.year,
    required this.entryType,
  });

  @override
  ConsumerState<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends ConsumerState<CategoryDetailPage> {
  late int month;
  late int year;
  
  @override
  void initState() {
    super.initState();
    month = widget.month;
    year = widget.year;
  }

  void onMonthYearChange(int newMonth, int newYear) {
    setState(() {
      month = newMonth;
      year = newYear;
    });

    ref.invalidate(categoryDetailTotalProvider);
    ref.invalidate(transactionsProvider);
  }

  String _monthName(int m) =>
    DateFormat.MMMM('en_US').format(DateTime(2000,m));

  @override
  Widget build(BuildContext context) {
    debugPrint("DETAIL PAGE entryType: ${widget.entryType}");
    final safeMonth = month;
    final safeYear = year;

    final totalAsync = ref.watch(
      categoryDetailTotalProvider((
        categoryId: widget.categoryId,
        month: safeMonth,
        year: safeYear,
        entryType: widget.entryType,
      )),
    );

    Widget header = Container(
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
                    Navigator.pop(context, true);
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
    
          FilterMonthYear(
            initialMonth: safeMonth,
            initialYear: safeYear,
            onMonthYearChanged: onMonthYearChange,
            color: Colors.white,
          ),
          SizedBox(height: 12,), 
          totalAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (error, stack) => Text(
              'โหลดข้อมูลไม่สำเร็จ',
              style: GoogleFonts.prompt(color: Colors.white),
            ),
            data: (total) => SummaryCard(
              selectedMonth: safeMonth,
              selectedYear: safeYear,
              title: "Total Category for ${_monthName(safeMonth)} $safeYear",
              isCategoryMode: true,
              totalOverride: total,
            ),
          )
        ],
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryDetailTotalProvider);
          ref.invalidate(transactionsProvider);

          await ref.read(
            categoryDetailTotalProvider((
              categoryId: widget.categoryId,
              month: month,
              year: year,
              entryType: widget.entryType,
            )).future,
          );
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height:  12,),
              ItemsRecent(
                selectedMonth: safeMonth, 
                selectedYear: safeYear, 
                categoryId: widget.categoryId,
                entryType: widget.entryType,
              )
            ],
          ),
        )
      )
    );
  }
}