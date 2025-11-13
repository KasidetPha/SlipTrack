import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ScanBody extends StatefulWidget {
  const ScanBody({super.key});

  @override
  State<ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends State<ScanBody> {
  // ====== Mock data: เรียกใช้กับ modal (UI เท่านั้น) ======
  final _items = <ReceiptScanResult>[
    ReceiptScanResult(
      title: 'H FHขนมปังชนิดแผ่น',
      icon: Icons.restaurant, iconBg: const Color(0xFFE67E22),
      date: DateTime(2025, 10, 19),
      qty: 1, amount: -40.00,
    ),
    ReceiptScanResult(
      title: 'H นมถั่วเหลือง UHT',
      icon: Icons.restaurant, iconBg: const Color(0xFFE67E22),
      date: DateTime(2025, 10, 19),
      qty: 1, amount: -15.00,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: const Radius.circular(12),
              strokeWidth: 2.5,
              dashPattern: const [15, 5],
              padding: EdgeInsets.zero,
              color: Colors.grey.withOpacity(0.8),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 300,
            ),
            // child: Container(
            //   decoration: BoxDecoration(
            //     color: Colors.grey.withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   padding: const EdgeInsets.symmetric(vertical: 48),
            //   width: double.infinity,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.all(15),
            //         decoration: BoxDecoration(
            //           color: Colors.blue.shade100,
            //           borderRadius: BorderRadius.circular(50),
            //         ),
            //         child: const Icon(
            //           Icons.photo_camera_outlined,
            //           color: Color(0xFF2563EB),
            //           size: 48,
            //         ),
            //       ),
            //       const SizedBox(height: 24),
            //       Text(
            //         "Photo or Select receipt",
            //         style: GoogleFonts.prompt(
            //             fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
            //       ),
            //       const SizedBox(height: 12),
            //       Text(
            //         "Take a clear photo of the slip for best results.",
            //         style: GoogleFonts.prompt(
            //             fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.5)),
            //       ),
            //       const SizedBox(height: 24),
            //       Padding(
            //         padding: const EdgeInsets.symmetric(horizontal: 24),
            //         child: InkWell(
            //           onTap: () {
            //             // TODO: เรียกกล้องจริง
            //             _showScanResultSheet(context, _items);
            //           },
            //           child: Container(
            //             decoration: BoxDecoration(
            //               color: const Color(0xFF2563EB),
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //             alignment: Alignment.center,
            //             padding: const EdgeInsets.all(12),
            //             width: double.infinity,
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 24),
            //                 const SizedBox(width: 12),
            //                 Text("Photo",
            //                     style: GoogleFonts.prompt(
            //                         color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       const SizedBox(height: 12),
            //       Padding(
            //         padding: const EdgeInsets.symmetric(horizontal: 24),
            //         child: InkWell(
            //           onTap: () {
            //             // TODO: เปิดแกลเลอรี่จริง
            //             _showScanResultSheet(context, _items);
            //           },
            //           child: Container(
            //             decoration: BoxDecoration(
            //               color: Colors.white,
            //               borderRadius: BorderRadius.circular(12),
            //               border: Border.all(color: Colors.grey.shade300),
            //             ),
            //             alignment: Alignment.center,
            //             padding: const EdgeInsets.all(12),
            //             width: double.infinity,
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 const Icon(Icons.image, color: Colors.black, size: 24),
            //                 const SizedBox(width: 12),
            //                 Text("Select from Gallery",
            //                     style: GoogleFonts.prompt(
            //                         color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15)),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ),
          const SizedBox(height: 24),
          const _Tips(),
        ],
      ),
    );
  }

  // ====== UI: Modal Bottom Sheet (Scan Results) ======
  Future<void> _showScanResultSheet(BuildContext context, List<ReceiptScanResult> items) async {
    final currency = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    final dateFmt = DateFormat('dd/MM/yyyy');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) {
            final cs = Theme.of(ctx).colorScheme;
            return Column(
              children: [
                const SizedBox(height: 8),
                // drag handle
                Container(
                  width: 48, height: 5,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant, borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 12),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scan receipt',
                                style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text('รายการที่ตรวจพบจากสลิป',
                                style: GoogleFonts.prompt(
                                    fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Text('${items.length}',
                          style: GoogleFonts.prompt(
                              fontWeight: FontWeight.w800, fontSize: 16, color: cs.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                // List
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return _ReceiptTile(
                        icon: it.icon,
                        iconBg: it.iconBg,
                        title: it.title,
                        qtyText: 'x${it.qty}',
                        dateText: dateFmt.format(it.date),
                        amountText: currency.format(it.amount.abs()),
                        isExpense: it.amount < 0,
                        onTap: () {
                          // TODO: เปิดหน้าแก้ไขรายการ (UI-only ตอนนี้)
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: items.length,
                  ),
                ),
                // Bottom actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      // Expanded(
                      //   child: OutlinedButton.icon(
                      //     onPressed: () {
                      //       // TODO: ไปหน้าแก้ไขทั้งหมด
                      //     },
                      //     icon: const Icon(Icons.edit_outlined),
                      //     label: Text('Edit all', style: GoogleFonts.prompt()),
                      //     style: OutlinedButton.styleFrom(
                      //       padding: const EdgeInsets.symmetric(vertical: 14),
                      //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            // TODO: Save/Confirm (เรียก API จริงภายหลัง)
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: Text('Save', style: GoogleFonts.prompt(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ====== Tiles & Models ======

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.qtyText,
    required this.dateText,
    required this.amountText,
    required this.isExpense,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String qtyText;
  final String dateText;
  final String amountText;
  final bool isExpense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.onSurface.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
            border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // บรรทัดแรก: title + x1 + amount
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isExpense ? '-$amountText' : amountText,
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // บรรทัดสอง: date + x1
                    Row(
                      children: [
                        Text(dateText,
                            style: GoogleFonts.prompt(fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Text(qtyText,
                            style: GoogleFonts.prompt(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiptScanResult {
  final String title;
  final IconData icon;
  final Color iconBg;
  final DateTime date;
  final int qty;
  final num amount; // ติดลบ = รายจ่าย
  ReceiptScanResult({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.date,
    required this.qty,
    required this.amount,
  });
}

// ====== Tips Box (เดิม) ======
class _Tips extends StatelessWidget {
  const _Tips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Colors.amber),
              const SizedBox(width: 12),
              Text("Tips for a better scan",
                  style: GoogleFonts.prompt(
                      fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A))),
            ],
          ),
          const SizedBox(height: 12),
          Text('- Good lighting',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
          Text('- Full receipt in frame',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
          Text('- No shadows or glare',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
        ]),
      ),
    );
  }
}
