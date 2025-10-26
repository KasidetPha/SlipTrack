import 'package:flutter/material.dart';
import 'package:frontend/models/stats_summary.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class SummaryCard extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final String title;
  final bool isCategoryMode;

  const SummaryCard({
    super.key, 
    required this.selectedMonth, 
    required this.selectedYear,
    this.title = 'summary',
    this.isCategoryMode = false
    
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {

  final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

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
  void didUpdateWidget(covariant SummaryCard oldWidget) {
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
    // TODO: implement dispose
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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
              child: CircularProgressIndicator(color: Colors.white,),
            )
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
            if (sc == 401 || sc == 403) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _logoutAndRedirect());
              msg = 'หมดสิทธิ์การใช้งาน โปรดเข้าสู่ระบบใหม่';
            }
          } else {
            msg = err.toString();
          }
          // ignore : avoid_print
          print('SummaryCard err: $err');
          
          return SizedBox(
            height: 150,
            child: Center(
              child: Text(msg, style: GoogleFonts.prompt(color: Colors.red),),
            ),
          );
        } 

        final summary = snapshot.data;

        if (summary == null) {
          return SizedBox(
            height: 150,
            child: Center(child: Text("ไม่มีข้อมูล", style: GoogleFonts.prompt(color: Colors.red))),
          );
        }

        final thisMonth = summary.thisMonth;
        final percentChange = summary.percentChange;

        final isIncrease = percentChange > 0;
        final isZero = percentChange == 0;
        // final arrowIcon = isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
        final arrowIcon = isZero ? Icons.remove_rounded : (isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);
        // final arrowColor = isIncrease ? Colors.redAccent : Colors.greenAccent;
        final arrowColor = isZero ? Colors.grey : (isIncrease ? Colors.redAccent : Colors.greenAccent);

        final percentText = "${percentChange.abs().toStringAsFixed(2)}%";

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          width: double.infinity,
          // height: 200,
        
          decoration: BoxDecoration(
            // color: Colors.white,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title, style: GoogleFonts.prompt(textStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),)),
                  // SizedBox(height: 12,),
                  // widget.isCategoryMode ? SizedBox.shrink() : 
                  // MouseRegion(
                  //   cursor: SystemMouseCursors.click,
                  //   child: Tooltip(
                  //     message: isPercentView ? 'สลับมุมมองจำนวนเงิน (฿)' : 'สลับมุมมองเป็นเปอร์เซ็นต์ (%)',
                  //     waitDuration: const Duration(milliseconds: 400),
                  //     showDuration: const Duration(seconds: 3),
                  //     verticalOffset: 10,
                  //     preferBelow: false,
                  //     decoration: BoxDecoration(
                  //       color: Colors.black.withOpacity(0.85),
                  //       borderRadius: BorderRadius.circular(12)
                  //     ),
                  //     textStyle: GoogleFonts.prompt(color: Colors.white, fontSize: 12),
                  //     child: Semantics(
                  //       button: true,
                  //       label: isPercentView
                  //       ? 'Switch to amount view'
                  //       : 'Switch to percent view',
                  //     child: InkWell(
                  //       borderRadius: BorderRadius.circular(20),
                  //       onTap: () {
                  //         setState(() {
                  //           isPercentView = !isPercentView;
                  //         });
                  //       },
                  //       child: AnimatedRotation(
                  //         turns: isPercentView ? 0 : 0.5,
                  //         duration: const Duration(milliseconds: 300),
                  //         curve: Curves.easeInOut,
                  //         child: Container(
                  //           padding: const EdgeInsets.all(6),
                  //           decoration: BoxDecoration(
                  //             color: Colors.white.withOpacity(0.15),
                  //             borderRadius: BorderRadius.circular(20),
                  //           ),
                  //           child: const Icon(
                  //             Icons.swap_horiz_rounded,
                  //             size: 18,
                  //             color: Colors.white,
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //     ),
                  //   ),
                  // )
                  Text('Savings Rate', style: GoogleFonts.prompt(color: Colors.white.withOpacity(0.8)),)
                ],
              ),
              SizedBox(height: 6,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currencyTh.format(thisMonth), style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),)),
                  Text("95%", style: GoogleFonts.prompt(textStyle: TextStyle(fontSize: 25, color: Colors.greenAccent, fontWeight: FontWeight.bold),)),
                  
                ],
              ),

              // if (!widget.isCategoryMode) ...[
              //   SizedBox(height: 6,),
              // ]
            ],
          ),
        );
      }
    );
  }
}
