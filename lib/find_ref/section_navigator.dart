import 'package:otzaria/models/books.dart';

/// Represents a hierarchical section in a book (סימן, סעיף, etc.)
class BookSection {
  final String text; // e.g., "אורח חיים", "סימן א", "סעיף א"
  final int index;
  final int level; // 1 = main (סימן), 2 = sub (סעיף), etc.
  final BookSection? parent;
  late List<BookSection> children;

  BookSection({
    required this.text,
    required this.index,
    this.level = 1,
    this.parent,
    List<BookSection>? childrenList,
  }) {
    children = childrenList ?? [];
  }

  /// מחזיר את המסלול המלא של הסעיף
  /// e.g. "אורח חיים, סימן א, סעיף א"
  String get fullPath {
    final parts = <String>[];
    BookSection? current = this;
    while (current != null) {
      parts.insert(0, current.text);
      current = current.parent;
    }
    return parts.join(', ');
  }
}

/// סיוע בניווט בין סעיפים וסימנים בספר
class SectionNavigator {
  /// מוצא סעיף ספציפי בעץ ה-TOC בהתאם לשם/מספר
  /// תומך בחיפוש חלקי כגון "שוע" ממקום "שולחן ערוך"
  static BookSection? findSection(
    List<TocEntry> toc,
    String searchText, {
    bool fuzzyMatch = true,
  }) {
    final normalized = _normalize(searchText);
    final sections = _flattenToc(toc);

    // ניסיון ראשון: חיפוש מדויק
    for (final section in sections) {
      if (_normalize(section.text) == normalized) {
        return section;
      }
    }

    // ניסיון שני: חיפוש עם fuzzy matching
    if (fuzzyMatch) {
      for (final section in sections) {
        if (_isFuzzyMatch(_normalize(section.text), normalized)) {
          return section;
        }
      }
    }

    return null;
  }

  /// מוצא את כל הסעיפים החוקיים (סימנים וסעיפים) בכל שם ספר
  /// משמש לניווט בין חלקים שונים של הספר
  static List<BookSection> findSectionsByLevel(
    List<TocEntry> toc,
    int minLevel, {
    int? maxLevel,
  }) {
    final sections = <BookSection>[];
    _collectSectionsByLevel(toc, minLevel, maxLevel, sections, null);
    return sections;
  }

  /// מוצא את כל הסעיפים בקטגוריה מסוימת
  /// לדוגמה, כל הסעיפים תחת "סימן א"
  static List<BookSection> findChildSections(
    BookSection parentSection,
  ) {
    return parentSection.children;
  }

  /// מוצא את ההורה של סעיף (אם קיים)
  static BookSection? findParentSection(
    BookSection section,
  ) {
    return section.parent;
  }

  /// מוצא את האחים של סעיף
  static List<BookSection> findSiblingSections(
    BookSection section,
  ) {
    if (section.parent == null) {
      return [];
    }
    return section.parent!.children
        .where((s) => s.text != section.text)
        .toList();
  }

  /// ממיר את ה-TocEntry למבנה BookSection מאורגן
  static List<BookSection> convertTocToSections(
    List<TocEntry> toc,
  ) {
    final sections = <BookSection>[];
    for (final entry in toc) {
      final section = _tocEntryToSection(entry, null);
      sections.add(section);
    }
    return sections;
  }

  // ============ Private Helpers ============

  /// ממיר TocEntry לBookSection באופן רקורסיבי
  static BookSection _tocEntryToSection(
    TocEntry entry,
    BookSection? parent,
  ) {
    final section = BookSection(
      text: entry.text,
      index: entry.index,
      level: entry.level,
      parent: parent,
    );

    section.children = entry.children
        .map((child) => _tocEntryToSection(child, section))
        .toList();

    return section;
  }

  /// משטח את עץ ה-TOC לרשימה שטוחה
  static List<BookSection> _flattenToc(List<TocEntry> toc) {
    final result = <BookSection>[];
    for (final entry in toc) {
      final section = _tocEntryToSection(entry, null);
      _flattenSection(section, result);
    }
    return result;
  }

  /// משטח סעיף וכל ילדיו לרשימה
  static void _flattenSection(
    BookSection section,
    List<BookSection> result,
  ) {
    result.add(section);
    for (final child in section.children) {
      _flattenSection(child, result);
    }
  }

  /// אוסף סעיפים בשכבה מסוימת
  static void _collectSectionsByLevel(
    List<TocEntry> toc,
    int minLevel,
    int? maxLevel,
    List<BookSection> result,
    BookSection? parent,
  ) {
    for (final entry in toc) {
      if (entry.level >= minLevel && (maxLevel == null || entry.level <= maxLevel)) {
        final section = _tocEntryToSection(entry, parent);
        result.add(section);
      }
      _collectSectionsByLevel(
        entry.children,
        minLevel,
        maxLevel,
        result,
        parent,
      );
    }
  }

  /// בדיקה אם שני טקסטים תואמים בחיפוש fuzzy
  /// תומך ב:
  /// - התאמה חלקית (substring)
  /// - התאמה בעיתוג (abbreviation)
  /// - דמיון קשתור (Levenshtein-like)
  static bool _isFuzzyMatch(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;

    // עדיפות 1: חיפוש חלקי
    if (text.contains(query)) return true;

    // עדיפות 2: ראשי תיבות
    if (_getAbbreviation(text) == query) return true;

    // עדיפות 3: דמיון מילים
    if (_wordSimilarity(text, query) > 0.7) return true;

    return false;
  }

  /// מחלץ ראשי תיבות מטקסט
  /// לדוגמה: "שולחן ערוך" → "שע"
  static String _getAbbreviation(String text) {
    return text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .join();
  }

  /// מחשב דמיון בין שני טקסטים
  /// ערך בין 0 ל-1 (1 = זהה לחלוטין)
  static double _wordSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final distance = _levenshteinDistance(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;
    return 1.0 - (distance / maxLength);
  }

  /// מחשב מרחק Levenshtein בין שני טקסטים
  static int _levenshteinDistance(String s1, String s2) {
    final List<List<int>> distances =
        List.generate(s1.length + 1, (i) => List.generate(s2.length + 1, (j) => 0));

    for (int i = 0; i <= s1.length; i++) {
      distances[i][0] = i;
    }

    for (int j = 0; j <= s2.length; j++) {
      distances[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        distances[i][j] = _min(
          distances[i - 1][j] + 1, // deletion
          distances[i][j - 1] + 1, // insertion
          distances[i - 1][j - 1] + cost, // substitution
        );
      }
    }

    return distances[s1.length][s2.length];
  }

  static int _min(int a, int b, int c) {
    return a < b ? (a < c ? a : c) : (b < c ? b : c);
  }

  /// מנרמל טקסט להשוואה
  static String _normalize(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
