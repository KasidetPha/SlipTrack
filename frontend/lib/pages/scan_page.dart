import 'package:flutter/material.dart';
import 'package:frontend/widgets/scan_page_widgets/scan_body.dart';
import 'package:frontend/widgets/scan_page_widgets/scan_header.dart';

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
        centerTitle: true,
        title: Text("Scan receipt"),
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
