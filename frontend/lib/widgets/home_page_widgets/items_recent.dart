import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/login_page.dart';

class ItemsRecent extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  const ItemsRecent({super.key,
    required this.selectedMonth,
    required this.selectedYear
  });

  @override
  State<ItemsRecent> createState() => _ItemsRecentState();
}


class _ItemsRecentState extends State<ItemsRecent> {
  late Future<List<ReceiptItem>> _futureItems;
    final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _futureItems = fetchReceiptItems();
    _futureItems = _load();
  }

  @override
  void didUpdateWidget(ItemsRecent oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget called - old: ${oldWidget.selectedMonth}/${oldWidget.selectedYear}, new ${widget.selectedMonth}/${widget.selectedYear}");
    if(oldWidget.selectedMonth != widget.selectedMonth || oldWidget.selectedYear != widget.selectedYear) {
      print("refreshing data for ${widget.selectedMonth}/${widget.selectedYear}");
      setState(() {
        _futureItems = _load();
      });
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
      final items = await ReceiptService().fetchReceiptItems(month: widget.selectedMonth, year: widget.selectedYear);
      return items;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await logoutAndRedirect();
        return [];
      }
      rethrow;
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

        final items = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: items.map((item) =>
              Padding(
                padding: const EdgeInsets.fromLTRB(24,0,24,12),
                child: Container(
                  width: double.infinity,
                  height: 78,
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
                              Image.asset(
                                "assets/images/icons/icon_food.png",
                                width: 25,
                                height: 25,
                              ),
                              const SizedBox(width: 15,),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text("${item.item_name} ", style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
                                      Text("x${item.quantity}", style: GoogleFonts.prompt(fontWeight: FontWeight.w500, color: Colors.grey),),
                                    ],
                                  ),
                                  Text(DateFormat('dd/MM/yyyy').format(item.receiptDate), style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5)),)
                                ]
                              ),
                            ],
                          ),
                          Text(
                            currencyTh.format(item.total_price),
                            style: GoogleFonts.prompt(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 18
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ).toList()
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
      height: 78,
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
                  Image.asset(
                    "assets/images/icons/icon_food.png",
                    width: 25,
                    height: 25,
                  ),
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