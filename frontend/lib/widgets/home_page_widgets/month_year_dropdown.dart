import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MonthYearDropdown extends StatefulWidget {
  final Function(int month, int year)? onMonthYearChanged;
  
  const MonthYearDropdown({super.key, this.onMonthYearChanged});

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

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   fetchReceipts();
    // });
  }

  int getMonthNumber(String monthName) {
    return months.indexOf(monthName) + 1;
  }

  void notifyParent() {
    if (selectedMonth != null && selectedYear != null) {
      final monthNumber = getMonthNumber(selectedMonth!);

      if (widget.onMonthYearChanged != null) {
        widget.onMonthYearChanged!(monthNumber, selectedYear!);
      }
    }
  }

  void updateMonth(String? value) {
    if (value == null || value == selectedMonth) return;
    setState(() {
      selectedMonth = value;
    });
    
    notifyParent();
  }

  void updateYear(int? value) {
    if (value == null || value == selectedYear) return;
    setState(() {
      selectedYear = value;
    });

    notifyParent();
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