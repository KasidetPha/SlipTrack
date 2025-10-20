import 'package:flutter/material.dart';
import 'package:frontend/widgets/add_expense_page_widgets/add_body.dart';
import 'package:frontend/widgets/add_expense_page_widgets/add_header.dart';
// import 'package:google_fonts/google_fonts.dart';

class AddExpensePage extends StatelessWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AddHeader(),
            const AddBody()
          ],
        ),
      ),
    );
  }
}
