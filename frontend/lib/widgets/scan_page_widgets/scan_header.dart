import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanHeader extends StatelessWidget {
  const ScanHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 76, 124, 255),
            Color.fromARGB(255, 29, 78, 216),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 2,
            offset: const Offset(0,1)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (ctx) => ));
              },
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22,),
              ),
            ),
          ),
          Text('Scan Receipt', style: GoogleFonts.prompt(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 1)),
          SizedBox(
            width: 48,
            height: 48,
          ),
        ],
      ),
    );
  }
}