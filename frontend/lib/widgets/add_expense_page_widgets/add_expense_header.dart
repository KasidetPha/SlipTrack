import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddExpenseHeader extends StatelessWidget {
  const AddExpenseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255,22, 163, 74),
            Color.fromARGB(144, 13, 148, 134)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Add Expense", style: GoogleFonts.prompt(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 1))
        ],
      )
    );
  }
}