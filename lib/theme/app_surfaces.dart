import 'package:flutter/material.dart';

/// רקעי מסך לסביבות שימוש שונות באפליקציה
///
/// משמש ליצירת עקביות ויזואלית בין מסכי "לוח" (panel screens):
/// settings, Library, Tools — בניגוד למסך העיון (המסך הראשי).
class AppSurfaces {
  AppSurfaces._();

  /// צבע ברירת המחדל לכרטיסי content באפליקציה.
  ///
  /// תואם לכרטיסי settings ולכרטיסי results בTools:
  /// - מצב כהה: [ColorScheme.surfaceContainer]
  /// - מצב בהיר: [ColorScheme.surface]
  static Color card(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.surface;
  }

  /// רקע מסכי לוח — settings, Library, Tools וכל מסך משני
  ///
  /// מחזיר:
  /// - מצב כהה: שחור מוחלט (כרטיסי SettingsCard בולטים מעליו)
  /// - מצב בהיר: surfaceContainerHighest בשקיפות 28% (טון עדין מעל הרקע הלבן)
  ///
  /// **שימוש:**
  /// ```dart
  /// Scaffold(
  ///   backgroundColor: AppSurfaces.panelBackground(context),
  ///   ...
  /// )
  /// ```
  static Color panelBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black
        : cs.surfaceContainerHighest.withValues(alpha: 0.12);
  }

  /// גרסה אטומה של רקע מסכי הלוח לשימוש בתוך חלוניות/כרטיסים
  /// כך שצבע המסגרת או הרקע שמתחת no ישפיעו על גוון הcontent.
  static Color solidPanelBackground(BuildContext context) {
    final theme = Theme.of(context);
    final color = panelBackground(context);
    return Color.alphaBlend(color, theme.colorScheme.surface);
  }
}
