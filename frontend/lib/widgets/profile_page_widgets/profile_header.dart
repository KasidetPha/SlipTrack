import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      height: 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255,147, 50, 233),
            Color.fromARGB(144, 218, 39, 121)
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Profile", style: GoogleFonts.prompt(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
          SizedBox(height: 24,),
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: ClipOval(
              child: Image.asset(
                "assets/images/icons/icon_user.png",
                width: 30,
                height: 30,
              ),
            )
          ),
          SizedBox(height: 24,),
          Text("Kasidet Phasuk", style: GoogleFonts.prompt(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),),
          Text("kasidet@gmail.com", style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)

        ],
      )
    );
  }
}