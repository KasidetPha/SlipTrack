import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SummaryCard extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;

  const SummaryCard({super.key, 
    required this.selectedMonth, 
    required this.selectedYear
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {

  Future<Map<String, dynamic>> fetchTotalAmount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    // if (token.isEmpty) {
    //   return [];
    // }

    final response = await http.post(
      Uri.parse('http://localhost:3000/getMonthlyExpensesComparison'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'month': widget.selectedMonth,
        'year': widget.selectedYear
      })
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load sum total amount');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchTotalAmount(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white,),
            )
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 150,
            child: Center(
              child: Text("เกิดข้อผิดพลาด", style: GoogleFonts.prompt(color: Colors.red),),
            ),
          );
        } else if (!snapshot.hasData) {
          return SizedBox(
            height: 150,
            child: Center(
              child: Text("ไม่มีข้อมูล", style: GoogleFonts.prompt(color: Colors.red),),
            ),
          );
        }

        final data = snapshot.data!;

        final thisMonth = double.tryParse(data['thisMonth']?.toString() ?? '0') ?? 0.0;
        final percentChange = double.tryParse(data['percentChange']?.toString() ?? '0') ?? 0.0;

        final isIncrease = percentChange >= 0;
        final arrowIcon = isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
        final arrowColor = isIncrease ? Colors.redAccent : Colors.greenAccent;

        final percentText = isIncrease ? "${percentChange.toStringAsFixed(2)}%" :"${percentChange.abs().toStringAsFixed(2)}%";

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          width: double.infinity,
          height: 150,
        
          decoration: BoxDecoration(
            // color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3)
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Total Expenses This Month", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),)),
              Text("${thisMonth.toStringAsFixed(2)}", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),)),
              Row(
              children: [
                  Icon(arrowIcon, color: arrowColor,),
                  SizedBox(width: 5,),
                  Text("${percentText} from last month", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),)),
                ],
              )
            ],
          ),
        );
      }
    );
  }
}