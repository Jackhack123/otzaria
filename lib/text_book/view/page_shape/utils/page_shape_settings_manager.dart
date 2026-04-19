import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/text_book/view/page_shape/utils/page_shape_commentary_selection.dart';

/// admin settings צורת הpage - שומר ומטעין את בחירת הCommentators
/// תומך בsettings גלובליות, settings פר-category, וsettings פר-book (override)
///
/// order עדיפות בloading: book specific → category → ברירת מחדל (JSON)
class PageShapeSettingsManager {
  // keys גלובליים (לsettings תצוגה בלבד - no לCommentators!)
  static const String _globalHighlightKey = 'page_shape_global_highlight';
  static const String _globalVisibilityPrefix = 'page_shape_global_visibility_';
  static const String _commentaryFontSizeKey =
      'page_shape_commentary_font_size';

  // keys פר-book
  static const String _bookConfigPrefix = 'page_shape_book_';
  static const String _bookHighlightPrefix = 'page_shape_highlight_';
  static const String _bookVisibilityPrefix = 'page_shape_visibility_';
  static const String _useBookSettingsPrefix = 'page_shape_use_book_settings_';
  static const String _bookViewModePrefix = 'page_shape_view_mode_';

  // keys פר-category (חדש!)
  static const String _categoryConfigPrefix = 'page_shape_category_';

  static const double defaultCommentaryFontSize = 16.0;

  // categories generalות מדי שno כדאי לSave עליהן settings
  static const List<String> _tooGeneralCategories = [
    'Otzaria',
    'הלכה',
    'מדרש',
    'Written Torah',
    'Talmud',
    'קבלה',
    'מוסר',
    'מחשבה',
    'שו"ת',
  ];

  // ==================== עזר לcategories ====================

  /// חילוץ רשימת categories מ-heCategories (מסנן categories generalות מדי)
  /// למשל: "הלכה, מyear תורה, book מדע" → ["מyear תורה", "book מדע"]
  /// אם אין categories אחרי הסינון, מחזיר את כל הcategories (כולל הgeneralות)
  static List<String> parseCategories(String? heCategories) {
    if (heCategories == null || heCategories.isEmpty) {
      return [];
    }
    final allCategories = heCategories
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final filtered =
        allCategories.where((c) => !_tooGeneralCategories.contains(c)).toList();

    // אם הסינון הסיר הכל, החזר את הcategories המקוריות
    return filtered.isNotEmpty ? filtered : allCategories;
  }

  /// קבלת קטגוריית האב הראשית (למשל "מyear תורה" מתוך "הלכה, מyear תורה, book מדע")
  static String? getParentCategory(String? heCategories) {
    final categories = parseCategories(heCategories);
    // מחזיר את הcategory הראשונה (אחרי סינון הgeneralות)
    if (categories.isNotEmpty) {
      return categories[0]; // למשל "מyear תורה"
    }
    return null;
  }

  /// חילוץ name בסיסי של commentator (בלי "על X")
  /// למשל: "רמב"ן על ברכות" → "רמב"ן"
  /// למשל: "השגות הראב"ד על מyear תורה, הלכות דעות" → "השגות הראב"ד"
  static String? extractBaseCommentatorName(String? fullName) {
    if (fullName == null) return null;

    // מחפשים "על " ולוקחים את מה שלפניו
    final onIndex = fullName.indexOf(' על ');
    if (onIndex > 0) {
      return fullName.substring(0, onIndex).trim();
    }

    // אם אין "על", מחזירים את הname כמו שהוא
    return fullName;
  }

  // ==================== גודל גופן (גלובלי בלבד) ====================

  /// save גודל גופן הCommentators (setting גלובלית)
  static Future<void> saveCommentaryFontSize(double size) async {
    await Settings.setValue<double>(_commentaryFontSizeKey, size);
  }

  /// טעינת גודל גופן הCommentators
  static double getCommentaryFontSize() {
    return Settings.getValue<double>(_commentaryFontSizeKey) ??
        defaultCommentaryFontSize;
  }

  // ==================== check אם יש settings פר-book ====================

  /// check אם הbook user בsettings פר-book
  static bool hasBookSpecificSettings(String bookTitle) {
    return Settings.getValue<bool>('$_useBookSettingsPrefix$bookTitle') ??
        false;
  }

  /// Enableה/כיבוי של settings פר-book
  static Future<void> setUseBookSpecificSettings(
      String bookTitle, bool useBookSettings) async {
    await Settings.setValue<bool>(
        '$_useBookSettingsPrefix$bookTitle', useBookSettings);
  }

  // ==================== settings Commentators ====================

