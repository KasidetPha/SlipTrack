import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MostCategory extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<bool>? onHasDataChanged;
  const MostCategory({
    super.key, 
    required this.selectedMonth, 
    required this.selectedYear, 
    this.onHasDataChanged
  });

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
    _notifyHasData(false);
    fetchCategories();
  }

  @override
  void didUpdateWidget(covariant MostCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
    oldWidget.selectedYear != widget.selectedYear) {
      _notifyHasData(false);
      fetchCategories();
    }
  }

  void _notifyHasData(bool hasData) {
    if (widget.onHasDataChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onHasDataChanged!(hasData);
      });
    }
  }
  
  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0.0;
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
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
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
          'total_spent': _parseDouble(e['total_spent'])
        };
      }).toList()..sort((a,b) => (b['total_spent'] as double).compareTo(a['total_spent'] as double));

      if (!mounted) return;
      setState(() {
        categories = list;
        _loading = false;
      });
      if (mounted) {
        _notifyHasData(categories.isNotEmpty);
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
      _error = err.toString();
      _loading = false;
      });
      _notifyHasData(false);
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
                  child: _CategoryCard(
                    color: Colors.green.withOpacity(0.1),
                    amountStyle: GoogleFonts.prompt(fontSize: 18, color:Colors.green, fontWeight: FontWeight.bold),
                    iconPath: "assets/images/icons/icon_food.png",
                    name: topOne['category_name'],
                    amountText: curencyTh.format(topOne['total_spent'] ?? 0.0),
                  ),
                ),
              const SizedBox(width: 16),
              if (topTwo != null)
                Expanded(
                  child: _CategoryCard(
                    color: Colors.blue.withOpacity(0.1),
                    amountStyle: GoogleFonts.prompt(fontSize: 18, color:Colors.blue, fontWeight: FontWeight.bold),
                    iconPath: "assets/images/icons/icon_food.png",
                    name: topTwo['category_name'],
                    amountText: curencyTh.format(topTwo['total_spent'] ?? 0.0),
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

class _CategoryCard extends StatelessWidget {
  final Color color;
  final TextStyle amountStyle;
  final String iconPath;
  final String name;
  final String amountText;
  
  const _CategoryCard({
    required this.color,
    required this.amountStyle,
    required this.iconPath,
    required this.name,
    required this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(12)
      ), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.asset(iconPath, width: 30, height: 30,),
          Text(name, style: GoogleFonts.prompt(fontSize: 16, color: Colors.black),),
          Text(amountText, style: amountStyle)
        ],
      ),
    );
  }
}
