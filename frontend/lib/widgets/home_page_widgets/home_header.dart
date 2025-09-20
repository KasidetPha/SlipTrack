import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/login_page.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // กลับไปหน้า Login และเคลียร์ navigation stack
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "SlipTrack",
          style: GoogleFonts.prompt(
            textStyle: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1
            ),
          )
        ),
        PopupMenuButton<int>(
          onSelected: (value) {
            if (value == 0) logout(context); // 0 คือ Logout
          },
          itemBuilder: (context) => [
            const PopupMenuItem<int>(
              value: 0,
              child: Text("Logout"),
            ),
          ],
          child: CircleAvatar(
            radius: 30,
            backgroundImage: const AssetImage("assets/images/profiles/profile_test.jpg"),
          ),
        ),
      ],
    );
  }
}
