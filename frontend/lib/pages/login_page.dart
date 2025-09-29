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
  bool isLoading = false;

  final Map<String, Map<String, String>> presets = {
    'user1': {'email': '67110985@dpu.ac.th', 'password': 'Admin1234'},
    'user2': {'email': '67111072@dpu.ac.th', 'password': 'Admin1234'},
    'user3': {'email': 'pimchanok@example.com', 'password': '123456'},
    'user4': {'email': 'arunwat@example.com', 'password': '123456'},
    'user5': {'email': 'kittipat@example.com', 'password': '123456'},
  };

  void fillCreds(String key, {bool submit = false}) {
    final data = presets[key];
    if (data == null) return;
    emailController.text = data['email'] ?? '';
    passwordController.text = data['password'] ?? '';
    if (submit) login();
  }

  Future<void> login() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      await _auth.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Success!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const BottomNavPage()),
      );
    } on DioException catch (err) {
      final data = err.response?.data;
      final msg = data is Map
          ? (data['message'] ?? data['error'] ?? err.message)
          : (data?.toString() ?? err.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $msg")),
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $err")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[400],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      AssetImage("assets/images/icons/icon_sliptrack.jpg"),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(height: 24),
                Text(
                  "Slip Track",
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Track your expenses with ease.",
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.normal,
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email",
                                  style: GoogleFonts.prompt(
                                      fontSize: 18, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                                  style: GoogleFonts.prompt(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.3),
                                    hintText: "Enter your email",
                                    hintStyle: GoogleFonts.prompt(
                                        color: Colors.black.withOpacity(0.4)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.4)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          const BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  "Password",
                                  style: GoogleFonts.prompt(
                                      fontSize: 18, color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  style: GoogleFonts.prompt(color: Colors.white),
                                  onFieldSubmitted: (_) {
                                    if (!isLoading) login();
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.3),
                                    hintText: "Enter your password",
                                    hintStyle: GoogleFonts.prompt(
                                        color: Colors.black.withOpacity(0.4)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Colors.white.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          const BorderSide(color: Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.brown,
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize:
                                        const Size(double.infinity, 0),
                                  ),
                                  onPressed: isLoading ? null : login,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          "Sign In",
                                          style: GoogleFonts.prompt(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.black.withOpacity(0.4),
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                    ),
                                    onPressed: () {
                                      // TODO: implement forgot password flow
                                    },
                                    child: Text(
                                      "Forgot Password?",
                                      style: GoogleFonts.prompt(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => fillCreds('user1'),
                      child: const Text("user1"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => fillCreds('user2'),
                      child: const Text("user2"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => fillCreds('user3'),
                      child: const Text("user3"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => fillCreds('user4'),
                      child: const Text("user4"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => fillCreds('user5'),
                      child: const Text("user5"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