  /// טעינת settings Commentators - previous book, אחר כך category
  /// order עדיפות: book specific → category → null (יטען מ-JSON)
  static Map<String, String?>? loadConfiguration(String bookTitle,
      {String? heCategories}) {
    // 1. previous בודקים אם יש settings לbook הspecific
    final bookConfig = _loadBookConfiguration(bookTitle);
    if (bookConfig != null) {
      return bookConfig;
    }

    // 2. אם אין, בודקים אם יש settings לcategory
    if (heCategories != null) {
      final categoryConfig = _loadCategoryConfiguration(heCategories);
      if (categoryConfig != null) {
        return categoryConfig;
      }
    }

    // 3. אם אין - מחזירים null (יטען מ-JSON)
    return null;
  }

  /// טעינת settings פר-book
  static Map<String, String?>? _loadBookConfiguration(String bookTitle) {
    final savedConfig =
        Settings.getValue<String>('$_bookConfigPrefix$bookTitle');
    return _parseConfiguration(savedConfig);
  }

  /// טעינת settings פר-category
  static Map<String, String?>? _loadCategoryConfiguration(String heCategories) {
    final categories = parseCategories(heCategories);

    // מחפשים מהcategory הspecificת ביותר לgeneral ביותר
    // למשל: "book מדע" → "מyear תורה" → "הלכה"
    for (int i = categories.length - 1; i >= 0; i--) {
      final category = categories[i];
      final savedConfig =
          Settings.getValue<String>('$_categoryConfigPrefix$category');
      final config = _parseConfiguration(savedConfig);
      if (config != null) {
        return config;
      }
    }

    return null;
  }

  /// check אם יש settings לcategory מסוימת
  static bool hasCategorySettings(String category) {
    final savedConfig =
        Settings.getValue<String>('$_categoryConfigPrefix$category');
    return savedConfig != null && savedConfig.isNotEmpty;
  }

  /// קבלת הcategory שממנה נטענו הsettings (אם יש)
  static String? getActiveCategory(String? heCategories) {
    if (heCategories == null) return null;

    final categories = parseCategories(heCategories);
    for (int i = categories.length - 1; i >= 0; i--) {
      final category = categories[i];
      if (hasCategorySettings(category)) {
        return category;
      }
    }
    return null;
  }

  /// פענוח מחרוזת settings
  static Map<String, String?>? _parseConfiguration(String? savedConfig) {
    if (savedConfig == null) {
      return null;
    }

    final parts = savedConfig.split('||');
    final config = <String, String?>{};

    for (final part in parts) {
      final keyValue = part.split('|');
      if (keyValue.length == 2) {
        final key = keyValue[0];
        final value = keyValue[1] == 'null' ? null : keyValue[1];
        config[key] = value;
      }
    }

    return config;
  }

  /// save settings Commentators - לbook או לcategory
  static Future<void> saveConfiguration(
    String bookTitle,
    Map<String, String?> config, {
    String? saveToCategory, // אם מוגדר - שומר לcategory במקום לbook
  }) async {
    if (saveToCategory != null) {
      // save לcategory - שומרים רק את הnames הבסיסיים של הCommentators
      final baseConfig = config.map((key, value) {
        if (isPageShapeRemainingCommentatorsValue(value) ||
            value == pageShapeMultipleCommentatorsModeValue) {
          return MapEntry(key, value);
        }

        return MapEntry(
          key,
          encodePageShapeCommentatorsSelection(
            decodePageShapeCommentatorsSelection(value)
                .map(extractBaseCommentatorName)
                .whereType<String>(),
            forceMultipleMode: isPageShapeMultipleCommentatorsMode(value),
          ),
        );
      });
      final configString = _serializeConfiguration(baseConfig);
      await Settings.setValue<String>(
          '$_categoryConfigPrefix$saveToCategory', configString);
    } else {
      // save לbook specific - שומרים את הnames הfullים
      final configString = _serializeConfiguration(config);
      await Settings.setValue<String>(
          '$_bookConfigPrefix$bookTitle', configString);
    }
  }

  /// המרת settings למחרוזת
  static String _serializeConfiguration(Map<String, String?> config) {
    final parts = <String>[];
    config.forEach((key, value) {
      parts.add('$key|${value ?? 'null'}');
    });
    return parts.join('||');
  }

  // ==================== הגדרת הדגשה ====================

  /// טעינת הגדרת הדגשה - previous פר-book, אחר כך גלובלי
  static bool getHighlightSetting(String bookTitle) {
    if (hasBookSpecificSettings(bookTitle)) {
      final bookSetting =
          Settings.getValue<bool>('$_bookHighlightPrefix$bookTitle');
      if (bookSetting != null) {
        return bookSetting;
      }
    }
    return Settings.getValue<bool>(_globalHighlightKey) ?? false;
  }

  /// save הגדרת הדגשה
  static Future<void> saveHighlightSetting(
    String bookTitle,
    bool enabled, {
    bool saveAsGlobal = true,
  }) async {
    if (saveAsGlobal) {
      await Settings.setValue<bool>(_globalHighlightKey, enabled);
    } else {
      await Settings.setValue<bool>('$_bookHighlightPrefix$bookTitle', enabled);
      await setUseBookSpecificSettings(bookTitle, true);
    }
  }

