import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IncomeCard extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  
  const IncomeCard({
    super.key, 
    required this.selectedMonth, 
    required this.selectedYear
  });

  @override
  State<IncomeCard> createState() => _IncomeCardState();
}

class _IncomeCardState extends State<IncomeCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      width: double.infinity,

      decoration: BoxDecoration(
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
        // mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.arrow_drop_up_rounded, color: Colors.green[300],size: 25,),
              SizedBox(width: 6,),
              Text("income", style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)
            ],
          ),
          SizedBox(height: 6,),
          Text("฿13,453", style: GoogleFonts.prompt(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),),
          SizedBox(height: 2,),
          Text("+12% from last month", style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)
        ],
      ),
    );
  }
}