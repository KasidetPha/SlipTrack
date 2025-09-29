import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_page/budget_setting.dart';
import 'package:frontend/pages/profile_page/edit_profile_page.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/home_page_widgets/items_recent.dart';
import 'widgets/bottom_nav_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const SplashGate(),
      // home: const BottomNavPage(),
      // home: const BudgetSetting(),
      // home: EditProfilePage()
      // home: ItemsRecentPage()
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  final _auth = AuthService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final ok = await _auth.isLoggedIn();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavPage())
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(),),
    );
  }
}