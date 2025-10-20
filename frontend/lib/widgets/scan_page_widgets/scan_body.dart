import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanBody extends StatefulWidget {
  const ScanBody({super.key});

  @override
  State<ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends State<ScanBody> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: Radius.circular(12),
              strokeWidth: 2.5,
              dashPattern: [15,5],
              padding: EdgeInsets.zero,
              color: Colors.grey.withOpacity(0.8)
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)
              ),
              // color: Colors.grey,
              padding: EdgeInsets.symmetric(vertical: 48),
              // margin: EdgeInsets.symmetric(vertical: 48),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    // alignment: Alignment.center,
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(50)
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined, color: const Color.fromARGB(255, 37, 99, 235), size: 48,
                    ),
                  ),
                  SizedBox(height: 24,),
                  Text("Photo or Select receipt", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),),
                  SizedBox(height: 12,),
                  Text("Take a clear photo of the slip for best results.", style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.5)),),
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 37, 99, 235),
                          borderRadius: BorderRadius.circular(12)
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(12),
                        width: double.infinity,
                        // margin: EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_camera_outlined, color: Colors.white, size: 24,),
                            SizedBox(width: 12,),
                            Text("Photo", style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15) ,),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300)
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(12),
                        width: double.infinity,
                        // margin: EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, color: Colors.black, size: 24,),
                            SizedBox(width: 12,),
                            Text("Select from Gallery", style: GoogleFonts.prompt(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 24,),
          _tips()
        ],
      ),
    );
  }
}

class _tips extends StatelessWidget {
  const _tips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.15)
        ),
        borderRadius: BorderRadius.circular(12)
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Colors.amber,),
                SizedBox(width: 12,),
                Text("Tips for a better scan", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blue.shade900,),),
              ],
            ),
            SizedBox(height: 12,),
            Text('- Good lighting', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue.shade900,),),
            Text('- Full receipt in frame', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue.shade900,),),
            Text('- No shadows or glare', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue.shade900,),),
          ],
        ),
      ),
    );
  }
}