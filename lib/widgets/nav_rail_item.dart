// lib/widgets/nav_rail_item.dart
//
// NavRailItem — button ניווט אנכי בסגנון Material 3.
//
// מממש את הסגנון של _buildNavButton ב-MainWindowScreen:
//  • אייקון (24px) מעל תווית
//  • Active Indicator: AnimatedContainer + AnimatedScale → secondaryContainer pill
//  • AnimatedSwitcher להחלפת regular ↔ filled
//  • AnimatedDefaultTextStyle noנימציית צבע הtext
//  • תמיכה ב-Tooltip לקיצורי מקלדת
//
// **שימוש:**
// ```dart
// NavRailItem(
//   icon: FluentIcons.library_24_regular,
//   iconFilled: FluentIcons.library_24_filled,
//   label: 'library',
//   isSelected: _currentIndex == 0,
//   onTap: () => _navigate(0),
//   tooltip: 'Ctrl+L',
// )
// ```

import 'package:flutter/material.dart';

class NavRailItem extends StatelessWidget {
  /// אייקון רגיל (כשno selected)
  final IconData icon;

  /// אייקון filled (כשselected) — אופציונלי
  final IconData? iconFilled;

  /// תווית מתחת noייקון
  final String label;

  /// האם פריט זה selected
  final bool isSelected;

  /// Callback בעת tap
  final VoidCallback onTap;

  /// text Tooltip (לרוב קיצור מקלדת) — אופציונלי
  final String? tooltip;

  const NavRailItem({
    super.key,
    required this.icon,
    this.iconFilled,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ── אייקון עם אנימציה regular ↔ filled ──────────────────────────────
    Widget iconWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOutCubicEmphasized,
      switchOutCurve: Curves.easeInOutCubicEmphasized,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Icon(
        isSelected && iconFilled != null ? iconFilled! : icon,
        key: ValueKey<bool>(isSelected),
        size: 24,
        color: isSelected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
      ),
    );

    if (tooltip != null) {
      iconWidget = Tooltip(
        preferBelow: false,
        message: tooltip!,
        child: iconWidget,
      );
    }

    return SizedBox(
      width: 74,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Active Indicator ────────────────────────────────────────
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.95,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubicEmphasized,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: onTap,
                  icon: iconWidget,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(56, 25),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // ── תווית ──────────────────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? cs.onSecondaryContainer
                    : cs.onSurfaceVariant,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
