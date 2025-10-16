import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.title = 'SlipTrack',
    this.onMenuTap,
    this.useEndDrawer = false,
    this.actions,
  });

  final String title;
  final VoidCallback? onMenuTap;
  final bool useEndDrawer;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final onPrimary = Colors.white;
    final menuBg = Colors.black.withOpacity(0.10);

    void openDrawerDefault() {
      final scaffoldState = Scaffold.maybeOf(context);
      if (scaffoldState == null) return;
      if (useEndDrawer) {
        scaffoldState.openEndDrawer();
      } else {
        scaffoldState.openDrawer();
      }
      HapticFeedback.selectionClick();
    }
    
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Tooltip(
                message: useEndDrawer ? 'Open menu (right)' : 'Open menu',
                child: InkWell(
                  onTap: onMenuTap ?? openDrawerDefault,
                  // radius: 28,
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    backgroundColor: menuBg,
                    child: const Icon(Icons.menu_rounded, size: 24, color: Colors.white,),
                  ),
                ),
              )
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                    height: 1.1
                  )
                ),
              ),
            ),
            SizedBox(
              width: 48, 
              height: 48, 
              child: (actions == null || actions!.isEmpty)
                ? const SizedBox.shrink()
                : Center(child: _ActionWrap(children: actions!),)
            )
          ],
        ),
      ),
    );
  }
}

class _ActionWrap extends StatelessWidget {
  const _ActionWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: children
        .map((w) => Padding(padding: const EdgeInsets.only(left: 4), 
        child: SizedBox(height: 48, child: Center(child: w,)),
      ))
        .toList(),
    );
  }
}