import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/bottom_nav_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("ได้รับแจ้งเตือนขณะปิดแอป: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
        textTheme: GoogleFonts.promptTextTheme()
      ),
      home: const SplashGate(), // ====> main
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
    _setupPushNotifications();
    _bootstrap();
  }

  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("ผู้ใช้อนุญาตให้แจ้งเตือน");

      try {
        String? token = await messaging.getToken();
        print("FCM Device Token: $token");

        if (token != null) {
          bool isLog = await _auth.isLoggedIn();
          if (isLog) {
            await ReceiptService().updateFcmToken(token);
          }
        }
      } catch (e) {
        print("เกิดข้อผิดพลาดในการดึง Token: $e");
      }
    } else {
      print("ผู้ใช้ไม่อนุญาตให้ส่งการแจ้งเตือน");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('ได้รับแจ้งเตือนในขณะเปิดแอป');
      print('หัวข้อ: ${message.notification?.title}');
    });
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