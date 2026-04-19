import 'package:search_engine/search_engine.dart';

/// מצבי הsearch השונים
enum SearchMode {
  advanced, // search מתקדם (slop/word-distance)
  exact, // search מדוייק
  fuzzy, // search מקורב (slop/word-distance)
  levenshtein, // מצב ישן לתאימות noחור בלבד
}

/// class שמרכזת את כל settings הsearch במקום אחד
/// כוללת settings קיימות וsettings עתידיות לרגקס
class SearchConfiguration {
  // settings search קיימות
  final int distance;
  final SearchMode searchMode;
  final ResultsOrder sortBy;
  final int numResults;
  final List<String> currentFacets;

  /// טווח הsearch המקורי שנקבע בדיאלוג (no variable ע"י tap בעץ הresults)
  /// משמש לספירת facets ולבאנר חיווי
  final List<String> searchScopeFacets;

  /// תיקון errors כתיב הוא כעת אפשרות בתוך הsearch המתקדם.
  final bool typoToleranceEnabled;

  // settings רגקס עתידיות (מוכנות להרחבה)
  final bool regexEnabled;
  final bool caseSensitive;
  final bool multiline;
  final bool dotAll;
  final bool unicode;

  const SearchConfiguration({
    // ערכי ברירת מחדל קיימים
    this.distance = 2,
    this.searchMode = SearchMode.advanced,
    this.sortBy = ResultsOrder.catalogue,
    this.numResults = 100,
    this.currentFacets = const ["/"],
    this.searchScopeFacets = const ["/"],
    this.typoToleranceEnabled = false,

    // ערכי ברירת מחדל לרגקס
    this.regexEnabled = false,
    this.caseSensitive = false,
    this.multiline = false,
    this.dotAll = false,
    this.unicode = true,
  });

  /// יוצר עותק עם שינויים
  SearchConfiguration copyWith({
    int? distance,
    SearchMode? searchMode,
    ResultsOrder? sortBy,
    int? numResults,
    List<String>? currentFacets,
    List<String>? searchScopeFacets,
    bool? typoToleranceEnabled,
    bool? regexEnabled,
    bool? caseSensitive,
    bool? multiline,
    bool? dotAll,
    bool? unicode,
  }) {
    return SearchConfiguration(
      distance: distance ?? this.distance,
      searchMode: searchMode ?? this.searchMode,
      sortBy: sortBy ?? this.sortBy,
      numResults: numResults ?? this.numResults,
      currentFacets: currentFacets ?? this.currentFacets,
      searchScopeFacets: searchScopeFacets ?? this.searchScopeFacets,
      typoToleranceEnabled: typoToleranceEnabled ?? this.typoToleranceEnabled,
      regexEnabled: regexEnabled ?? this.regexEnabled,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      multiline: multiline ?? this.multiline,
      dotAll: dotAll ?? this.dotAll,
      unicode: unicode ?? this.unicode,
    );
  }

  /// המרה לmap לsave או העברה
  Map<String, dynamic> toMap() {
    return {
      'distance': distance,
      'searchMode': searchMode.index,
      'sortBy': sortBy.index,
      'numResults': numResults,
      'currentFacets': currentFacets,
      'searchScopeFacets': searchScopeFacets,
      'typoToleranceEnabled': typoToleranceEnabled,
      'regexEnabled': regexEnabled,
      'caseSensitive': caseSensitive,
      'multiline': multiline,
      'dotAll': dotAll,
      'unicode': unicode,
    };
  }

  /// יצירה מmap
  factory SearchConfiguration.fromMap(Map<String, dynamic> map) {
    final rawSearchMode = SearchMode.values[map['searchMode'] ?? 0];
    final normalizedSearchMode = rawSearchMode == SearchMode.levenshtein
        ? SearchMode.advanced
        : rawSearchMode;
    final typoToleranceEnabled =
        map['typoToleranceEnabled'] ?? rawSearchMode == SearchMode.levenshtein;

    return SearchConfiguration(
      distance: map['distance'] ?? 2,
      searchMode: normalizedSearchMode,
      sortBy: ResultsOrder.values[map['sortBy'] ?? 0],
      numResults: map['numResults'] ?? 100,
      currentFacets: List<String>.from(map['currentFacets'] ?? ["/"]),
      searchScopeFacets: List<String>.from(map['searchScopeFacets'] ?? ["/"]),
      typoToleranceEnabled: typoToleranceEnabled,
      regexEnabled: map['regexEnabled'] ?? false,
      caseSensitive: map['caseSensitive'] ?? false,
      multiline: map['multiline'] ?? false,
      dotAll: map['dotAll'] ?? false,
      unicode: map['unicode'] ?? true,
    );
  }

  /// check אם הsearch במצב רגקס
  bool get isRegexMode => regexEnabled;

  /// קבלת דגלי רגקס כמחרוזת (לשימוש עתידי)
  String get regexFlags {
    String flags = '';
    if (!caseSensitive) flags += 'i';
    if (multiline) flags += 'm';
    if (dotAll) flags += 's';
    if (unicode) flags += 'u';
    return flags;
  }

  // Getters לתאימות noחור
  bool get fuzzy => searchMode == SearchMode.fuzzy;
  bool get isAdvancedSearchEnabled =>
      searchMode == SearchMode.advanced || searchMode == SearchMode.levenshtein;
  bool get isTypoToleranceEnabled =>
      searchMode == SearchMode.levenshtein ||
      (searchMode == SearchMode.advanced && typoToleranceEnabled);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchConfiguration &&
        other.distance == distance &&
        other.searchMode == searchMode &&
        other.sortBy == sortBy &&
        other.numResults == numResults &&
        other.currentFacets.toString() == currentFacets.toString() &&
        other.searchScopeFacets.toString() == searchScopeFacets.toString() &&
        other.typoToleranceEnabled == typoToleranceEnabled &&
        other.regexEnabled == regexEnabled &&
        other.caseSensitive == caseSensitive &&
        other.multiline == multiline &&
        other.dotAll == dotAll &&
        other.unicode == unicode;
  }

  @override
  int get hashCode {
    return Object.hash(
      distance,
      searchMode,
      sortBy,
      numResults,
      currentFacets,
      searchScopeFacets,
      typoToleranceEnabled,
      regexEnabled,
      caseSensitive,
      multiline,
      dotAll,
      unicode,
    );
  }

  @override
  String toString() {
    return 'SearchConfiguration('
        'distance: $distance, '
        'searchMode: $searchMode, '
        'sortBy: $sortBy, '
        'numResults: $numResults, '
        'facets: $currentFacets, '
        'scope: $searchScopeFacets, '
        'typoToleranceEnabled: $typoToleranceEnabled, '
        'regex: $regexEnabled, '
        'caseSensitive: $caseSensitive, '
        'multiline: $multiline, '
        'dotAll: $dotAll, '
        'unicode: $unicode'
        ')';
  }
}
