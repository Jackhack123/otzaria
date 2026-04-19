import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:otzaria/theme/theme_exports.dart';
import 'package:otzaria/widgets/app_menu.dart';

/// רכיב שמציג buttonי action עם יכולת hideה במסכים צרים
/// כשחלק מהbuttons נסתרים, מוצג button "..." שפותח תפריט
///
/// תומך בשני מצבי עבודה:
/// 1. מצב חדש: `actions` + `alwaysInMenu` - buttons נעלמים בorder ההצגה, ותמיד יש תפריט עם buttons constants
/// 2. מצב ישן: `actions` + `originalOrder` - buttons נעלמים לפי עדיפות, תפריט רק אם צריך
class ResponsiveActionBar extends StatefulWidget {
  /// רשימת buttonי הaction.
  /// במצב חדש: order ההצגה (מימין לשמאל ב-RTL)
  /// במצב ישן: order עדיפות (החשוב ביותר ראשון)
  final List<ActionButtonData> actions;

  /// [מצב חדש] buttons שתמיד יהיו בתפריט "..." (גם במסכים רחבים)
  final List<ActionButtonData>? alwaysInMenu;

  /// [מצב ישן] הorder המקורי של הbuttons (לתצוגה עקבית)
  final List<ActionButtonData>? originalOrder;

  /// מbook מקסימלי של buttons להציג לפני מעבר לתפריט "..."
  final int maxVisibleButtons;

  /// האם button "..." יהיה בצד ימין (ברירת מחדל: false - שמאל)
  final bool overflowOnRight;

  /// היסט location לתפריט ה-"..." ביחס לbutton.
  final Offset overflowMenuOffset;

  const ResponsiveActionBar({
    super.key,
    required this.actions,
    this.alwaysInMenu,
    this.originalOrder,
    required this.maxVisibleButtons,
    this.overflowOnRight = false,
    this.overflowMenuOffset = const Offset(0, 4),
  }) : assert(
          alwaysInMenu != null || originalOrder != null,
          'Either alwaysInMenu or originalOrder must be provided',
        );

  @override
  State<ResponsiveActionBar> createState() => _ResponsiveActionBarState();
}

class _ResponsiveActionBarState extends State<ResponsiveActionBar> {
  @override
  Widget build(BuildContext context) {
    // check אם יש buttons בכלל
    final hasAlwaysInMenu =
        widget.alwaysInMenu != null && widget.alwaysInMenu!.isNotEmpty;

    if (widget.actions.isEmpty && !hasAlwaysInMenu) {
      return const SizedBox.shrink();
    }

    // קביעת מצב העבודה
    // New mode is only when originalOrder is NOT provided.
    // If originalOrder is provided, we keep old-mode priority behavior, and
    // allow alwaysInMenu to populate the overflow menu even on wide screens.
    final isNewMode =
        widget.alwaysInMenu != null && widget.originalOrder == null;

    if (isNewMode) {
      return _buildNewMode(context);
    } else {
      return _buildOldMode(context);
    }
  }

  /// מצב חדש: buttons נעלמים בorder ההצגה, תמיד יש תפריט עם buttons constants
  Widget _buildNewMode(BuildContext context) {
    final totalButtons = widget.actions.length;
    int effectiveMaxVisible = widget.maxVisibleButtons;

    // אם צריך להסתיר רק button אחד, אין טעם להציג תפריט שתופס מקום בעצמו.
    // עדיף פשוט להציג את כל הbuttons.
    if (totalButtons - widget.maxVisibleButtons == 1) {
      effectiveMaxVisible = totalButtons;
    }

    List<ActionButtonData> visibleActions;
    List<ActionButtonData> hiddenActions;

    // אם יש מקום לכל הbuttons, נציג את כולם
    if (effectiveMaxVisible >= totalButtons) {
      visibleActions = List.from(widget.actions);
      hiddenActions = [];
    } else {
      // מסתירים buttons מהסוף לתחילה (הימני ביותר יעלם אחרון)
      final numToShow = effectiveMaxVisible;
      visibleActions = widget.actions.take(numToShow).toList();
      hiddenActions = widget.actions.skip(numToShow).toList();
    }

    // תמיד מוסיפים את הbuttons שצריכים להיות בתפריט
    final allHiddenActions = [...hiddenActions, ...widget.alwaysInMenu!];

    final visibleWidgets =
        visibleActions.map((action) => action.widget).toList();
    final List<Widget> children = [];

    // מסך הbook: תפריט בצד שמאל, buttons מימין לשמאל (RTL)
    // תמיד מציגים button "..." אם יש buttons בתפריט
    if (allHiddenActions.isNotEmpty) {
      children.add(_buildOverflowButton(allHiddenActions));
    }
    // הופכים את הorder כך שהbutton הראשון בlist (PDF) יהיה ימני ביותר
    children.addAll(visibleWidgets.reversed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: children,
    );
  }

