import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/monthly_kind.dart';
import 'package:frontend/models/stats_summary.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseCard extends ConsumerStatefulWidget {
  final int selectedMonth;
  final int selectedYear;

  const ExpenseCard({
    super.key,
    required this.selectedMonth, 
    required this.selectedYear,
  });

  @override
  ConsumerState<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends ConsumerState<ExpenseCard> {

  final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  String formatCurrency(num amount, {int decimals = 1}) {
    final isNeg = amount < 0;
    double v = amount.abs().toDouble();

    String suffix = '';
    double divisor = 1;

    if (v >= 1e9) {
      suffix = 'B';
      divisor = 1e9;
    } else if (v >= 1e6) {
      suffix = 'M';
      divisor = 1e6;
    } else if (v >= 1e3) {
      suffix = 'k';
      divisor = 1e3;
    }

    String numberStr;
    if (suffix.isEmpty) {
      numberStr = NumberFormat.currency(locale: 'th_TH', symbol: '฿').format(v);
    } else {
      final compact = (v / divisor).toStringAsFixed(decimals).replaceAll(RegExp(r'\.?0+$'), '');
      numberStr = '฿$compact$suffix';
    }

    return isNeg ? '-$numberStr' : numberStr;
  }

  bool _loggingOut = false;
  bool isPercentView = true;

  
  Future<void> _logoutAndRedirect() async {
    if (_loggingOut) return;
    _loggingOut = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    ApiClient().clearToken();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSummary = ref.watch(summaryProvider(MonthlyKind.expense));

    return asyncSummary.when(
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(color: Colors.white),),
      ),
      error: (err, stack) {
        print("Expense card err: $err");
        if (err.toString().contains('401') || err.toString().contains('403')) {
          if (!_loggingOut) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _logoutAndRedirect());
          }
          return SizedBox(height: 150, child: Center(child: Text("หมดสิทธิการใช้งาน", style: GoogleFonts.prompt(color: Colors.red)),),);
        }

        return SizedBox(height: 150, child: Center(child: Text('เกิดข้อผิดพลาด', style: GoogleFonts.prompt(color: Colors.red)),),);
      },
      data: (summary) {
        final double thisMonth = summary.thisMonth ?? 0.0;
        double percentChange = summary.percentChange ?? 0.0;

        if (percentChange.isNaN || percentChange.isInfinite) percentChange = 0.0;

        final isIncrease = percentChange > 0;
        final isZero = percentChange == 0;

        final arrowIcon = isZero ? Icons.remove_rounded : (isIncrease ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded);
        final arrowColor = isZero ? Colors.grey : (isIncrease ? Colors.red[300] : Colors.green[300]);

        final String sign = isZero ? '' : (isIncrease ? '+' : '-');
        final percentText = "${percentChange.abs().toStringAsFixed(1)}%";

        final double lastMonth = summary.lastMonth ?? 0.0;

        final double amountChange = thisMonth - lastMonth;

        return SizedBox(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                isPercentView = !isPercentView;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              width: double.infinity,
            
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3)
                  )
                ]
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(16),
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(
                              Icons.touch_app_rounded,
                              size: 96,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                      ),
                    )
                  ),
              
                  Column(
                    // mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        // mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(arrowIcon, color: arrowColor,size: 25,),
                          SizedBox(width: 6,),
                          Text("Expense", style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)
                        ],
                      ),
                      SizedBox(height: 6,),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text("${currencyTh.format(thisMonth)}", style: GoogleFonts.prompt(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700),)
                      ),
                      SizedBox(height: 2,),
                      
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              isPercentView 
                              ? "$sign$percentText " 
                              : "$sign${formatCurrency(amountChange)} ", 
                              style: GoogleFonts.prompt(color: arrowColor, fontWeight: FontWeight.w500),
                            ),
                            Text("vs last mo.", style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}