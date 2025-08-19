import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // height: double.infinity,
        padding: const EdgeInsets.all(24),
        height: 280,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 37, 98, 235), Color.fromARGB(144, 76, 52, 234)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
          ),
          // color: Colors.blue,
          borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 2,
            offset: const Offset(0, 1)
          )
        ]
        ),
        // color: Colors.amber,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "SlipTrack",
                  style: GoogleFonts.prompt(
                    textStyle: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2
                    ),
                  )

                ),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(25)
                    ),
                    child: IconButton(
                      icon: Image.asset("assets/images/icon_user.png", fit: BoxFit.contain, color: Colors.black.withOpacity(0.5),),
                      // color: Colors.black.withOpacity(0.50),
                      onPressed: () {
                        print("Profile button clicked");
                      },
                    ),
                  ),
                ),
              ]
            ),
            SizedBox(height: 20,),
            SizedBox(
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
                    Text("Total Expenses This Month", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 15, color: Colors.white),)),
                    Text("1,246.50 บาท", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),)),
                    Text("12% from last month", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 15, color: Colors.white),)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}