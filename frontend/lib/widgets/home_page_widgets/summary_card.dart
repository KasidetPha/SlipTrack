import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Container(
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
            Text("1,246.50 THB", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),)),
            Row(
            children: [
                Icon(Icons.arrow_upward_rounded, color: Colors.white.withOpacity(0.8)),
                SizedBox(width: 5,),
                Text("12% from last month", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),)),
              ],
            )
          ],
        ),
      ),
    );
  }
}