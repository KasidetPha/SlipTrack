import 'package:flutter/material.dart';
import 'package:frontend/widgets/add_expense_page_widgets/add_expense_body.dart';
import 'package:frontend/widgets/add_expense_page_widgets/add_expense_header.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_fonts/google_fonts.dart';

class AddExpensePage extends StatelessWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        toolbarHeight: 80,
        title: const Text('Add Expense'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            // borderRadius: BorderRadius.vertical(
            //   bottom: Radius.circular(30)
            // ),
            gradient: LinearGradient(
              colors: [Color(0xFFFF5E62), Color(0xFFFB2966)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const AddExpenseHeader(),
            const AddExpenseBody()
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8), // กันชนกับขอบจอ
        child: SizedBox(
          width: 220,
          height: 56,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2563EB), // 🔵 สีน้ำเงินหลัก
            foregroundColor: Colors.white,             // ตัวอักษรเป็นสีขาว
            onPressed: () {
              debugPrint('Save clicked');
            },
            label: Text(
              'Save',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            // icon: const Icon(Icons.check_rounded),
          ),
        ),
      ),
    );
  }
}
