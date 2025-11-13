import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showAddEntrySheet(
  BuildContext context, {
    VoidCallback? onIncome,
    VoidCallback? onExpense,
    VoidCallback? onScan,
    void Function(String quickLabel)? onQuickAction
}) async {
  final result = await showModalBottomSheet(
    context: context, 
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))
    ),
    builder: (_) => const _AddEntrySheet()
  );

  if (result == 'income') onIncome?.call();
  if (result == 'scan') onScan?.call();
  if (result == 'expense') onExpense?.call();
  if (result is String && result.startsWith('quick:')) {
    onQuickAction?.call(result.replaceFirst('quick:', ''));
  }
}

class _AddEntrySheet extends StatelessWidget {
  const _AddEntrySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.promptTextTheme(Theme.of(context).textTheme);

    Widget actionCard({
      required List<Color> gradient,
      required IconData icon,
      required String title,
      required String returnValue,
      required double width
    }) {
      return Semantics(
        button: true,
        label: title,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            focusColor: Colors.white.withOpacity(0.14),
            highlightColor: Colors.white.withOpacity(0.06),
            onTap: () => Navigator.pop(context, returnValue),
            child: Container(
              width: width,
              height: 140,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: const Offset(0,8)
                  )
                ]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(height: 10,),
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 15
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      );
    }

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 16.0;
          final contentPadding = 40.0;
          final maxW = constraints.maxWidth - contentPadding;
          final isThreeCols = constraints.maxWidth >= 360;
          final cols = isThreeCols ? 3 : 2;
          final cardWidth = (maxW - spacing * (cols - 1)) / cols;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 24
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('New Transaction',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, letterSpacing: 0.2
                ),),
                const SizedBox(height: 4,),
                Text("Choose what you'd like to add",
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black54
                ),),
                const SizedBox(height: 16,),
                  
                Row(
                  children: [
                    actionCard(
                      width: cardWidth,
                      gradient: const [Color(0xFF0CC27E), Color(0xFF24B36B)], 
                      icon: Icons.attach_money_rounded, 
                      title: "Income", 
                      returnValue: 'income'
                    ),
                    const SizedBox(width: 16,),
                    actionCard(
                      width: cardWidth,
                      gradient: const [Color.fromARGB(255, 77, 118, 253), Color.fromARGB(255, 71, 113, 253)], 
                      icon: Icons.document_scanner_rounded, 
                      title: 'Scan receipt', 
                      returnValue: 'scan'
                    ),
                    const SizedBox(width: 16,),
                    actionCard(
                      width: cardWidth,
                      gradient: const [Color(0xFFFF5E62), Color(0xFFFB2966)], 
                      icon: Icons.receipt_long_rounded, 
                      title: 'Expense', 
                      returnValue: 'expense'
                    )
                  ],
                )
              ],
            ),
          );
        }
      ),
    );
  }
}