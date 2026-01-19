import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/bottom_nav_page.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;

  final Map<String, Map<String, String>> _testPresets = {
    'User1' : {
      'email': 'pimchanok@example.com',
      'password': '123456'
    },
    'User2': {
      'email': 'arunwat@example.com',
      'password': '123456',
    },
    'User3': {
      'email': 'kittipat@example.com',
      'password': '123456'
    }
  };
  
  // สีหลัก เขียว
  static const Color kPrimary = Color(0xFF16A34A);
  // สีเขียวเข้ม ใช้กับหัวข้อ
  static const Color kPrimaryDark = Color(0xFF166534);
  // สี accent น้ำเงิน (ใช้กับลิงก์/กราเดียนต์)
  static const Color kAccentBlue = Color(0xFF0EA5E9);
  // สีเหลืองจุดเล็ก ๆ accent
  static const Color kAccentYellow = Color(0xFFFACC15);
  // สีพื้นหลังของทั้งหน้า
  static const Color kBg = Color(0xFFF3F4F6);
  // สีพื้นของช่องกรอก input
  static const Color kInputBg = Color(0xFFF8FAFC);

  Future<void> login() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _auth.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim()
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Seccess"))
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const BottomNavPage()
        )
      );
    } on DioException catch (err) {
      final data = err.response?.data;
      final msg = data is Map
        ? (data['message'] ?? data['error'] ?? err.message)
        : (data?.toString() ?? err.message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $msg"))
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed $err"))
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _applyPreset(String email, String password) {
    if (isLoading) return;

    setState(() {
      emailController.text = email;
      passwordController.text = password;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filed test account'),
        duration: Duration(seconds: 1)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          _buildBackGroundBlobs(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildLoginCard(),
                  ),
                ),
              ),
              
            )
          )
        ],
      ),
    );
  }

  Widget _buildBackGroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _blob(
            width: 220,
            height: 220,
            colors: const [
              Color(0xFF0D9488),
              kPrimary
            ]
          )
        ),
        Positioned(
          bottom: -90,
          right: -40,
          child: _blob(
            width: 260, 
            height: 260, 
            colors: const [
              Color(0xFF0F9488),
              kPrimary
            ]
          )
        ),
        Positioned(
          top: 60, 
          right: 40, 
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: kAccentYellow,
              shape: BoxShape.circle
            ),
          ),
        )
      ],
    );
  }

  Widget _blob({
    required double width,
    required double height,
    required List<Color> colors,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomCenter)
            )
          ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0,12),
          )
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
          width: 0.7
        )
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container(
                //   padding: const EdgeInsets.all(8),
                //   decoration: BoxDecoration(
                //     color: kPrimary.withOpacity(0.10),
                //     borderRadius: BorderRadius.circular(14)
                //   ),
                //   child: const Icon(
                //     Icons.receipt_long_rounded,
                //     size: 20,
                //     color: kPrimary,
                //   ),
                // ),
                // const SizedBox(width: 8,),
                Text(
                  "SlipTrack",
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryDark,
                    letterSpacing: 0.4
                  ),
                )
              ],
            ),

            const SizedBox(height: 16,),

            Text(
              "Welcome",
              style: GoogleFonts.prompt(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kPrimaryDark
              ),
            ),
            const SizedBox(height: 4,),
            Text(
              'Log in to see your lastet receipts and spending insights.',
              style: GoogleFonts.prompt(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4
              ),
            ),
            const SizedBox(height: 20,),

            Text('Email', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800]),),
            const SizedBox(height: 6,),
            TextFormField(
              controller: emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.prompt(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.email_rounded),
                filled: true,
                fillColor: kInputBg,
                contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 0.8
                  )
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: kPrimary,
                    width: 1.2
                  )
                )
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Invalid email format';
                }
                return null;
              },
            ),
            const SizedBox(height: 14,),
            Text('Password', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800]),),
            const SizedBox(height: 6,),
            TextFormField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: _obscurePassword,
              style: GoogleFonts.prompt(fontSize: 14),
              decoration: InputDecoration(
                hintText: '******',
                hintStyle: GoogleFonts.prompt(
                  fontSize: 18,
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded
                  ),
                  onPressed: isLoading 
                    ? null 
                    : () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                ),
                filled: true,
                fillColor: kInputBg,
                contentPadding: 
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 0.8
                  )
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: kPrimary,
                    width: 1.2
                  )
                )
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password myst be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 10,),

            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: isLoading ? null : () {
                    // navigate
                  }, 
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0,0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w500, color: kAccentBlue)
                  ),
                ),
              ]
            ),
            const SizedBox(height: 10,),
            _buildQuickFillCard(),
            
            const SizedBox(height: 14,),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimary, kAccentBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ]
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)
                    )
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isLoading
                      ? const SizedBox(
                        key: ValueKey('loading'),
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: 
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                      : Text(
                        "Login",
                        key: const ValueKey('text'),
                        style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                  )
                ),
              ),
            ),
            const SizedBox(height: 16,),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Don\'t have an account?', style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[700]),),
                  TextButton(
                    onPressed: isLoading 
                    ? null 
                    : () {
                      // navigate
                    }, 
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0,0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap
                    ),
                    child: Text('Register', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600, color: kAccentBlue),),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFillCard() {
    if (_testPresets.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kInputBg,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 0.8
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Quick fill", style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary),),
          const SizedBox(height: 8,),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _testPresets.entries.map((entry) {
              final label = entry.key;
              final email = entry.value['email'] ?? '';
              final password = entry.value['password'] ?? '';

              return OutlinedButton(
                onPressed: () => _applyPreset(email, password),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: kPrimary.withOpacity(0.6),
                    width: 0.9
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(14)
                  )
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryDark),)
                  ],
                )
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}