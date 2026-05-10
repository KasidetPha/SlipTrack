import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/models/receipt_item.dart';
import 'package:frontend/utils/category_icon_mapper.dart';
import 'package:frontend/widgets/Edit_Receipt_Item_Sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/pages/login_page.dart';

class ItemsRecent extends ConsumerStatefulWidget {
  final int selectedMonth;
  final int selectedYear;
  final int? categoryId;
  final String? entryType;

  const ItemsRecent({super.key,
    required this.selectedMonth,
    required this.selectedYear,
    this.categoryId,
    this.entryType,
  });

  @override
  ConsumerState<ItemsRecent> createState() => _ItemsRecentState();
}

class _ItemsRecentState extends ConsumerState<ItemsRecent> {
  final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  final Set<int> _hiddenItems = {};

  @override
  void didUpdateWidget(covariant ItemsRecent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.categoryId != widget.categoryId ||
        oldWidget.entryType != widget.entryType) {
      _hiddenItems.clear();
    }
  }

  Future<void> _openEditModal(ReceiptItem item) async {
    final result = await showModalBottomSheet<ReceiptItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: EditReceiptItemSheet(item: item),
      )
    );

    if (!mounted) return;

    if (result != null) {
      ref.read(transactionControllerProvider).refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved changes'), backgroundColor: Colors.green,)
      );
    }
  }

  Future<void> logoutAndRedirect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ApiClient().clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  String _buildDateLabel(DateTime date) {
    final now = DateTime.now();

    final bool isSameDate = date.year == now.year && date.month == now.month && date.day == now.day;

    final bool isCurrentFilter = widget.selectedMonth == now.month && widget.selectedYear == now.year;

    if (isSameDate && isCurrentFilter) {
      final dateToday = DateFormat('d MMM').format(date);
      return 'Today, ${dateToday}';
    } else {
      final dateNotToday = DateFormat('EEE, d MMM').format(date);
      return dateNotToday;
    }
  }

  Future<void> _handleDelete(ReceiptItem item) async {
    final success = await ref
        .read(transactionControllerProvider)
        .deleteTransaction(item.item_id, item.entryType);

    if (!mounted) return;

    if (success) {
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoryDetailTotalProvider);
      ref.invalidate(categoryTotalsProvider);
      ref.invalidate(summaryProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully')),
      );
    } else {
      setState(() {
        _hiddenItems.remove(item.item_id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("ITEMS RECENT entryType: ${widget.entryType}");
    final asyncItems = ref.watch(transactionsProvider((
      categoryId: widget.categoryId,
      month: widget.selectedMonth,
      year: widget.selectedYear,
      entryType: widget.entryType,
    )));
    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator(),),
      error: (error, stack) {
        return Center(child: Text("Error: $error"),);
      },
      data: (data) {
        
        final visibleData = data.where((item) => !_hiddenItems.contains(item.item_id)).toList();
        if (visibleData.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 78,
                    child: _EmptyTransactionCard(),
                  )
                )
              ],
            ),
          );
        }
        final items = [...visibleData]
          ..sort(
            (a, b) => b.receiptDate.compareTo(a.receiptDate),
          );
          debugPrint(
            "RECENT ITEMS: ${items.map((e) => '${e.item_name}: ${e.total_price} ${e.receiptDate}').toList()}",
          );

          debugPrint("HIDDEN ITEMS: $_hiddenItems");
          debugPrint(
            "RAW RECENT DATA: ${data.map((e) => '${e.item_id} ${e.item_name}: ${e.total_price}').toList()}",
          );

          return Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
          
              // print(item.item_name);
              final DateTime dateOnly = DateUtils.dateOnly(item.receiptDate);
          
              DateTime? previousDate;
          
              if (index > 0) {
                previousDate = DateUtils.dateOnly(items[index - 1].receiptDate);
              }
          
              final bool isFirstOfDay = previousDate == null || previousDate != dateOnly;
          
              double dailyIncome = 0;
              double dailyExpense = 0;
          
              if (isFirstOfDay) {
                final sameDayItems = items.where((i) => DateUtils.dateOnly(i.receiptDate) == dateOnly);
                for (var dayItem in sameDayItems) {
                  if (dayItem.entryType == 'income') {
                    dailyIncome += dayItem.total_price;
                  } else {
                    dailyExpense += dayItem.total_price;
                  }
                }
              }
          
              final String dateLabel = _buildDateLabel(dateOnly);
              final iconData = 
                (item.iconName != null && item.iconName!.isNotEmpty)
                  ? getIconFromKey(item.iconName!)
                  : Icons.category_rounded;
          
              final iconColor =
                (item.colorHex != null && item.colorHex!.isNotEmpty)
                  ? colorFromHex(item.colorHex!)
                  : Colors.grey;
          
              final bool isIncome = item.entryType == 'income';
          
              // final String transactionLabel = isIncome ? 'Income' : 'Expense';
          
              final Color amountColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;
          
              final String amountPrefix = isIncome ? '+' : '-';
          
              return Padding(
                padding: const EdgeInsets.fromLTRB(24,0,24,12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirstOfDay) ... [
                    Text(
                        dateLabel,
                        style: GoogleFonts.prompt(
                          color: Colors.black.withOpacity(0.65),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (widget.categoryId == null) ...[
                        const SizedBox(height: 12,),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.black12.withOpacity(0.05)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          offset: const Offset(0,2),
                                          blurRadius: 6
                                        )
                                      ]
                                    ),
                                    
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Income', style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.green.shade600),),
                                        Text("+${currencyTh.format(dailyIncome)}", style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade600),)
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16,),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.black12.withOpacity(0.05)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          offset: const Offset(0,2),
                                          blurRadius: 6
                                        )
                                      ]
                                    ),
                                    
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Expense', style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.red.shade600),),
                                        Text("-${currencyTh.format(dailyExpense)}", style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade600),),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                      SizedBox(height: 16,),
                    ],
                      Dismissible(
                        key: Key('item_${item.item_id}'), // ใช้ ID รายการเป็น Key
                        direction: DismissDirection.endToStart, // ปัดจากขวาไปซ้าย
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // แจ้งเตือนยืนยัน
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Delete Transaction?', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                              content: Text('Are you sure you want to delete "${item.item_name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true), 
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          setState(() {
                            _hiddenItems.add(item.item_id);
                          });
                          _handleDelete(item);
                        },
                        child: InkWell(
                        onTap:() => _openEditModal(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black12,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                offset: const Offset(0,2),
                                blurRadius: 6
                              )
                            ]
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 19,
                                        backgroundColor: iconColor.withOpacity(0.15),
                                        child: Icon(
                                          iconData,
                                          color: iconColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                        
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.item_name,
                                                    style: GoogleFonts.prompt(
                                                      color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
                                                      fontSize: 16, 
                                                      fontWeight: FontWeight.w700
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  isIncome ? '' :
                                                  " x${item.quantity}",
                                                  style: GoogleFonts.prompt(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                        
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.note ?? '',
                                                    style: GoogleFonts.prompt(
                                                      fontWeight: FontWeight.w400,
                                                      fontSize: 14,
                                                      color: Colors.black54
                                                    ),
                                                    maxLines: 1,                
                                                    overflow: TextOverflow.ellipsis,
                                                    softWrap: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        
                                const SizedBox(width: 12),
                        
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$amountPrefix${currencyTh.format(item.total_price)}',
                                      style: GoogleFonts.prompt(
                                        color: amountColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                        
                                    const SizedBox(height: 4,),
                                    
                                    const Icon(
                                      Icons.chevron_right_outlined,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            }).toList()
          );
        }
      );
      }
  }



class _EmptyTransactionCard extends StatelessWidget {
  const _EmptyTransactionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5)
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined),
                  const SizedBox(width: 15),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("No transactions", style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                      Text("for this period", style: GoogleFonts.prompt(color: Colors.black.withOpacity(0.5))),
                    ],
                  ),
                ],
              ),
              Text(
                "฿0.00",
                style: GoogleFonts.prompt(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}