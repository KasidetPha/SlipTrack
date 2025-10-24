import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthYearDropdown extends StatefulWidget {
  final Function(int month, int year)? onMonthYearChanged;

  // ค่าใหม่ที่เพิ่มเข้ามา
  final int? initialMonth;
  final int? initialYear;
  final int startYear;
  final int endYear;
  final Color dropdownColor;
  final TextStyle? textStyle;

  const MonthYearDropdown({
    super.key,
    this.onMonthYearChanged,
    this.initialMonth,
    this.initialYear,
    this.startYear = 2020,
    this.endYear = 2030,
    this.dropdownColor = const Color.fromARGB(255, 37, 98, 235),
    this.textStyle,
  });

  @override
  State<MonthYearDropdown> createState() => _MonthYearDropdownState();
}

class _MonthYearDropdownState extends State<MonthYearDropdown> {
  final List<String> months = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];

  late List<int> years;

  String? selectedMonth;
  int? selectedYear;

  @override
  void initState() {
    super.initState();
    years = List<int>.generate(
      widget.endYear - widget.startYear + 1,
      (i) => widget.startYear + i,
    );

    final now = DateTime.now();
    selectedMonth = widget.initialMonth != null
        ? months[widget.initialMonth! - 1]
        : months[now.month - 1];

    selectedYear = widget.initialYear ?? now.year;
  }

  int getMonthNumber(String monthName) {
    return months.indexOf(monthName) + 1;
  }

  void notifyParent() {
    if (selectedMonth != null && selectedYear != null) {
      widget.onMonthYearChanged?.call(
        getMonthNumber(selectedMonth!),
        selectedYear!,
      );
    }
  }

  void updateMonth(String? value) {
    if (value == null || value == selectedMonth) return;
    setState(() => selectedMonth = value);
    notifyParent();
  }

  void updateYear(int? value) {
    if (value == null || value == selectedYear) return;
    setState(() => selectedYear = value);
    notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.textStyle ?? GoogleFonts.prompt(color: Colors.white);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 2)
                )
              ]
            ),
            child: DropdownButtonFormField<String>(
              dropdownColor: widget.dropdownColor,
              value: selectedMonth,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 24,
              ),
              decoration: _inputDecoration(),
              style: style,
              iconEnabledColor: Colors.white,
              items: months.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(month, style: style),
                );
              }).toList(),
              onChanged: updateMonth,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              // color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 2)
                )
              ]
            ),
            child: DropdownButtonFormField<int>(
              decoration: _inputDecoration(),
              style: style,
              dropdownColor: widget.dropdownColor,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 24,
              ),
              iconEnabledColor: Colors.white,
              value: selectedYear,
              items: years.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString(), style: style),
                );
              }).toList(),
              onChanged: updateYear,
            ),
          ),
        )
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      label: null,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12)
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // enabledBorder: OutlineInputBorder(
      //   borderSide: const BorderSide(color: Colors.white, width: 1),
      //   borderRadius: BorderRadius.circular(12),
      // ),
      // focusedBorder: OutlineInputBorder(
      //   borderSide: const BorderSide(color: Colors.white, width: 1),
      //   borderRadius: BorderRadius.circular(12),
      // ),
    );
  }
}
