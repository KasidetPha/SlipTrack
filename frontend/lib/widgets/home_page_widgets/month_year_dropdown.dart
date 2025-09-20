import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MonthYearDropdown extends StatefulWidget {
  const MonthYearDropdown({super.key});

  @override
  State<MonthYearDropdown> createState() => _MonthYearDropdownState();
}

class _MonthYearDropdownState extends State<MonthYearDropdown> {

  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  final List<int> years = List<int>.generate(11, (i) => 2020+i);

  String? selectedMonth;
  int? selectedYear;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedMonth = months[now.month - 1];
    selectedYear = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchReceipts();
    });
  }

  int getMonthNumber(String monthName) {
    return months.indexOf(monthName) + 1;
  }

  Future<void> fetchReceipts() async {
    if (selectedMonth == null || selectedYear == null) return;

    final monthNumber = getMonthNumber(selectedMonth!);
    final url = Uri.parse(
      'http://localhost:3000/receipt_item?month=$monthNumber&year=$selectedYear'
    );

    print("Fetching receipts for $monthNumber/$selectedYear");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(url, headers: {
        'Authorization' : 'Bearer ${token}'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
      } else {
        print("error: ${response.statusCode}");
      }
    } catch (err) {
      print("Exception: $err");
    }
  }

  void updateMonth(String? value) {
    if (value == null || value == selectedMonth) return;
    setState(() {
      selectedMonth = value;
    });

    fetchReceipts();
  }

  void updateYear(int? value) {
    if (value == null || value == selectedYear) return;
    setState(() {
      selectedYear = value;
    });

    fetchReceipts();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(12)
              ),
            ),
            style: TextStyle(color: Colors.white),
            dropdownColor: const Color.fromARGB(255, 37, 98, 235),
            value: selectedMonth,
            items: months.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(month, style: GoogleFonts.prompt()),
              );
            }).toList(),
            onChanged: updateMonth,
          )
        ),
        SizedBox(width: 16,),
        Expanded(
          child: DropdownButtonFormField<int>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(12)
              )
            ),
            dropdownColor: Color.fromARGB(255, 142, 125, 255),
            style: TextStyle(color: Colors.white),
            value: selectedYear,
            items: years.map((year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text(year.toString(), style: GoogleFonts.prompt(),)
              );
            }).toList(),
            onChanged: updateYear,
          ),
        )
      ],
    );
  }
}