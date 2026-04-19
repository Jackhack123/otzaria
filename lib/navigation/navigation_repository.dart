import 'dart:io';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/constants/database_constants.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/settings/settings_exports.dart';

class NavigationRepository {
  /// בודק אם the library emptyה - כלומר אם file seforim.db no קיים
  bool checkLibraryIsEmpty() {
    final libraryPath =
        Settings.getValue<String>(SettingsRepository.keyLibraryPath);

    if (libraryPath == null || libraryPath.isEmpty) {
      return true;
    }

    // check שfile seforim.db קיים בpath המתאים
    final databasePath = DatabaseConstants.getDatabasePath();
    final databaseFile = File(databasePath);

    if (!databaseFile.existsSync()) {
      return true;
    }

    // Android: גם אם הfile "קיים" (stat עובד), ייתyes שה-native sqlite3
    // no יכול לopen אותו מאחסון Scoped Storage חיצוני.
    // אם אין keyDbEffectivePath, המשמעות היא שה-flow no הושלם — נחזיר true
    // כדי שהuser יגיע למסך הבחירה עם הדיאלוג המתאים.
    if (Platform.isAndroid && !_isNativeAccessible(databasePath)) {
      final effectivePath =
          Settings.getValue<String>(SettingsRepository.keyDbEffectivePath) ??
              '';
      if (effectivePath.isEmpty) {
        return true;
      }
    }

    return false;
  }

  /// בודק אם path נגיש ל-sqlite3 native ב-Android.
  static bool _isNativeAccessible(String filePath) {
    if (filePath.startsWith('/data/')) return true;
    if (filePath.contains('/Android/data/')) return true;
    if (filePath.contains('/Android/obb/')) return true;
    return false;
  }

  Future<void> refreshLibrary() async {
    // טעינת the library again
    final libraryPath =
        Settings.getValue<String>(SettingsRepository.keyLibraryPath);
    if (libraryPath != null) {
      // update path the library
      FileSystemData.instance.libraryPath = libraryPath;

      // טעינת the library again
      DataRepository.instance.library = FileSystemData.instance.getLibrary();
      DataRepository.instance.invalidateExternalBooksCache();

      // פתיחה again של אינדקס הsearch
      try {
        await TantivyDataProvider.instance.reopenIndex();
      } catch (e) {
        // Continue without search index if it fails
      }
    }
  }
}