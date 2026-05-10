import 'package:flutter/material.dart';
import 'package:frontend/widgets/scan_page_widgets/scan_body.dart';
import 'package:frontend/widgets/scan_page_widgets/scan_header.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 8,
        shadowColor: const Color.fromARGB(255, 76, 124, 255).withOpacity(0.3), // เงาสีชมพูอ่อนๆ
        centerTitle: true,
        toolbarHeight: 75, // เพิ่มความสูงให้ดูโปร่งขึ้น
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 76, 124, 255), Color.fromARGB(255, 29, 78, 216)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Scan Receipt',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 22, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ScanHeader(),
            ScanBody()
          ],
        ),
      ),
    );
  }
}
