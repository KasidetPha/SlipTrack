import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/first_Username_icon.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/login_page.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  late Future<FirstUsernameIcon> _future;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _cancelToken = CancelToken();
    _future = _load(_cancelToken);
  }

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  Future<FirstUsernameIcon> _load(CancelToken? cancelToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      ApiClient().setToken(token);
    }

    return ReceiptService().fetchInitial(cancelToken: cancelToken);
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiClient().clearToken();

    // กลับไปหน้า Login และเคลียร์ navigation stack
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget _buildAvatar(String initialText) {
    final String initial = (initialText.isNotEmpty ? initialText[0] : '?').toUpperCase();
    return Tooltip(
      message: 'Profile',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)]
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4)
                )
              ]
            ),
            padding: const EdgeInsets.all(2.5),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(initial, style: GoogleFonts.prompt(color: Colors.black87, fontSize: 26, letterSpacing: .5),),
            ),
          )
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return FutureBuilder(future: _future, builder: (context, snapshot) {
      String initial = '?';
      if (snapshot.connectionState == ConnectionState.waiting) {
        initial = '...';
      } else if (snapshot.hasData) {
        final v = snapshot.data!.initial.trim();
        initial = v.isEmpty ? '?' : v.toUpperCase();
      } else if (snapshot.hasError) {
        initial = '?';
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "SlipTrack",
            style: GoogleFonts.prompt(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1
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
            child: _buildAvatar(initial),
          ),
        ],
      );
    });
  }
}
