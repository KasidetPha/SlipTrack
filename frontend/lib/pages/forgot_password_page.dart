import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/pages/reset_password_page.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  static const Color kPrimary = Color(0xFF16A34A);
  static const Color kPrimaryDark = Color(0xFF166534);
  static const Color kAccentBlue = Color(0xFF0EA5E9);
  static const Color kAccentYellow = Color(0xFFFACC15);
  static const Color kBg = Color(0xFFF3F4F6);
  static const Color kInputBg = Color(0xFFF8FAFC);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await AuthService().forgotPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(resetToken: token ?? ''),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งคำขอไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
                  child: _buildCard(),
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

  Widget _buildCard() {
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
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 0.7),
      ),
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
              'Forgot Password',
              style: GoogleFonts.prompt(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your email for reset a password.',
              style: GoogleFonts.prompt(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Email',
              style: GoogleFonts.prompt(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.prompt(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: GoogleFonts.prompt(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                prefixIcon: const Icon(Icons.email_rounded),
                filled: true,
                fillColor: kInputBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimary, width: 1.2),
                ),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Please enter your email';
                if (!_isEmail(email)) return 'Invalid email format';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _gradientButton(
              text: 'Send Reset Request',
              loading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kAccentBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String text,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
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
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}