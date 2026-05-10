import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final fullnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final geminiController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureGemini = true;

  static const Color kPrimary = Color(0xFF16A34A);
  static const Color kPrimaryDark = Color(0xFF166534);
  static const Color kAccentBlue = Color(0xFF0EA5E9);
  static const Color kAccentYellow = Color(0xFFFACC15);
  static const Color kBg = Color(0xFFF3F4F6);
  static const Color kInputBg = Color(0xFFF8FAFC);

  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    geminiController.dispose();
    super.dispose();
  }

  void fillDemoData() {
    setState(() {
      fullnameController.text = 'Test User';
      emailController.text = 'test@gmail.com';
      passwordController.text = '12345678';
      confirmPasswordController.text = '12345678';
      geminiController.text = 'AIzaSyAC9AYOlj-Bgmk1ErDJAeHPlEO5ex5R6Co';
    });
  }

  // void fillDemoData() {
  //   setState(() {
  //     fullnameController.text = 'Test User';
  //     emailController.text = 'test@example.com';
  //     passwordController.text = '12345678';
  //     confirmPasswordController.text = '12345678';
  //     geminiController.text = 'AIzaSyAC9AYOlj-Bgmk1ErDJAeHPlEO5ex5R6Co';
  //   });
  // }

  Future<void> register() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await ProfileService().register(
        fullname: fullnameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        geminiApiKey: geminiController.text.trim().isEmpty
            ? null
            : geminiController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Register success')),
      );

      Navigator.pop(context, {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
      });
    } on DioException catch (err) {
      final data = err.response?.data;
      final msg = data is Map
          ? (data['message'] ?? data['detail'] ?? data['error'] ?? err.message)
          : (data?.toString() ?? err.message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register failed: $msg')),
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register failed: $err')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _isEmail(String value) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildRegisterCard(),
                ),
              ),
            ),
          ),
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
            colors: const [Color(0xFF0D9488), kPrimary],
          ),
        ),
        Positioned(
          bottom: -90,
          right: -40,
          child: _blob(
            width: 260,
            height: 260,
            colors: const [Color(0xFF0F9488), kPrimary],
          ),
        ),
        Positioned(
          top: 60,
          right: 40,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: kAccentYellow,
              shape: BoxShape.circle,
            ),
          ),
        ),
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
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.85),
          width: 0.7,
        ),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'SlipTrack',
                  style: GoogleFonts.prompt(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryDark,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
        
              const SizedBox(height: 16),
        
              Text(
                'Create Account',
                style: GoogleFonts.prompt(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryDark,
                ),
              ),
        
              const SizedBox(height: 4),
        
              Text(
                'Register to start tracking your receipts and spending.',
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
        
              const SizedBox(height: 20),
        
              _label('Full name'),
              _input(
                controller: fullnameController,
                autofillHints: const [AutofillHints.name],
                hintText: 'Your name',
                icon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
        
              const SizedBox(height: 14),
        
              _label('Email'),
              _input(
                controller: emailController,
                hintText: 'you@example.com',
                autofillHints: const [AutofillHints.email],
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!_isEmail(value.trim())) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
        
              const SizedBox(height: 14),
        
              _label('Password'),
              _input(
                controller: passwordController,
                hintText: '******',
                autofillHints: const [AutofillHints.password],
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
        
              const SizedBox(height: 14),
        
              _label('Confirm password'),
              _input(
                controller: confirmPasswordController,
                hintText: '******',
                autofillHints: const [AutofillHints.password],
                icon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != passwordController.text) {
                    return 'Password does not match';
                  }
                  return null;
                },
              ),
        
              const SizedBox(height: 14),
        
              _label('Gemini API Token'),
              _input(
                controller: geminiController,
                hintText: 'Optional',
                icon: Icons.key_rounded,
                obscureText: _obscureGemini,
                helperText:
                    'ใส่ Gemini API Token ของคุณเองได้ภายหลังในหน้า Edit Profile',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureGemini
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() => _obscureGemini = !_obscureGemini);
                        },
                ),
              ),
        
              // const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : fillDemoData,
                  child: Text(
                    'Fill Demo',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w500, color: Colors.red),
                  ),
                ),
              ),

              // const SizedBox(height: 12),
        
              SizedBox(
                width: double.infinity,
                height: 46,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kAccentBlue],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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
                              'Register',
                              key: const ValueKey('text'),
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
        
              const SizedBox(height: 16),
        
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kAccentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.prompt(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? helperText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) {
    return TextFormField(
      controller: controller,
      autofillHints: autofillHints,
      enabled: !isLoading,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.prompt(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        hintStyle: GoogleFonts.prompt(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        helperStyle: GoogleFonts.prompt(
          fontSize: 11,
          color: Colors.grey[600],
          height: 1.3,
        ),
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kInputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: kPrimary,
            width: 1.2,
          ),
        ),
      ),
      validator: validator,
    );
  }


}
