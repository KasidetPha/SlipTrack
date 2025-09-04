import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "SlipTrack",
          style: GoogleFonts.prompt(
            textStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1
            ),
          )
        ),
        CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage("assets/images/profiles/profile_test.jpg"),
        )
      ]
    );
  }
}