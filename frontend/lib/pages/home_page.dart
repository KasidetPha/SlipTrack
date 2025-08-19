import 'package:flutter/material.dart';
import 'package:frontend/widgets/home_widgets/home_header.dart';
import 'package:frontend/widgets/home_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/items_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // ✅ ทำให้ทั้งหน้าเลื่อนได้
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              height: 280,
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
                  SizedBox(height: 20),
                  SummaryCard(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      height: 140,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 240, 253, 244),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset("assets/images/icon_food.png", width: 30, height: 30,),
                          SizedBox(height: 10,),
                          Text("Food & Dining", style: GoogleFonts.prompt(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal)),
                          Text("456.20.-", style: GoogleFonts.prompt(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16,),
                  Expanded(
                    child: Container(
                      height: 140,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 239, 246, 255),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Image.asset("assets/images/icon_transport.png", width: 30, height: 30,),
                          SizedBox(height: 10,),
                          Text("Transportation", style: GoogleFonts.prompt(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal)),
                          Text("234.80.-", style: GoogleFonts.prompt(fontSize: 18, color: Colors.blue[600], fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                  )
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}
