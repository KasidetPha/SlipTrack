import 'package:flutter/material.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/pages/category_seeall_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/Edit_Receipt_Item_Sheet.dart';
import 'package:frontend/widgets/home_page_widgets/month_year_dropdown.dart';
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
  late Future<List<ReceiptItem>> _futureItems;
  int? month;
  int? year;

  final NumberFormat _currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  @override
  void initState() {
    super.initState();
    month = widget.month;
    year = widget.year;
    _futureItems = _load();
  }

  void onMonthYearChange(int newMonth, int newYear) {
    setState(() {
      month = newMonth;
      year = newYear;
      _futureItems = _load();
    });
  }

  // String _monthName(int m) =>
  //   DateFormat.MMMM('th_TH').format(DateTime(2000,m));

  Future<void> _logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiClient().clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (ctx) => const LoginPage()), 
      (route) => false
    );
  }

  Future<List<ReceiptItem>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      await _logoutAndRedirect();
      return [];
    }

    ApiClient().setToken(token);

    try {
      final items = await ReceiptService().fetchReceiptItemsByCategory(
        categoryId: widget.categoryId, 
        month: month, 
        year: year
      );
      return items;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _logoutAndRedirect();
        return [];
      }
      rethrow;
    }
  }

  Future<void> _openEditModal(ReceiptItem item) async {
    final bool? updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: EditReceiptItemSheet(item: item),
      )
    );

    if (!mounted) return;
    if (updated == true) {
      setState(() {
        _futureItems = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved changes'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeMonth = month ?? widget.month;
    final safeYear = year ?? widget.year;

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
            MonthYearDropdown(
              initialMonth: safeMonth,
              initialYear: safeYear,
              onMonthYearChanged: onMonthYearChange
            ),
            SizedBox(height: 24,), 
            SummaryCard(
              selectedMonth: safeMonth, 
              selectedYear: safeYear,
              title: "Total Category for $safeMonth $safeYear",
            )
          ],
        ),
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureItems = _load();
          });
          await _futureItems;
        },
        child: FutureBuilder<List<ReceiptItem>>(
          future: _futureItems, 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    header,
                    const SizedBox(height: 24,),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator(),),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    header,
                    const SizedBox(height: 24,),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _ErrorCard(message: "Error: ${snapshot.error}"),
                    )
                  ],
                ),
              );
            }
            
            final items = snapshot.data ?? [];
            final hasData = items.isNotEmpty;

            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 24,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: hasData
                      ? ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12,),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          print("${widget.categoryId}");
                          print("${item.category_id}");
                          return _TransactionRow(
                            categoryId: item.category_id,
                            title: item.item_name, 
                            // subtitle: , 
                            qtyLabel: 'x${item.quantity}',
                            amount: item.total_price,
                            currency: _currencyTh,
                            date: item.receiptDate,
                            onTap: () => _openEditModal(item)
                          );
                        },
                      )
                    : const _EmptyTransactionCard(),
                  )
                ],
              ),
            );
          }
        )
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final int categoryId;
  final String title;
  final String qtyLabel;
  final num amount;
  final NumberFormat currency;
  final VoidCallback? onTap;
  final DateTime? date;

  const _TransactionRow({
    super.key,
    required this.categoryId,
    required this.title,
    required this.qtyLabel,
    required this.amount,
    required this.currency,
    required this.onTap,
    required this.date,
    });

  @override
  Widget build(BuildContext context) {
    final String dateLabel = (date != null)
      ? DateFormat('dd/MM/yyyy').format(date!)
      : '-';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
          ),
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorForCategoryId(categoryId).withOpacity(0.2),
                child: Icon(iconForCategoryId(categoryId), color: colorForCategoryId(categoryId),),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(title,
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(qtyLabel,
                        style: GoogleFonts.prompt(fontWeight: FontWeight.w500, color: Colors.grey)),
                    ]),
                    Text(dateLabel,
                      style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5)))
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${currency.format(amount)}',
                    style: GoogleFonts.prompt(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Icon(Icons.chevron_right_outlined,
                    size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionCard  extends StatelessWidget {
  const _EmptyTransactionCard ({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5)
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("No transactions",
                    style:
                        GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                Text("for this period",
                    style: GoogleFonts.prompt(color: Colors.black54)),
              ],
            ),
          ),
          Text(
            "฿0.00",
            style: GoogleFonts.prompt(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700)
      ),
      child: Text(message,style: GoogleFonts.prompt(color: Colors.red.shade700),),
    );
  }
}