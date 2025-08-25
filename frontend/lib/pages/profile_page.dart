import 'package:flutter/material.dart';
import 'package:frontend/widgets/profile_page_widgets/profile_body.dart';
import 'package:frontend/widgets/profile_page_widgets/profile_header.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileHeader(),
          const ProfileBody()
        ],
      ),
    );
  }
}