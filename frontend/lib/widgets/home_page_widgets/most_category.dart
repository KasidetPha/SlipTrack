import 'package:flutter/material.dart';
// import 'package:frontend/models/items_list.dart';
import 'package:google_fonts/google_fonts.dart';

class MostCategory extends StatelessWidget {
  const MostCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  Image.asset("assets/images/icons/icon_food.png", width: 30, height: 30,),
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
                  Image.asset("assets/images/icons/icon_transport.png", width: 30, height: 30,),
                  SizedBox(height: 10,),
                  Text("Transportation", style: GoogleFonts.prompt(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal)),
                  Text("234.80.-", style: GoogleFonts.prompt(fontSize: 18, color: Colors.blue[600], fontWeight: FontWeight.bold))
                ],
              ),
            ),
          )
        ],
      )
    );
  }
}
