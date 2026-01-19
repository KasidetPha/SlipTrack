import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/Edit_Receipt_Item_Sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/login_page.dart';

class ItemsRecent extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final int? categoryId;


  const ItemsRecent({super.key,
    required this.selectedMonth,
    required this.selectedYear,
    this.categoryId
  });

  @override
  State<ItemsRecent> createState() => _ItemsRecentState();
}

class _ItemsRecentState extends State<ItemsRecent> {
  late Future<List<ReceiptItem>> _futureItems;
  final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  @override
  void initState() {
    super.initState();
    _futureItems = _load();
  }

  @override
  void didUpdateWidget(ItemsRecent oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget called - old: ${oldWidget.selectedMonth}/${oldWidget.selectedYear}, new ${widget.selectedMonth}/${widget.selectedYear}");

    final monthChange = oldWidget.selectedMonth != widget.selectedMonth || oldWidget.selectedYear != widget.selectedYear;

    final categoryChanged = oldWidget.categoryId != widget.categoryId;

    if(monthChange || categoryChanged) {
      print("refreshing data for ${widget.selectedMonth}/${widget.selectedYear}, catId=${widget.categoryId}");
      setState(() {
        _futureItems = _load();
      });
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

  Future<void> logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiClient().clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<List<ReceiptItem>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      await logoutAndRedirect();
      return [];
    }

    ApiClient().setToken(token);

    try {
      if (widget.categoryId != null) {
        return await ReceiptService().fetchReceiptItemsByCategory(
          categoryId: widget.categoryId!,
          month: widget.selectedMonth,
          year: widget.selectedYear,
        );
      } else {
        return await ReceiptService().fetchReceiptItems(
          month: widget.selectedMonth, 
          year: widget.selectedYear
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await logoutAndRedirect();
        return [];
      }
      rethrow;
    }
  }

  String _buildDateLabel(DateTime date) {
    final now = DateTime.now();

    final bool isSameDate = date.year == now.year && date.month == now.month && date.day == now.day;

    final bool isCurrentFilter = widget.selectedMonth == now.month && widget.selectedYear == now.year;

    if (isSameDate && isCurrentFilter) {
      return 'Today ${date.day}';
    } else {
      final weekday = DateFormat('EEE').format(date);
      return '$weekday ${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReceiptItem>>(
      future: _futureItems,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 78,
                    child: _EmptyTransactionCard(),
                  )
                ),
              ],
            ),
          );
        }

        final items = [...snapshot.data!]
          ..sort(
            (a, b) => b.receiptDate.compareTo(a.receiptDate),
          );

        return SingleChildScrollView(
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];

              print(item.item_name);
              final DateTime dateOnly = 
                DateUtils.dateOnly(item.receiptDate);

              DateTime? previousDate;

              if (index > 0) {
                previousDate = DateUtils.dateOnly(items[index - 1].receiptDate);
              }

              final bool isFirstOfDay = 
                previousDate == null || previousDate != dateOnly;

              final String dateLabel = _buildDateLabel(dateOnly);

              final iconData = 
                (item.iconName != null && item.iconName!.isNotEmpty)
                  ? getIconFromKey(item.iconName!)
                  : Icons.category_rounded;

              final iconColor =
                (item.colorHex != null && item.colorHex!.isNotEmpty)
                  ? colorFromHex(item.colorHex!)
                  : Colors.grey;

              final bool isIncome = item.entryType == 'income';

              final String transactionLabel = isIncome ? 'Income' : 'Expense';

              final Color amountColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;

              final String amountPrefix = isIncome ? '+' : '-';

              return Padding(
                padding: const EdgeInsets.fromLTRB(24,0,24,12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    _openEditModal(item);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFirstOfDay) ... [
                      Text(
                          dateLabel,
                          style: GoogleFonts.prompt(
                            color: Colors.black.withOpacity(0.65),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6,)
                      ],
                        // const SizedBox(height: 12,),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black12,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              offset: const Offset(0,2),
                              blurRadius: 6
                            )
                          ]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 19,
                                      backgroundColor: iconColor.withOpacity(0.15),
                                      child: Icon(
                                        iconData,
                                        color: iconColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transactionLabel, 
                                            style: GoogleFonts.prompt(
                                              color: Colors.black.withOpacity(0.85),
                                              fontSize: 16, 
                                              fontWeight: FontWeight.w700
                                            ),
                                          ),
                                          const SizedBox(height: 4),

                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  item.item_name,
                                                  style: GoogleFonts.prompt(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,                
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: true,
                                                ),
                                              ),
                                              Text(
                                                " x${item.quantity}",
                                                style: GoogleFonts.prompt(
                                                  // fontWeight: FontWeight.w500,
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      
                              const SizedBox(width: 12),
                      
                              Column(
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$amountPrefix${currencyTh.format(item.total_price)}',
                                    style: GoogleFonts.prompt(
                                      color: amountColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                      
                                  const SizedBox(height: 4,),
                                  
                                  const Icon(
                                    Icons.chevron_right_outlined,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()
          ),
        );
      }
    );
  }
}



class _EmptyTransactionCard extends StatelessWidget {
  const _EmptyTransactionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5)
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined),
                  const SizedBox(width: 15),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("No transactions", style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                      Text("for this period", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5))),
                    ],
                  ),
                ],
              ),
              Text(
                "฿0.00",
                style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}