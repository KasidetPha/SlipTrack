import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemsRecent extends StatelessWidget {
  const ItemsRecent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: Container(
              width: double.infinity,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5)
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Image.asset("assets/images/icons/icon_food.png", width: 25, height: 25,),
                          SizedBox(width: 15,),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Coffee Shop", style: GoogleFonts.prompt(fontWeight: FontWeight.bold),),
                              Text("Today, 9:30 AM", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5)),)
                            ]
                          ),
                        ],
                      ),
                      Text("4.50.-", style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),)
                    ],
                  ),
                ),
              ),
            ),
            
          );
        }),
      ),
    );
  }
}