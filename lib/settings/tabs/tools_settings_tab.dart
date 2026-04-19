import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/tools/calendar/ulits/calendar_cubit.dart';
import 'package:otzaria/settings/panels/settings_panels_exports.dart';

/// טאב Tools — לוח year, גימטריות, עורך.
///
/// [calendarCubit] — העברה מפורשת של CalendarCubit כדי לתקן את nextג שבו
/// settings לוח הyear no נשמרות כאשר הsettings נOpenות כ-route חדש (ה-context
/// של המסך החדש no מכיל את ה-CalendarCubit ממסך הניווט).
class ToolsSettingsTab extends StatelessWidget {
  /// CalendarCubit שמגיע מה-context של המסך שOpen את הsettings.
  /// אם null, מנסה לקרוא מה-context (תואמות noחור).
  final CalendarCubit? calendarCubit;

  const ToolsSettingsTab({super.key, this.calendarCubit});

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      primary: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          CalendarSettingsTab(),
          GematriaSettingsTab(),
          // [EDITING DISABLED] EditorSettingsTab(),
          SizedBox(height: 16),
        ],
      ),
    );

    // אם קיבלנו CalendarCubit במפורש — עטוף כדי להבטיח שהשינויים יישמרו
    if (calendarCubit != null) {
      return BlocProvider<CalendarCubit>.value(
        value: calendarCubit!,
        child: content,
      );
    }

    return content;
  }
}
