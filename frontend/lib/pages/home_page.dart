import 'package:flutter/material.dart';
import 'package:frontend/widgets/home_widgets/home_header.dart';
import 'package:frontend/widgets/home_widgets/items_recent.dart';
import 'package:frontend/widgets/home_widgets/month_year_dropdown.dart';
import 'package:frontend/widgets/home_widgets/most_category.dart';
import 'package:frontend/widgets/home_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:frontend/models/items_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              // height: 280,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 37, 98, 235),
                    Color.fromARGB(144, 76, 52, 234)
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
              child: const Column(
                children: [
                  HomeHeader(),
                  SizedBox(height: 24),
                  MonthYearDropdown(),
                  SizedBox(height: 24),
                  SummaryCard(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const MostCategory(),

            // const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.fromLTRB(24,24,24,24),
              child: Text("Recent Transactions", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold ),),
            ),

            // const SizedBox(height: 24),

            const ItemsRecent()
          ],
        ),
      ),
    );
  }
}
