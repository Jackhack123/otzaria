import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// רכיב שמציג כפתורי פעולה עם יכולת הסתרה במסכים צרים
/// כשחלק מהכפתורים נסתרים, מוצג כפתור "..." שפותח תפריט
/// 
/// תומך בשני מצבי עבודה:
/// 1. מצב חדש: `actions` + `alwaysInMenu` - כפתורים נעלמים בסדר ההצגה, ותמיד יש תפריט עם כפתורים קבועים
/// 2. מצב ישן: `actions` + `originalOrder` - כפתורים נעלמים לפי עדיפות, תפריט רק אם צריך
class ResponsiveActionBar extends StatefulWidget {
  /// רשימת כפתורי הפעולה.
  /// במצב חדש: סדר ההצגה (מימין לשמאל ב-RTL)
  /// במצב ישן: סדר עדיפות (החשוב ביותר ראשון)
  final List<ActionButtonData> actions;

  /// [מצב חדש] כפתורים שתמיד יהיו בתפריט "..." (גם במסכים רחבים)
  final List<ActionButtonData>? alwaysInMenu;

  /// [מצב ישן] הסדר המקורי של הכפתורים (לתצוגה עקבית)
  final List<ActionButtonData>? originalOrder;

  /// מספר מקסימלי של כפתורים להציג לפני מעבר לתפריט "..."
  final int maxVisibleButtons;

  /// האם כפתור "..." יהיה בצד ימין (ברירת מחדל: false - שמאל)
  final bool overflowOnRight;

  const ResponsiveActionBar({
    super.key,
    required this.actions,
    this.alwaysInMenu,
    this.originalOrder,
    required this.maxVisibleButtons,
    this.overflowOnRight = false,
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
    // Check if there are any buttons at all
    final hasAlwaysInMenu = widget.alwaysInMenu != null && widget.alwaysInMenu!.isNotEmpty;
    
    if (widget.actions.isEmpty && !hasAlwaysInMenu) {
      return const SizedBox.shrink();
    }

    // Determine operation mode
    final isNewMode = widget.alwaysInMenu != null;

    if (isNewMode) {
      return _buildNewMode(context);
    } else {
      return _buildOldMode(context);
    }
  }

  /// New mode: buttons disappear in display order, always have menu with fixed buttons
  Widget _buildNewMode(BuildContext context) {
    final totalButtons = widget.actions.length;
    int effectiveMaxVisible = widget.maxVisibleButtons;

    // If only need to hide one button, no point showing menu that takes space.
    // Better to just show all buttons.
    if (totalButtons - widget.maxVisibleButtons == 1) {
      effectiveMaxVisible = totalButtons;
    }

    List<ActionButtonData> visibleActions;
    List<ActionButtonData> hiddenActions;

    // If there is room for all buttons, show them all
    if (effectiveMaxVisible >= totalButtons) {
      visibleActions = List.from(widget.actions);
      hiddenActions = [];
    } else {
      // Hiding buttons from end to start (הימני ביותר יעלם אחרון)
      final numToShow = effectiveMaxVisible;
      visibleActions = widget.actions.take(numToShow).toList();
      hiddenActions = widget.actions.skip(numToShow).toList();
    }

    // Always add buttons that should be in menu
    final allHiddenActions = [...hiddenActions, ...widget.alwaysInMenu!];

    final visibleWidgets =
        visibleActions.map((action) => action.widget).toList();
    final List<Widget> children = [];

    // Book screen: menu on left, buttons right to left (RTL)
    // תמיד מציגים כפתור "..." אם יש כפתורים בתפריט
    if (allHiddenActions.isNotEmpty) {
      children.add(_buildOverflowButton(allHiddenActions));
    }
    // הופכים את הסדר כך שהכפתור הראשון ברשימה (PDF) יהיה ימני ביותר
    children.addAll(visibleWidgets.reversed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: children,
    );
  }

  /// מצב ישן: כפתורים נעלמים לפי עדיxxxxxxפריט רק אם צריך
  Widget _buildOldMode(BuildContext context) {
    final totalButtons = widget.originalOrder!.length;
    int effectiveMaxVisible = widget.maxVisibleButtons;

    // If only need to hide one button, no point showing menu that takes space.
    // Better to just show all buttons.
    if (totalButtons - widget.maxVisibleButtons == 1) {
      effectiveMaxVisible = totalButtons;
    }

    List<ActionButtonData> visibleActions;
    List<ActionButtonData> hiddenActions;

    // If there is room for all buttons, show them all וללא תפריט "..."
    if (effectiveMaxVisible >= totalButtons) {
      visibleActions = List.from(widget.originalOrder!);
      hiddenActions = [];
    } else {
      final numToHide = totalButtons - effectiveMaxVisible;

      // ניקח את הכפתורים הפחות חשובים מרשימת העדיפויות
      final Set<ActionButtonData> actionsToHide =
          widget.actions.reversed.take(numToHide).toSet();

      visibleActions = [];
      hiddenActions = [];

      // נחלק את הכפתורים (לפי הסדר המקורי!) לגלויים ונסתרים
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

    if (widget.overflowOnRight) {
      // Library screen: menu on right. Visual order R->L requires reversing list.
      children.addAll(visibleWidgets.reversed);
      if (hiddenActions.isNotEmpty) {
        children.add(_buildOverflowButton(hiddenActions));
      }
    } else {
      // Menu on left side
      if (hiddenActions.isNotEmpty) {
        children.add(_buildOverflowButton(hiddenActions));
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
    // Create unique key על סמך הכפתורים הנסתרים To prevent context issues
    final uniqueKey = 'overflow_${hiddenActions.map((a) => a.tooltip).join('_')}';

    return Builder(
      key: ValueKey(uniqueKey),
      builder: (context) {
        return PopupMenuButton<ActionButtonData>(
          icon: const Icon(FluentIcons.more_vertical_24_regular),
          tooltip: 'More actions',
          // הוספת offset כדי למקם את התפריט מתחת לכפתור
          offset: const Offset(0, 40.0),
          onSelected: (action) {
            action.onPressed?.call();
          },
          itemBuilder: (context) {
            return hiddenActions.map((action) {
              return PopupMenuItem<ActionButtonData>(
                value: action,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (action.icon != null) ...[
                      Icon(action.icon),
                      const SizedBox(width: 8),
                    ],
                    Text(action.tooltip ?? ''),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}

/// נתוני כפתור פעולה
class ActionButtonData {
  /// הווידג'ט של הכפתור
  final Widget widget;

  /// האייקון (לשימוש בתפריט הנפתח)
  final IconData? icon;

  /// הטקסט להצגה בתפריט הנפתח
  final String? tooltip;

  /// הפעולה לביצוע כשלוחצים על הכפתור בתפריט
  final VoidCallback? onPressed;

  const ActionButtonData({
    required this.widget,
    this.icon,
    this.tooltip,
    this.onPressed,
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
