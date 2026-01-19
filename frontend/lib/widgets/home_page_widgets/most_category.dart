import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/category_total.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MostCategory extends StatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<bool>? onHasDataChanged;
  const MostCategory({
    super.key, 
    required this.selectedMonth, 
    required this.selectedYear, 
    this.onHasDataChanged
  });

  @override
  State<MostCategory> createState() => _MostCategoryState();
}

class _MostCategoryState extends State<MostCategory> {
  final curencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  // List<Map<String, dynamic>> categories = [];
  List<CategoryTotal> _categories = [];
  bool _loading = false;
  String ? _error;

  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _notifyHasData(false);
    _cancelToken = CancelToken();
    _fetchCategories();
  }

  @override
  void didUpdateWidget(covariant MostCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
    oldWidget.selectedYear != widget.selectedYear) {
      _notifyHasData(false);
      _fetchCategories();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  void _notifyHasData(bool hasData) {
    if (widget.onHasDataChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onHasDataChanged!(hasData);
      });
    }
  }

  Future<void> _syncTokenToClient() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      ApiClient().setToken(token);
    } else {
      print('MostCategory: token is empty');
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _syncTokenToClient();

      final list = await ReceiptService().fetchCategoryTotals(
        month: widget.selectedMonth, 
        year: widget.selectedYear,
        cancelToken: _cancelToken
      );

      if (!mounted) return;
      setState(() {
        _categories = list;
        _loading = false;
      });
      _notifyHasData(_categories.isNotEmpty);

    } on DioException catch (e) {
      if (!mounted) return;
      // ignroe: avoid_print
      print('MostCategory Dio error: ${e.response?.statusCode} ${e.message}');
      setState(() {
        _error = e.message ?? 'Network error';
        _loading = false;
        _categories = [];
      });
      _notifyHasData(false);
    } on ApiException catch (e) {
      if (!mounted) return;
      print('MostCategory ApiException: ${e.statusCode} ${e.message}');
      setState(() {
        _error = "${e.message} (${e.statusCode ?? '-'})";
        _loading = false;
        _categories = [];
      });
      _notifyHasData(false);
    } catch (err) {
      if (!mounted) return;
      print('MostCategory error: $err');
      setState(() {
        _error = err.toString();
        _loading = false;
        _categories = [];
      });
      _notifyHasData(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(),),);
    }

    if (_error != null) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text("Error: $_error", style: GoogleFonts.prompt(color: Colors.red),),
        ),
      );
    }

    if (_categories.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text('ยังไม่มีข้อมูลในเดือนนี้', style: GoogleFonts.prompt(),),
        ),
      );
    }

    final topOne = _categories.isNotEmpty ? _categories[0] : null;
    final topTwo = _categories.length > 1 ? _categories[1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (topOne != null)
                Expanded(
                  child: _CategoryCard(
                    accent: (topOne.colorHex != null && topOne.colorHex!.isNotEmpty)
                      ? colorFromHex(topOne.colorHex!)
                      : Colors.blue,

                    bgColor: ((topOne.colorHex != null && topOne.colorHex!.isNotEmpty)
                      ? colorFromHex(topOne.colorHex!)
                      : Colors.blue).withOpacity(0.1),

                    amountStyle: GoogleFonts.prompt(
                      fontSize: 18,
                      color: (topOne.colorHex != null && topOne.colorHex!.isNotEmpty)
                        ? colorFromHex(topOne.colorHex!)
                        : Colors.blue,
                      fontWeight: FontWeight.bold
                    ),
                    iconData: (topOne.iconName != null && topOne.iconName!.isNotEmpty)
                      ? getIconFromKey(topOne.iconName!)
                      : Icons.category_rounded,

                    name: topOne.categoryName,
                    amountText: curencyTh.format(topOne.totalSpent),
                  ),
                ),
              const SizedBox(width: 16),
              if (topTwo != null)
                Expanded(
                  child: _CategoryCard(
                    accent: (topTwo.colorHex != null && topTwo.colorHex!.isNotEmpty)
                      ? colorFromHex(topTwo.colorHex!)
                      : Colors.blue,

                    bgColor: ((topTwo.colorHex != null && topTwo.colorHex!.isNotEmpty)
                      ? colorFromHex(topTwo.colorHex!)
                      : Colors.blue).withOpacity(0.1),

                    amountStyle: GoogleFonts.prompt(
                      fontSize: 18,
                      color: (topTwo.colorHex != null && topTwo.colorHex!.isNotEmpty)
                        ? colorFromHex(topTwo.colorHex!)
                        : Colors.blue,
                      fontWeight: FontWeight.bold
                    ),
                    iconData: (topTwo.iconName != null && topTwo.iconName!.isNotEmpty)
                      ? getIconFromKey(topTwo.iconName!)
                      : Icons.category_rounded,

                    name: topTwo.categoryName,
                    amountText: curencyTh.format(topTwo.totalSpent),
                  ),
                )
              else
                const Expanded(child: SizedBox())
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Color bgColor;
  final IconData iconData;
  final Color accent;
  final TextStyle amountStyle;
  // final String iconPath;
  final String name;
  final String amountText;
  
  const _CategoryCard({
    required this.bgColor,
    required this.iconData,
    required this.accent,
    required this.amountStyle,
    // required this.iconPath,
    required this.name,
    required this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.01)),
        color: bgColor, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 2,
            offset: const Offset(0,1)
          )
        ]
      ), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(iconData, size: 28, color: accent,),
          Text(name, style: GoogleFonts.prompt(fontSize: 16, color: Colors.black),),
          Text(amountText, style: amountStyle)
        ],
      ),
    );
  }
}
