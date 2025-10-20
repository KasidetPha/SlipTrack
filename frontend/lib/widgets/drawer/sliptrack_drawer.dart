import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum AppLanguage { th, en }

class SliptrackDrawer extends StatelessWidget {
  const SliptrackDrawer({
    super.key,
    required this.displayName,
    required this.email,
    required this.balance,
    this.onScanReceipt,
    this.onAddExpense,
    this.onAddIncome,
    // 🔽 เพิ่มสองพารามิเตอร์นี้เพื่อควบคุม UI toggle
    required this.language,
    required this.onLanguageChanged,
  });

  final String displayName;
  final String email;
  final num balance;

  final VoidCallback? onScanReceipt;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;

  // 🔽 state ภายนอกส่งเข้ามา (แค่ UI เลยใช้ enum กับ callback)
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyTh = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _ProfileHeader(
                displayName: displayName,
                email: email,
                balanceText: currencyTh.format(balance),
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Quick Actions'),
                    _Tile(icon: Icons.document_scanner_rounded, label: "Scan Receipt (OCR)", onTap: onScanReceipt),
                    _Tile(icon: Icons.payments, label: "Add Expense", onTap: onAddExpense),
                    _Tile(icon: Icons.account_balance_wallet_rounded, label: "Add Income", onTap: onAddIncome),

                    const SizedBox(height: 8),
                    const _SectionLabel('Manage'),
                    _Tile(icon: Icons.category_rounded, label: 'Category', onTap: () {}),
                    _Tile(icon: Icons.account_balance_wallet_rounded, label: 'Budget', onTap: () {}),
                    _Tile(icon: Icons.analytics_rounded, label: 'Reports & Analytics', onTap: () {}),

                    const SizedBox(height: 8),
                    const _SectionLabel('App'),

                    // 🔽 Language row + Toggle ด้านขวา
                    _Tile(
                      icon: Icons.language_rounded,
                      label: 'Language',
                      trailing: LanguageToggle(
                        value: language,
                        onChanged: onLanguageChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageToggle extends StatefulWidget {
  const LanguageToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> {
  late AppLanguage _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
  }

  @override
  void didUpdateWidget(covariant LanguageToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _current = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(
            context,
            label: 'TH',
            emoji: '',
            selected: _current == AppLanguage.th,
            onTap: () {
              setState(() => _current = AppLanguage.th);
              widget.onChanged(AppLanguage.th);
            },
          ),
          _pill(
            context,
            label: 'EN',
            emoji: '',
            selected: _current == AppLanguage.en,
            onTap: () {
              setState(() => _current = AppLanguage.en);
              widget.onChanged(AppLanguage.en);
            },
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context,
      {required String label, required String emoji, required bool selected, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.balanceText,
  });

  final String displayName;
  final String email;
  final String balanceText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primary.withOpacity(0.12),
            child: Text(
              'KS',
              style: GoogleFonts.prompt(fontWeight: FontWeight.w700, fontSize: 16, color: cs.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text(email, style: GoogleFonts.prompt(fontSize: 13, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Balance: ', style: GoogleFonts.prompt(fontSize: 13, color: cs.onSurfaceVariant)),
                    Text(balanceText, style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        text,
        style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(label, style: GoogleFonts.prompt(fontSize: 15)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      minLeadingWidth: 28,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
