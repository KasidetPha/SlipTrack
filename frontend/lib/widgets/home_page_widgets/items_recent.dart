import 'package:flutter/material.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

// แก้ ReceiptItem model ให้รองรับ total_amount เป็น String
class ReceiptItem {
  final String item_name;
  final double total_amount;
  final DateTime receipt_date;

  ReceiptItem({required this.item_name, required this.total_amount, required this.receipt_date});

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    // final parsedDate = DateTime.tryParse(json['receipt_date'] ?? '');
    return ReceiptItem(
      item_name: json['item_name'] ?? '',
      total_amount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      receipt_date: DateTime.tryParse(json['receipt_date'] ?? '')?.toLocal() ?? DateTime.now()
    );
  }
}

class _ItemsRecentState extends State<ItemsRecent> {
  late Future<List<ReceiptItem>> _futureItems;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _futureItems = fetchReceiptItems();
  }

  @override
  void didUpdateWidget(ItemsRecent oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget called - old: ${oldWidget.selectedMonth}/${oldWidget.selectedYear}, new ${widget.selectedMonth}/${widget.selectedYear}");
    if(oldWidget.selectedMonth != widget.selectedMonth || oldWidget.selectedYear != widget.selectedYear) {
      print("refreshing data for ${widget.selectedMonth}/${widget.selectedYear}");
      setState(() {
        _futureItems = fetchReceiptItems();
      });
    }
  }

  Future<void> logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<List<ReceiptItem>> fetchReceiptItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      await logoutAndRedirect();
      return [];
    }

    final response = await http.post(
      Uri.parse('http://localhost:3000/receipt_item'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'month': widget.selectedMonth,
        'year': widget.selectedYear,
      })
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((item) => ReceiptItem.fromJson(item)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await logoutAndRedirect();
      return [];
    } else {
      throw Exception("Can't fetch Receipt: ${response.statusCode}");
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
          return const Center(child: Text("Not found Item"));
        }

        final items = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: items.map((item) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
                                  Text("${item.item_name}", style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
                                  Text(DateFormat('dd-MM-yyyy').format(item.receipt_date), style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5)),)
                                ]
                              ),
                            ],
                          ),
                          Text(
                            "${item.total_amount.toStringAsFixed(2)}.-",
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
            ).toList(),
          ),
        );
      }
    );
  }
}
