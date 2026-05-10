import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/monthly_kind.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ ตัวแปรป้องกันการเตะออกหน้า Login ซ้ำซ้อน
bool _isLoggingOutGlobal = false;

class SummaryCard extends ConsumerWidget {
  final int selectedMonth;
  final int selectedYear;
  final String title;
  final bool isCategoryMode;
  final double? totalOverride;

  const SummaryCard({
    super.key, 
    required this.selectedMonth, 
    required this.selectedYear,
    this.title = 'summary',
    this.isCategoryMode = false,
    this.totalOverride,
  });

  Future<void> _logoutAndRedirect(BuildContext context) async {
    if (_isLoggingOutGlobal) return;
    _isLoggingOutGlobal = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiClient().clearToken();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (totalOverride != null) {
      return _buildCardContent(totalOverride!, 0.0, true);
    }

    final asyncSummary = ref.watch(summaryProvider(MonthlyKind.net));

    return asyncSummary.when(
      loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Colors.white))),
      error: (err, stack) {
        if (err.toString().contains('401') || err.toString().contains('403')) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _logoutAndRedirect(context));
          return SizedBox(height: 150, child: Center(child: Text("หมดสิทธิการใช้งาน", style: GoogleFonts.prompt(color: Colors.red))));
        }
        return SizedBox(height: 150, child: Center(child: Text('เกิดข้อผิดพลาด', style: GoogleFonts.prompt(color: Colors.red))));
      },
      data: (summary) => _buildCardContent(summary?.thisMonth ?? 0.0, summary?.percentChange ?? 0.0, false)
    );
  }

  Widget _buildCardContent(double amountToShow, double percentChange, bool hidePercent) {
    final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    return SizedBox(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(title, style: GoogleFonts.prompt(textStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500))),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currencyTh.format(amountToShow), style: GoogleFonts.prompt(textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}