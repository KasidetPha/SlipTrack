import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/monthly_kind.dart';
import 'package:frontend/models/stats_summary.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseCard extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;

  const ExpenseCard({
    super.key,
    required this.selectedMonth, 
    required this.selectedYear
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {

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

  late Future<StatsSummary> _future;
  CancelToken? _cancelToken;
  bool _loggingOut = false;
  bool isPercentView = true;

  @override
  void initState() {
    super.initState();
    _cancelToken = CancelToken();
    _future = _load(_cancelToken!);
  }

  @override
  void didUpdateWidget(covariant ExpenseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
      oldWidget.selectedYear != widget.selectedYear) {
        _cancelToken?.cancel('refresh');
        _cancelToken = CancelToken();
        setState(() {
          _future = _load(_cancelToken!);
        });
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    super.dispose();
  }
  
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

  Future<StatsSummary> _load(CancelToken cancelToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      await _logoutAndRedirect();

      throw DioException(
        requestOptions: RequestOptions(path: '/monthlyComparison'),
        type: DioExceptionType.cancel,
        message: "No token"
      );
    }

    // if (token != null && token.isNotEmpty) {
    //   ApiClient().setToken(token);
    // }

    ApiClient().setToken(token);

    return ReceiptService().GetMonthlyComparison(
      month: widget.selectedMonth,
      year: widget.selectedYear,
      type: MonthlyKind.expense,
      cancelToken: cancelToken
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatsSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white)
            ),
          );
        }

        if (snapshot.hasError) {

          String msg = 'เกิดข้อผิดพลาด';
          final err = snapshot.error;

          if (err is DioException) {
            if (err.type == DioExceptionType.cancel) {
              return const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white,),
                ),
              );
            }

            final sc = err.response?.statusCode;
            msg = err.message ?? msg;
            if ((sc == 401 || sc == 403) && !_loggingOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _logoutAndRedirect());
              msg = 'หมดสิทธิ์การใช้งาน โปรดเข้าสู่ระบบใหม่';
            }
          } else {
            msg = err.toString();
          }
          // ignore : avoid_print
          print('Expense card err: $err');

          return SizedBox(
            height: 150,
            child: Center(
              child: Text(msg, style: GoogleFonts.prompt(color: Colors.red),),
            )
          );
        }

        final summary = snapshot.data;

        if (summary == null) {
          return SizedBox(
            height: 150,
            child: Center(child: Text('ไม่มีข้อมูล', style: GoogleFonts.prompt(color: Colors.red),),),
          );
        }

        final double thisMonth = summary.thisMonth ?? 0.0;
        double percentChange = summary.percentChange ?? 0.0;

        if (percentChange.isNaN || percentChange.isInfinite) percentChange = 0.0;

        final isIncrease = percentChange > 0;
        final isZero = percentChange == 0;

        final arrowIcon = isZero ? Icons.remove_rounded : (isIncrease ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded);
        final arrowColor = isZero ? Colors.grey : (isIncrease ? Colors.red[300] : Colors.green[300]);

        final String sign = isZero ? '' : (isIncrease ? '+' : '-');
        final percentText = "${percentChange.abs().toStringAsFixed(1)}%";

        double? lastMonthEstimated;
        final double ratio = 1 + (percentChange / 100.0);
        if (ratio.abs() > 1e-9) {
          lastMonthEstimated = thisMonth / ratio;
        } else {
          lastMonthEstimated = null;
        }

        final double amountChange = (lastMonthEstimated == null)
          ? 0.0
          : (lastMonthEstimated * percentChange.abs() / 100.0);

        return InkWell(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
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
                          Text("Expenses", style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)
                        ],
                      ),
                      SizedBox(height: 6,),
                      Text("${currencyTh.format(thisMonth)}", style: GoogleFonts.prompt(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700),),
                      SizedBox(height: 2,),
                      
                      Row(
                        children: [
                          Text(
                            isPercentView 
                            ? "$sign$percentText " 
                            : "$sign${formatCurrency(amountChange)} ", 
                            style: GoogleFonts.prompt(color: arrowColor, fontWeight: FontWeight.w500),
                          ),
                          Text("vs last mo.", style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)
                        ],
                      )
                    ],
                  ),
                ],
              )
            ),
          ),
        );
      }
    );
  }
}