  /// מצב ישן: buttons נעלמים לפי עדיxxxxxxפריט רק אם צריך
  Widget _buildOldMode(BuildContext context) {
    final totalButtons = widget.originalOrder!.length;
    int effectiveMaxVisible = widget.maxVisibleButtons;

    // אם צריך להסתיר רק button אחד, אין טעם להציג תפריט שתופס מקום בעצמו.
    // עדיף פשוט להציג את כל הbuttons.
    if (totalButtons - widget.maxVisibleButtons == 1) {
      effectiveMaxVisible = totalButtons;
    }

    List<ActionButtonData> visibleActions;
    List<ActionButtonData> hiddenActions;

    // אם יש מקום לכל הbuttons, נציג את כולם ולno תפריט "..."
    if (effectiveMaxVisible >= totalButtons) {
      visibleActions = List.from(widget.originalOrder!);
      hiddenActions = [];
    } else {
      final numToHide = totalButtons - effectiveMaxVisible;

      // ניקח את הbuttons הפחות חשובים מרשימת העדיפויות
      final Set<ActionButtonData> actionsToHide =
          widget.actions.reversed.take(numToHide).toSet();

      visibleActions = [];
      hiddenActions = [];

      // נחלק את הbuttons (לפי הorder המקורי!) לגלויים ונסתרים
      for (final action in widget.originalOrder!) {
        if (actionsToHide.contains(action)) {
          hiddenActions.add(action);
        } else {
          visibleActions.add(action);
        }
      }
    }

    final visibleWidgets =
        visibleActions.map((action) => action.widget).toList();
    final List<Widget> children = [];

    final alwaysInMenu = widget.alwaysInMenu ?? const <ActionButtonData>[];
    final allHiddenActions = [...hiddenActions, ...alwaysInMenu];

    if (widget.overflowOnRight) {
      // מסך the library: תפריט בצד ימין. הorder החזותי R->L דורש היפוך הlist.
      children.addAll(visibleWidgets.reversed);
      if (allHiddenActions.isNotEmpty) {
        children.add(_buildOverflowButton(allHiddenActions));
      }
    } else {
      // תפריט בצד שמאל
      if (allHiddenActions.isNotEmpty) {
        children.add(_buildOverflowButton(allHiddenActions));
      }
      children.addAll(visibleWidgets);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: children,
    );
  }

  Widget _buildOverflowButton(List<ActionButtonData> hiddenActions) {
    // יצירת key ייoverrideי על סמך הbuttons הנסתרים כדי למנוע issues context
    final uniqueKey =
        'overflow_${hiddenActions.map((a) => a.tooltip).join('_')}';

    return Builder(
      key: ValueKey(uniqueKey),
      builder: (context) {
        final menuMetrics = Theme.of(context).extension<AppMenuMetrics>() ??
            AppMenuMetrics.create(compactMenus: false);
        return AppPopupMenuButton<ActionButtonData>(
          icon: const Icon(FluentIcons.more_vertical_24_regular),
          tooltip: 'עוד actions',
          position: PopupMenuPosition.under,
          offset: widget.overflowMenuOffset,
          onSelected: (action) {
            action.onPressed?.call();
          },
          itemBuilder: (context) {
            return hiddenActions.map((action) {
              // אם יש submenuItems, נבנה תת-תפריט
              if (action.submenuItems != null &&
                  action.submenuItems!.isNotEmpty) {
                return buildAppSubmenuPopupMenuItem<ActionButtonData>(
                  context: context,
                  metrics: menuMetrics,
                  label: action.tooltip ?? '',
                  icon: action.icon,
                  menuChildren: action.submenuItems!.map((subAction) {
                    return MenuItemButton(
                      leadingIcon: subAction.icon != null
                          ? Icon(subAction.icon, size: menuMetrics.iconSize)
                          : null,
                      style: buildAppSubmenuItemStyle(context, menuMetrics),
                      onPressed: () {
                        Navigator.of(context).pop(); // סוגר את התפריט הראשי
                        subAction.onPressed?.call();
                      },
                      child: Text(
                        subAction.tooltip ?? '',
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  }).toList(),
                );
              }

              // פריט רגיל לno submenu
              return buildAppPopupMenuItem<ActionButtonData>(
                context,
                AppMenuEntry<ActionButtonData>(
                  value: action,
                  label: action.tooltip ?? '',
                  icon: action.icon,
                  enabled: action.onPressed != null,
                ),
                menuMetrics,
                null,
              );
            }).toList();
          },
        );
      },
    );
  }
}

/// נתוני button action
class ActionButtonData {
  /// הווידג'ט של הbutton
  final Widget widget;

  /// האייקון (לשימוש בתפריט הנOpen)
  final IconData? icon;

  /// הtext להצגה בתפריט הנOpen
  final String? tooltip;

  /// הaction לביצוע כשלוחצים על הbutton בתפריט
  final VoidCallback? onPressed;

  /// רשימת פריטי תת-תפריט (אם קיימת, זה יהיה submenu)
  final List<ActionButtonData>? submenuItems;

  const ActionButtonData({
    required this.widget,
    this.icon,
    this.tooltip,
    this.onPressed,
    this.submenuItems,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionButtonData &&
          runtimeType == other.runtimeType &&
          tooltip == other.tooltip;

  @override
  int get hashCode => tooltip.hashCode;
}
