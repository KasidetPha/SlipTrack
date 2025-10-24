import 'package:flutter/material.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/pages/profile_page/edit_profile_page.dart';
import 'package:frontend/pages/profile_page/budget_setting.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  bool _loading = false;

  Future<bool> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('คุณต้องการออกจากระบบใช่ไหม'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _handleSignOut() async {
    if (_loading) return;
    if (!await _confirmSignOut()) return;

    setState(() => _loading = true);
    try {
      // TODO: ถ้ามี AuthService.logout() ให้เรียกที่นี่
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');   // ปรับ key ให้ตรงกับโปรเจกต์
      // await prefs.remove('refresh_token');  // ถ้ามี

      if (!mounted) return;
      // กลับไปหน้า Login และเคลียร์สแตกทั้งหมด
      Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (ctx) => const LoginPage()), 
      (route) => false
    );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Account Settings",
              style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 24),

          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const EditProfilePage()));
              debugPrint("Edit Profile clicked");
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.edit, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Edit Profile",
                            style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text("Update your personal information",
                            style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BudgetSetting()));
              debugPrint("budget setting clicked");
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.account_balance_wallet, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Budget Settings",
                            style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text("Set monthly spending limits",
                            style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade600,
                padding: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : _handleSignOut,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      "Sign Out",
                      style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
