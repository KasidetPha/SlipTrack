import 'package:flutter/material.dart';
import 'package:frontend/pages/add_expense_page.dart';
import 'package:frontend/pages/category_detail_page.dart';
import 'package:frontend/pages/category_seeall_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/scan_page.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/add_entry_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
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
        fontFamily: GoogleFonts.prompt().fontFamily,
        useMaterial3: true
      ),
      // initialRoute: '/splashGate',
      // routes: {
      //   '/splashGate': (_) => const SplashGate(),
      //   '/scan': (_) => const ScanPage()
      // },

      home: const SplashGate(), // ====> main
      // home: const ScanPage(),
      // home: const AddExpensePage(),
      // home: const BottomNavPage(),
      // home: const BudgetSetting(),
      // home: EditProfilePage()
      // home: ItemsRecentPage()
      // home: CategorySeeall(selectedMonth: DateTime.now().month, selectedYear: DateTime.now().year,)
      // home: CategoryDetailPage(categoryId: 5, month: 10, year: 2025,categoryName: 'Bills',)
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