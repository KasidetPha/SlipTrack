import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MostCategory extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  const MostCategory({super.key, required this.selectedMonth, required this.selectedYear});

  @override
  State<MostCategory> createState() => _MostCategoryState();
}

class _MostCategoryState extends State<MostCategory> {
  final curencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  List<Map<String, dynamic>> categories = [];
  bool _loading = false;
  String ? _error;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void didUpdateWidget(covariant MostCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedYear != widget.selectedYear) {
          fetchCategories();
    }
  }

  Future<void> fetchCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        throw Exception('Token is empty');
      }

      final response = await http.post(
        Uri.parse('http://localhost:3000/receipt_item/categories'),
        headers: {
          'Authorization': 'Barrer $token',
          'Content-type': 'application/json'
        },
        body: json.encode({
          'month': widget.selectedMonth,
          'year': widget.selectedYear
        })
      );

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}: ${response.body}");
      }

      final List<dynamic> data = json.decode(response.body);
      final list = data.map((e) {
        return {
          'category_name': (e['category_name'] ?? '').toString(),
          'total_spent': double.tryParse((e['total_spent'] ?? '0').toString())
        };
      }).toList()..sort((a,b) => (b['total_spent'] as double).compareTo(a['total_spent'] as double));

      if (!mounted) return;
      setState(() {
        categories = list;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
      _error = err.toString();
      _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(),),);
    }

    if (_error != null) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text("Error: $_error", style: GoogleFonts.prompt(color: Colors.red),),
        ),
      );
    }

    if (categories.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text('ยังไม่มีข้อมูลในเดือนนี้', style: GoogleFonts.prompt(),),
        ),
      );
    }

    final topOne = categories.isNotEmpty ? categories[0] : null;
    final topTwo = categories.length > 1 ? categories[1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (topOne != null)
                Expanded(
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset("assets/images/icons/icon_food.png", width: 30, height: 30),
                        Text(
                          topOne['category_name'],
                          style: GoogleFonts.prompt(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          curencyTh.format(topOne['total_spent'] ?? 0.0),
                          style: GoogleFonts.prompt(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              if (topTwo != null)
                Expanded(
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset("assets/images/icons/icon_transport.png", width: 30, height: 30),
                        Text(
                          topTwo['category_name'],
                          style: GoogleFonts.prompt(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          curencyTh.format(topTwo['total_spent'] ?? 0.0),
                          style: GoogleFonts.prompt(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // SizedBox(height: 8,),
          // TextButton.icon(
          //   style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), iconAlignment: IconAlignment.end),
          //   onPressed: () {}, 
          //   label: Text("See All", style: GoogleFonts.prompt(color: Colors.blueAccent),),
          //   icon: const Icon(Icons.chevron_right_rounded),
          // ),
        ],
      ),
    );
  }
}
