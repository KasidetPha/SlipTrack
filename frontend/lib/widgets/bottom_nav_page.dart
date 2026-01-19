import 'package:flutter/material.dart';
import 'package:frontend/pages/add_expense_page.dart';
import 'package:frontend/pages/add_income_page.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/profile_page.dart';
import 'package:frontend/pages/scan_page.dart';
import 'package:frontend/widgets/add_entry_sheet.dart';
// import 'package:lucide_icons/lucide_icons.dart';

class BottomNavPage extends StatefulWidget {
  const BottomNavPage({super.key});

  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  int _currentIndex = 0;

  Key _homeKey = UniqueKey();

  Future<void> _onTap(int index) async {
    if (index == 1) {
      await showAddEntrySheet(
        context,
        onIncome: () async {
          // Navigator.pop(context);
          
          final result = await Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddIncomePage())
          );

          if (result == true) {
            setState(() {
              _homeKey = UniqueKey();
              _currentIndex = 0;
            });
          }
        },
        onScan: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage()));
        },
        onExpense: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpensePage()));
        },
        onQuickAction: (label) {
          
        }
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {

    final List<Widget> pages = [
      HomePage(key: _homeKey),
      const SizedBox.shrink(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: false,
      body: pages[_currentIndex],

      floatingActionButton: SizedBox(
        height: 56,
        width: 56,
        child: FloatingActionButton(
          shape: const StadiumBorder(),
          elevation: 6,
          onPressed: () => _onTap(1),
          child: const Icon(Icons.add_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(
                  icon: Icons.home_rounded, 
                  label: 'Home', 
                  selected: _currentIndex == 0, 
                  onTap: () => _onTap(0)
                ),
                SizedBox(width: 56,),
                _NavBtn(
                  icon: Icons.person_rounded, 
                  label: 'Profile', 
                  selected: _currentIndex == 2, 
                  onTap: () => _onTap(2)
                ),
              ],
            ),
          ),
        )
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected 
      ? Theme.of(context).colorScheme.primary
      : Colors.grey[600];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color,),
            const SizedBox(height: 2,),
            Text(label, style: TextStyle(fontSize: 11.5, color: color),)
          ],
        ),
      ),
    );
  }
}