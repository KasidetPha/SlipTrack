import 'package:flutter/material.dart';
import 'package:frontend/widgets/add_page_widgets/add_body.dart';
import 'package:frontend/widgets/add_page_widgets/add_header.dart';
// import 'package:google_fonts/google_fonts.dart';

class AddPage extends StatelessWidget {
  const AddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AddHeader(),
            const AddBody()
          ],
        ),
      ),
    );
  }
}
