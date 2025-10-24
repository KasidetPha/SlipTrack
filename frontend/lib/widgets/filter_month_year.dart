import 'package:flutter/material.dart';

class FilterMonthYear extends StatefulWidget {
  final Function(int month, int year)? onMonthYearChanged;

  final int? initialMonth;
  final int? initialYear;
  
  const FilterMonthYear({
    super.key,
    this.onMonthYearChanged,
    this.initialMonth,
    this.initialYear
  });

  @override
  State<FilterMonthYear> createState() => _FilterMonthYearState();
}

class _FilterMonthYearState extends State<FilterMonthYear> {
  static const List<String> months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
    "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = widget.initialMonth ?? now.month;
    _year = widget.initialYear ?? now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) => {
      widget.onMonthYearChanged?.call(_month, _year)
    });
  }

  void _emit() =>widget.onMonthYearChanged?.call(_month, _year);

  void _prev() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
      print("$_month, $_year");
    });

      _emit();
  }

  void _next() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
      print("$_month, $_year");
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          IconButton(
            onPressed: _prev,
            icon: const Icon(Icons.chevron_left_outlined),
            color: Colors.white,
          ),
          SizedBox(width: 2,),
          Icon(Icons.calendar_month_rounded, color: Colors.white,),
          Text(" ${months[_month - 1]} ", style: TextStyle(color: Colors.white),),
          Text("$_year", style: TextStyle(color: Colors.white),),
          SizedBox(width: 2,),
          IconButton(
            onPressed: _next,
            icon: const Icon(Icons.chevron_right_outlined), color: Colors.white,
          ),
          
        ],
      ),
    );
  }
}