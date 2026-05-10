import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/profile_page/edit_profile_page.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/category_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final profileLogoutLoadingProvider = StateProvider<bool>((ref) => false);

class ProfileBody extends ConsumerStatefulWidget {
  const ProfileBody({super.key});

  @override
  ConsumerState<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<ProfileBody> {
  bool _loading = false;

  Future<bool> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Sign out?',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณต้องการออกจากระบบใช่ไหม',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('ออกจากระบบ', style: GoogleFonts.prompt()),
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
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('token');
      await prefs.remove('gemini_api_key');

      ApiClient().clearToken();
      ProfileService().clearCache();

      ref.invalidate(userProfileProvider);
      ref.invalidate(userProfileDetailProvider);

      ref.invalidate(transactionsProvider);
      ref.invalidate(summaryProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(categorySummaryProvider);
      ref.invalidate(categoryDetailTotalProvider);
      ref.invalidate(dashboardProvider);

      ref.invalidate(categoriesProvider);
      ref.invalidate(budgetProvider);

      final now = DateTime.now();
      ref.read(calendarFiltersProvider.notifier).state = {
        'month': now.month,
        'year': now.year,
      };

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (ctx) => const LoginPage()),
        (route) => false,
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
  Widget _profileMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconBgColor,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.prompt(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account Settings",
            style: GoogleFonts.prompt(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 24),

          _profileMenuItem(
            icon: Icons.edit_rounded,
            iconColor: Colors.orange,
            iconBgColor: Colors.blue.shade50,
            title: "Edit Profile",
            subtitle: "Update your personal information",
            onTap: () async {
              final updated = await Navigator.push(context,
                MaterialPageRoute(builder: (ctx) => const EditProfilePage())
              );

              if (updated == true) {
                ref.invalidate(userProfileProvider);
              }
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade600,
                padding: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}