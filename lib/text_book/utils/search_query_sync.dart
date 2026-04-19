import 'package:flutter/material.dart';

/// מסנכרנת שאילתת search אל [controller] בלי לדרוס בחירה קיימת
/// כאשר הtext כבר תואם לvalue המבוקש.
void syncSearchControllerQuery(
  TextEditingController controller,
  String query,
) {
  if (controller.text == query) {
    return;
  }

  controller.value = controller.value.copyWith(
    text: query,
    selection: TextSelection.collapsed(offset: query.length),
    composing: TextRange.empty,
  );
}

/// מחילה שאילתת search שמגיעה ממסלול פרוגרמטי, כגון search מתקדם,
/// ומסנכרנת גם את ה-state החיצוני דרך [onQueryChanged].
void applyInBookSearchQuery({
  required TextEditingController controller,
  required String query,
  required ValueChanged<String> onQueryChanged,
}) {
  syncSearchControllerQuery(controller, query);
  onQueryChanged(query);
}
