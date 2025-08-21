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
              icon: Image.asset("assets/images/icons/icon_user.png", fit: BoxFit.contain, color: Colors.black.withOpacity(0.5),),
              // color: Colors.black.withOpacity(0.50),
              onPressed: () {
                print("Profile button clicked");
              },
            ),
          ),
        ),
      ]
    );
  }
}