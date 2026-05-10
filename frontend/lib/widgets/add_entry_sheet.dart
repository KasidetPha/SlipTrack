import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showAddEntrySheet(
  BuildContext context, {
  bool hasToken = true,
  VoidCallback? onIncome,
  VoidCallback? onExpense,
  VoidCallback? onScan,
  void Function(String quickLabel)? onQuickAction,
}) async {
  final result = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddEntrySheet(hasToken: hasToken), // ✅ ส่งค่า
  );

  if (result == 'income') onIncome?.call();
  if (result == 'scan') onScan?.call();
  if (result == 'expense') onExpense?.call();
}

class _AddEntrySheet extends StatelessWidget {
  final bool hasToken;

  const _AddEntrySheet({
    super.key,
    required this.hasToken,
  });

  void _showTokenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยังไม่ได้ตั้งค่า API Key'),
        content: const Text(
          'กรุณาเพิ่ม Gemini API Key ในหน้า Profile ก่อนใช้งานสแกนใบเสร็จ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme =
        GoogleFonts.promptTextTheme(Theme.of(context).textTheme);

    Widget actionCard({
      required List<Color> gradient,
      required IconData icon,
      required String title,
      required String returnValue,
      required double width,
      bool disabled = false,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (disabled) {
            _showTokenDialog(context);
            return;
          }
          Navigator.pop(context, returnValue);
        },
        child: Container(
          width: width,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final maxW = constraints.maxWidth - 40;
        final cardWidth = (maxW - spacing * 2) / 3;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Transaction',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Choose what you'd like to add",
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  actionCard(
                    width: cardWidth,
                    gradient: const [
                      Color(0xFF0CC27E),
                      Color(0xFF24B36B)
                    ],
                    icon: Icons.attach_money_rounded,
                    title: "Income",
                    returnValue: 'income',
                  ),
                  const SizedBox(width: 16),

                  /// 🔥 Scan (มี logic)
                  actionCard(
                    width: cardWidth,
                    gradient: hasToken
                        ? const [
                            Color(0xFF4D76FD),
                            Color(0xFF4771FD)
                          ]
                        : [
                            Colors.grey.shade400,
                            Colors.grey.shade300,
                          ],
                    icon: Icons.document_scanner_rounded,
                    title: hasToken
                        ? 'Scan receipt'
                        : 'Scan receipt',
                    returnValue: 'scan',
                    disabled: !hasToken,
                  ),

                  const SizedBox(width: 16),

                  actionCard(
                    width: cardWidth,
                    gradient: const [
                      Color(0xFFFF5E62),
                      Color(0xFFFB2966)
                    ],
                    icon: Icons.receipt_long_rounded,
                    title: 'Expense',
                    returnValue: 'expense',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}