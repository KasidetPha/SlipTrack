import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_page/budget_setting.dart';
import 'package:frontend/pages/profile_page/edit_profile_page.dart';
import 'package:frontend/widgets/home_page_widgets/items_recent.dart';
import 'widgets/bottom_nav_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SlipTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      // home: const BottomNavPage(),
      // home: const BudgetSetting(),
      // home: EditProfilePage()
      // home: ItemsRecentPage()
    );
  }
}
