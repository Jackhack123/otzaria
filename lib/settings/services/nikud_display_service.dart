import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/settings/engine/settings_state.dart';

/// מחזיר האם יש להסיר ניקוד עבור book נתון.
///
/// [defaultRemoveNikud] - האם ברירת המחדל היא להסיר ניקוד.
/// [removeNikudFromTanach] - האם להסיר ניקוד גם מbookי Written Torah.
/// [isTanach] - האם הbook הcurrent שייך לWritten Torah.
bool shouldRemoveNikudForBook({
  required bool defaultRemoveNikud,
  required bool removeNikudFromTanach,
  required bool isTanach,
}) {
  return defaultRemoveNikud && (removeNikudFromTanach || !isTanach);
}

/// מחזיר האם שינוי מצב הsettings מחייב loading again של book open.
bool shouldReloadForNikudSettingsChange({
  required SettingsState previous,
  required SettingsState current,
}) {
  return previous.defaultRemoveNikud != current.defaultRemoveNikud ||
      previous.removeNikudFromTanach != current.removeNikudFromTanach;
}

/// פותר האם להסיר ניקוד עבור book יעד, לפי settings הניקוד והסיווג שלו.
Future<bool> resolveRemoveNikudForBook({
  required String title,
  required bool defaultRemoveNikud,
  required bool removeNikudFromTanach,
  int? categoryId,
  String? fileType,
}) async {
  if (!defaultRemoveNikud) {
    return false;
  }

  final isTanach = await FileSystemData.instance.isTanachBook(
    title,
    categoryId: categoryId,
    fileType: fileType,
  );

  return shouldRemoveNikudForBook(
    defaultRemoveNikud: defaultRemoveNikud,
    removeNikudFromTanach: removeNikudFromTanach,
    isTanach: isTanach,
  );
}
