import 'package:flutter/material.dart';
import 'package:otzaria/search/models/search_configuration.dart';

/// settings לרינדור text
///
/// class זו מכילה את כל הפרמטרים הדרושים לעיבוד והצגת text,
/// כולל settings search, עיצוב, והסרת סימנים מיוחדים.
@immutable
class RenderSettings {
  /// האם להסיר ניקוד מהtext
  final bool removeNikud;

  /// האם להסיר סימני פיסוק מהtext
  final bool removePunctuation;

  /// האם להסיר טעמים מהtext
  final bool removeTeamim;

  /// האם להחליף names קדושים
  final bool replaceHolyNames;

  /// text לsearch והדגשה
  final String searchText;

  /// אינדקס תוצאת הsearch הcurrent (-1 להדגשת הכל)
  final int currentSearchIndex;

  /// אפשרויות search מתקדמות (כתיב full/חסר וכו')
  final Map<String, Map<String, bool>> searchOptions;

  /// מילים חילופיות לsearch
  final Map<int, List<String>> alternativeWords;

  /// ערכי מרווח לsearch
  final Map<String, String> spacingValues;

  /// האם זה search fuzzy
  final bool isFuzzySearch;

  /// מצב הsearch
  final SearchMode searchMode;

  /// גודל הtext
  final double fontSize;

  /// משפחת הגופן
  final String? fontFamily;

  /// גובה הline
  final double lineHeight;

  /// האם להפעיל קישורים inline
  final bool enableInlineLinks;

  /// האם לעצב סוגריים
  final bool formatParentheses;

  /// האם ליישר text ב-justify
  final bool justifyText;

  const RenderSettings({
    this.removeNikud = false,
    this.removePunctuation = false,
    this.removeTeamim = true,
    this.replaceHolyNames = false,
    this.searchText = '',
    this.currentSearchIndex = -1,
    this.searchOptions = const {},
    this.alternativeWords = const {},
    this.spacingValues = const {},
    this.isFuzzySearch = false,
    this.searchMode = SearchMode.exact,
    this.fontSize = 18.0,
    this.fontFamily,
    this.lineHeight = 1.5,
    this.enableInlineLinks = false,
    this.formatParentheses = true,
    this.justifyText = true,
  });

  /// יוצר עותק עם שינויים
  RenderSettings copyWith({
    bool? removeNikud,
    bool? removePunctuation,
    bool? removeTeamim,
    bool? replaceHolyNames,
    String? searchText,
    int? currentSearchIndex,
    Map<String, Map<String, bool>>? searchOptions,
    Map<int, List<String>>? alternativeWords,
    Map<String, String>? spacingValues,
    bool? isFuzzySearch,
    SearchMode? searchMode,
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    bool? enableInlineLinks,
    bool? formatParentheses,
    bool? justifyText,
  }) {
    return RenderSettings(
      removeNikud: removeNikud ?? this.removeNikud,
      removePunctuation: removePunctuation ?? this.removePunctuation,
      removeTeamim: removeTeamim ?? this.removeTeamim,
      replaceHolyNames: replaceHolyNames ?? this.replaceHolyNames,
      searchText: searchText ?? this.searchText,
      currentSearchIndex: currentSearchIndex ?? this.currentSearchIndex,
      searchOptions: searchOptions ?? this.searchOptions,
      alternativeWords: alternativeWords ?? this.alternativeWords,
      spacingValues: spacingValues ?? this.spacingValues,
      isFuzzySearch: isFuzzySearch ?? this.isFuzzySearch,
      searchMode: searchMode ?? this.searchMode,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      enableInlineLinks: enableInlineLinks ?? this.enableInlineLinks,
      formatParentheses: formatParentheses ?? this.formatParentheses,
      justifyText: justifyText ?? this.justifyText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RenderSettings) return false;
    return removeNikud == other.removeNikud &&
        removePunctuation == other.removePunctuation &&
        removeTeamim == other.removeTeamim &&
        replaceHolyNames == other.replaceHolyNames &&
        searchText == other.searchText &&
        currentSearchIndex == other.currentSearchIndex &&
        isFuzzySearch == other.isFuzzySearch &&
        searchMode == other.searchMode &&
        fontSize == other.fontSize &&
        fontFamily == other.fontFamily &&
        lineHeight == other.lineHeight &&
        enableInlineLinks == other.enableInlineLinks &&
        formatParentheses == other.formatParentheses &&
        justifyText == other.justifyText;
  }

  @override
  int get hashCode {
    return Object.hash(
      removeNikud,
      removePunctuation,
      removeTeamim,
      replaceHolyNames,
      searchText,
      currentSearchIndex,
      isFuzzySearch,
      searchMode,
      fontSize,
      fontFamily,
      lineHeight,
      enableInlineLinks,
      formatParentheses,
      justifyText,
    );
  }
}