  // ==================== settings הצגת טורים ====================

  /// טעינת settings הצגת טורים - previous פר-book, אחר כך גלובלי
  static Map<String, bool> getColumnVisibility(String bookTitle) {
    if (hasBookSpecificSettings(bookTitle)) {
      final bookVisibility = _getBookColumnVisibility(bookTitle);
      if (bookVisibility != null) {
        return bookVisibility;
      }
    }
    return _getGlobalColumnVisibility();
  }

  static Map<String, bool> _getGlobalColumnVisibility() {
    return {
      'left': Settings.getValue<bool>('${_globalVisibilityPrefix}left') ?? true,
      'right':
          Settings.getValue<bool>('${_globalVisibilityPrefix}right') ?? true,
      'bottom':
          Settings.getValue<bool>('${_globalVisibilityPrefix}bottom') ?? true,
    };
  }

  static Map<String, bool>? _getBookColumnVisibility(String bookTitle) {
    final left =
        Settings.getValue<bool>('${_bookVisibilityPrefix}left_$bookTitle');
    final right =
        Settings.getValue<bool>('${_bookVisibilityPrefix}right_$bookTitle');
    final bottom =
        Settings.getValue<bool>('${_bookVisibilityPrefix}bottom_$bookTitle');

    // אם אף אחד no הוגדר, החזר null
    if (left == null && right == null && bottom == null) {
      return null;
    }

    return {
      'left': left ?? true,
      'right': right ?? true,
      'bottom': bottom ?? true,
    };
  }

  /// save settings הצגת טורים
  static Future<void> saveColumnVisibility(
    String bookTitle,
    Map<String, bool> visibility, {
    bool saveAsGlobal = true,
  }) async {
    if (saveAsGlobal) {
      await Settings.setValue<bool>(
          '${_globalVisibilityPrefix}left', visibility['left'] ?? true);
      await Settings.setValue<bool>(
          '${_globalVisibilityPrefix}right', visibility['right'] ?? true);
      await Settings.setValue<bool>(
          '${_globalVisibilityPrefix}bottom', visibility['bottom'] ?? true);
    } else {
      await Settings.setValue<bool>('${_bookVisibilityPrefix}left_$bookTitle',
          visibility['left'] ?? true);
      await Settings.setValue<bool>('${_bookVisibilityPrefix}right_$bookTitle',
          visibility['right'] ?? true);
      await Settings.setValue<bool>('${_bookVisibilityPrefix}bottom_$bookTitle',
          visibility['bottom'] ?? true);
      await setUseBookSpecificSettings(bookTitle, true);
    }
  }

  // ==================== העדפת תצוגה (page shape view) ====================

  /// save העדפת תצוגה לbook - האם לopen בתצוגת צורת הpage
  static Future<void> saveViewModePreference(
      String bookTitle, bool showPageShapeView) async {
    await Settings.setValue<bool>(
        '$_bookViewModePrefix$bookTitle', showPageShapeView);
  }

  /// טעינת העדפת תצוגה לbook - מחזיר null אם אין העדפה Saveה
  static bool? getViewModePreference(String bookTitle) {
    return Settings.getValue<bool>('$_bookViewModePrefix$bookTitle');
  }

  // ==================== איפוס settings ====================

  /// איפוס כל settings פר-book (Commentators + תצוגה)
  static Future<void> resetBookSettings(String bookTitle) async {
    await resetBookCommentatorConfig(bookTitle);
    await resetBookDisplaySettings(bookTitle);
  }

  /// איפוס settings Commentators פר-book בלבד
  static Future<void> resetBookCommentatorConfig(String bookTitle) async {
    await Settings.setValue<String?>('$_bookConfigPrefix$bookTitle', null);
  }

  /// איפוס settings תצוגה פר-book בלבד (הדגשה ונראות טורים)
  static Future<void> resetBookDisplaySettings(String bookTitle) async {
    await setUseBookSpecificSettings(bookTitle, false);
    await Settings.setValue<bool?>('$_bookHighlightPrefix$bookTitle', null);
    await Settings.setValue<bool?>(
        '${_bookVisibilityPrefix}left_$bookTitle', null);
    await Settings.setValue<bool?>(
        '${_bookVisibilityPrefix}right_$bookTitle', null);
    await Settings.setValue<bool?>(
        '${_bookVisibilityPrefix}bottom_$bookTitle', null);
    await Settings.setValue<bool?>('$_bookViewModePrefix$bookTitle', null);
  }

  /// איפוס settings category
  static Future<void> resetCategorySettings(String category) async {
    await Settings.setValue<String?>('$_categoryConfigPrefix$category', null);
  }
}
