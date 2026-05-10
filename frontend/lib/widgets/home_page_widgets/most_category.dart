import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MostCategory extends ConsumerStatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<bool>? onHasDataChanged;

  const MostCategory({
    super.key, 
    required this.selectedMonth, 
    required this.selectedYear, 
    this.onHasDataChanged,
  });

  @override
  ConsumerState<MostCategory> createState() => _MostCategoryState();
}

class _MostCategoryState extends ConsumerState<MostCategory> {
  final curencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  
  void _notifyHasData(bool hasData) {
    if (widget.onHasDataChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onHasDataChanged!(hasData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final asyncCategories = ref.watch(categoryTotalsProvider((
      month: widget.selectedMonth,
      year: widget.selectedYear,
    )));

    return asyncCategories.when(
      loading: () {
        _notifyHasData(false);
        return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(),),);
      },
      error: (err, stack) {
        _notifyHasData(false);
        return SizedBox(
          height: 140,
          child: Center(
            child: Text("Error: $err", style: GoogleFonts.prompt(color: Colors.red),),
          ),
        );
      },
      data: (categories) {
        _notifyHasData(categories.isNotEmpty);
        debugPrint(
          "MOST CATEGORY UI: ${categories.map((e) => '${e.categoryName}: ${e.totalSpent}').toList()}",
        );

        if (categories.isEmpty) {
          return SizedBox(
            height: 140,
            child: Center(
              child: Text('ยังไม่มีข้อมูลในเดือนนี้', style: GoogleFonts.prompt(),),
            ),
          );
        }

        final topOne = categories.isNotEmpty ? categories[0] : null;
        final topTwo = categories.length > 1 ? categories[1] : null;

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