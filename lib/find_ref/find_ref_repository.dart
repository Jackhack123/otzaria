import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:search_engine/search_engine.dart';

class FindRefRepository {
  final DataRepository dataRepository;

  FindRefRepository({required this.dataRepository});

  /// חיפוש מקורות עם תמיכה בחיפוש מטושטש (fuzzy search)
  Future<List<ReferenceSearchResult>> findRefs(String ref) async {
    // שלב 1: שלוף יותר תוצאות מהרגיל כדי לפצות על אלו שיסוננו
    final processedRef =
        replaceParaphrases(removeSectionNames(ref));
    final rawResults = await TantivyDataProvider.instance
        .searchRefs(processedRef, 300, false);

    // שלב 2: בצע סינון כפילויות (דה-דופליקציה) חכם
    var unique = _dedupeRefs(rawResults);

    // שלב 3: אם יש מעט תוצאות, נסה חיפוש מטושטש
    if (unique.length < 10) {
      final fuzzyResults = await _fuzzySearchRefs(ref);
      // מיזוג התוצאות עם עדיפות לתוצאות המדויקות
      unique = _mergeFuzzyResults(unique, fuzzyResults);
    }

    // שלב 4: החזר עד 100 תוצאות ייחודיות
    return unique.length > 100
        ? unique.take(100).toList(growable: false)
        : unique;
  }

  /// חיפוש מטושטש באמצעות התאמה חלקית וקירבה כתיבה
  Future<List<ReferenceSearchResult>> _fuzzySearchRefs(String ref) async {
    final words = ref.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return [];

    // חלץ את מילות העיקרון (השונות מהשכיחות)
    final significantWords =
        words.where((w) => w.length > 2).toList();

    if (significantWords.isEmpty) return [];

    // לכל מילה, נסה חיפוש עם התאמה חלקית
    List<ReferenceSearchResult> results = [];
    for (final word in significantWords) {
      try {
        final wordResults = await TantivyDataProvider.instance
            .searchRefs(word, 50, true); // true = fuzzy
        results.addAll(wordResults);
      } catch (e) {
        // চালך בהמשך בקיים
      }
    }

    return _dedupeRefs(results);
  }

  /// מיזוג תוצאות fuzzy עם תוצאות מדויקות
  List<ReferenceSearchResult> _mergeFuzzyResults(
    List<ReferenceSearchResult> exactResults,
    List<ReferenceSearchResult> fuzzyResults,
  ) {
    final exact = <String, ReferenceSearchResult>{};
    final seen = <String>{};

    // הוסף תוצאות מדויקות תחילה
    for (final r in exactResults) {
      final key = _makeRefKey(r);
      if (seen.add(key)) {
        exact[key] = r;
      }
    }

    // הוסף תוצאות fuzzy שעדיין לא הוכנסו
    for (final r in fuzzyResults) {
      final key = _makeRefKey(r);
      if (seen.add(key)) {
        exact[key] = r;
      }
    }

    return exact.values.toList();
  }

  String _makeRefKey(ReferenceSearchResult r) =>
      '${_normalize(r.reference)}|${r.filePath}|${_segNum(r.segment)}';

  /// מסננת רשימת תוצאות ומשאירה רק את הייחודיות על בסיס מפתח מורכב.
  List<ReferenceSearchResult> _dedupeRefs(List<ReferenceSearchResult> results) {
    final seen = <String>{}; // סט לשמירת מפתחות שכבר נראו
    final out = <ReferenceSearchResult>[];

    for (final r in results) {
      // יצירת מפתח ייחודי חכם מ-3 חלקים:

      // 1. טקסט ההפניה לאחר נרמול
      final refKey = _normalize(r.reference);

      // 2. יעד ההפניה (קובץ ספציפי או שם ספר וסוג)
      final file = r.filePath.trim().toLowerCase();
      final title = r.title.trim().toLowerCase();
      final typ = r.isPdf ? 'pdf' : 'txt';
      final dest = file.isNotEmpty ? file : '$title|$typ';

      // 3. המיקום המדויק בתוך היעד
      final seg = _segNum(r.segment);

      // הרכבת המפתח הסופי
      final key = '$refKey|$dest|$seg';

      // הוסף לרשימת הפלט רק אם המפתח לא נראה בעבר
      if (seen.add(key)) {
        out.add(r);
      }
    }
    return out;
  }

  /// פונקציית עזר לנרמול טקסט: מורידה רווחים, הופכת לאותיות קטנות ומאחדת רווחים.
  String _normalize(String? s) =>
      (s ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// פונקציית עזר להמרת 'segment' למספר שלם (int) בצורה בטוחה.

  int _segNum(dynamic s) {
    if (s is num) return s.round();
    return int.tryParse(s?.toString() ?? '') ?? 0;
  }
}
