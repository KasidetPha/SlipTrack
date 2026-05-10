import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordPage extends StatefulWidget {
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.resetToken,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color kPrimary = Color(0xFF16A34A);
  static const Color kPrimaryDark = Color(0xFF166534);
  static const Color kAccentBlue = Color(0xFF0EA5E9);
  static const Color kAccentYellow = Color(0xFFFACC15);
  static const Color kBg = Color(0xFFF3F4F6);
  static const Color kInputBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.resetToken;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().resetPassword(
        token: _tokenController.text.trim(),
        newPassword: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset password success. Please login again.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset password failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
              'Reset Password',
              style: GoogleFonts.prompt(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a new password for your account.',
              style: GoogleFonts.prompt(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            // const SizedBox(height: 20),
            // _label('Reset Token'),
            // _input(
            //   controller: _tokenController,
            //   hintText: 'Reset token',
            //   icon: Icons.key_rounded,
            //   validator: (value) {
            //     if (value == null || value.trim().isEmpty) {
            //       return 'Reset token is required';
            //     }
            //     return null;
            //   },
            // ),
            const SizedBox(height: 14),
            _label('New Password'),
            _input(
              controller: _passwordController,
              hintText: '******',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter new password';
                }
                if (value.trim().length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _label('Confirm Password'),
            _input(
              controller: _confirmPasswordController,
              hintText: '******',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please confirm password';
                }
                if (value.trim() != _passwordController.text.trim()) {
                  return 'Password does not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _gradientButton(
              text: 'Reset Password',
              loading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.popUntil(context, (route) => route.isFirst),
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: obscureText,
      style: GoogleFonts.prompt(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.prompt(
          fontSize: 14,
          color: Colors.grey[400],
        ),
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
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
      validator: validator,
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