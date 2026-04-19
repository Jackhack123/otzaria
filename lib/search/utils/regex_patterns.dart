/// מרכז רגקסים לsearch - כל הרגקסים במקום אחד
///
/// file זה מרכז את כל הרגקסים המשמשים לsearch בSystem
/// כדי לשפר את הארגון ולהקל על התחזוקה.
///
/// הfile מחליף רגקסים שהיו מפוזרים בfiles nextים:
/// - lib/search/search_repository.dart
/// - lib/search/utils/hebrew_morphology.dart
/// - lib/utils/text_manipulation.dart
/// - lib/search/models/search_terms_model.dart
/// - lib/search/view/enhanced_search_field.dart
///
/// יתרונות הריכוז:
/// 1. קל יותר לתחזק ולעדyes רגקסים
/// 2. מונע כפילויות
/// 3. מבטיח עקביות בין חלקי הSystem השונים
/// 4. מקל על tests ותיקונים
class SearchRegexPatterns {
  // ===== רגקסים בסיסיים =====

  /// רגקס לפיצול מילים לפי רווחים
  static final RegExp wordSplitter = RegExp(r'\s+');

  /// רגקס לסינון רווחים בקלט
  static final RegExp spacesFilter = RegExp(r'\s');

  // ===== רגקסים לעיבוד HTML =====

  /// רגקס להסרת תגי HTML וישויות
  static final RegExp htmlStripper = RegExp(r'<[^>]*>|&[^;]+;');

  // ===== רגקסים לעיבוד עברית =====

  /// רגקס להסרת ניקוד וטעמים
  static final RegExp vowelsAndCantillation = RegExp(r'[\u0591-\u05C7]');

  /// רגקס להסרת טעמים בלבד
  static final RegExp cantillationOnly = RegExp(r'[\u0591-\u05AF]');

  /// רגקס בסיסי לidentify name הקודש (יהוה) עם ניקוד.
  ///
  /// הסינון של מקרים כמו "ויגביהוהו" מתבצע בקוד, כדי שנוכל
  /// להתעלם מסימני ניקוד וטעמים שלפני הname בלי לפספס מקרים כמו "לַֽיהֹוָֽה".
  static final RegExp holyName = RegExp(
    r"י([\p{Mn}]*)ה([\p{Mn}]*)ו([\p{Mn}]*)ה([\p{Mn}]*)",
    unicode: true,
  );

  // ===== רגקסים למורפולוגיה עברית =====

  /// רגקס לidentify קידומות דקדוקיות
  static final RegExp grammaticalPrefixes = RegExp(r'^(ו|מ|כ|ב|ש|ל|ה)+(.+)');

  /// רגקס לidentify endת דקדוקיות
  static final RegExp grammaticalSuffixes = RegExp(
      r'(ותי|ותיך|ותיו|ותיה|ותינו|ותיכם|ותיyes|ותיהם|ותיהן|יי|יך|יו|יה|ינו|יכם|יyes|יהם|יהן|י|ך|ו|ה|נו|כם|yes|ם|ן|ים|ות)$');

  // ===== functions ליצירת רגקסים דינמיים =====

  /// יוצר רגקס לsearch מילה עם קידומות דקדוקיות
  static String createPrefixPattern(String word) {
    if (word.isEmpty) return word;
    return r'(ו|מ|דא|א|כש|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' +
        RegExp.escape(word);
  }

  /// יוצר רגקס לsearch מילה עם endת דקדוקיות
  static String createSuffixPattern(String word) {
    if (word.isEmpty) return word;
    const suffixPattern =
        r'(ותי|ותיך|ותיו|ותיה|ותינו|ותיכם|ותיyes|ותיהם|ותיהן|יי|יך|יו|יה|ינו|יכם|יyes|יהם|יהן|י|ך|ו|ה|נו|כם|yes|ם|ן|ים|ות)?';
    return RegExp.escape(word) + suffixPattern;
  }

  /// יוצר רגקס לsearch מילה עם קידומות וendת יחד
  static String createFullMorphologicalPattern(String word) {
    if (word.isEmpty) return word;
    String pattern = RegExp.escape(word);

    // הוספת קידומות
    pattern = r'(ו|מ|כ|ב|ש|ל|ה|ד)?(כ|ב|ש|ל|ה|ד)?(ה)?' + pattern;

    // הוספת endת
    const suffixPattern =
        r'(ותי|ותַי|ותיך|ותֶיךָ|ותַיִךְ|ותיו|ותָיו|ותיה|ותֶיהָ|ותינו|ותֵינוּ|ותיכם|ותֵיכם|ותיyes|ותֵיyes|ותיהם|ותֵיהם|ותיהן|ותֵיהן|יות|יי|יַי|יך|יךָ|יִךְ|יו|יה|יא|תא|יהָ|ינו|יכם|יyes|יהם|יהן|י|ך|ךָ|ךְ|ו|ה|הּ|נו|כם|yes|ם|ן|ים|ות)?';
    pattern = pattern + suffixPattern;

    return pattern;
  }

  /// יוצר רגקס לsearch קידומות רגילות (no דקדוקיות)
  static String createPrefixSearchPattern(String word,
      {int maxPrefixLength = 3}) {
    if (word.isEmpty) return word;

    if (word.length <= 1) {
      return '.{1,5}${RegExp.escape(word)}';
    } else if (word.length <= 2) {
      return '.{1,4}${RegExp.escape(word)}';
    } else if (word.length <= 3) {
      return '.{1,3}${RegExp.escape(word)}';
    } else {
      return '.*${RegExp.escape(word)}';
    }
  }

  /// יוצר רגקס לsearch endת רגילות (no דקדוקיות)
  static String createSuffixSearchPattern(String word,
      {int maxSuffixLength = 7}) {
    if (word.isEmpty) return word;

    if (word.length <= 1) {
      return '${RegExp.escape(word)}.{1,7}';
    } else if (word.length <= 2) {
      return '${RegExp.escape(word)}.{1,6}';
    } else if (word.length <= 3) {
      return '${RegExp.escape(word)}.{1,5}';
    } else {
      return '${RegExp.escape(word)}.*';
    }
  }

  /// יוצר רגקס לsearch חלק ממילה
  ///
  /// function זו משמשת גם כאשר הuser בוחר גם קידומות וגם endת יחד,
  /// מכיוון שהשילוב הזה בעצם מחפש את המילה בכל מקום בתוך מילה אחרת
  static String createPartialWordPattern(String word) {
    if (word.isEmpty) return word;

    if (word.length <= 3) {
      return '.{0,3}${RegExp.escape(word)}.{0,3}';
    } else {
      return '.{0,2}${RegExp.escape(word)}.{0,2}';
    }
  }

  /// יוצר רגקס לכתיב full/חסר
  static String createFullPartialSpellingPattern(
    String word, {
    bool tokenAnchors = true, // עיגון לטוקן כשאין דקדוק/חלק-ממילה
  }) {
    if (word.isEmpty) return word;
    final variations = generateFullPartialSpellingVariations(word);
    final escaped = variations.map(RegExp.escape).toList();
    final core = '(?:${escaped.join('|')})';
    return tokenAnchors ? '^$core\$' : core;
  }

  // ===== functions עזר =====

  /// יוצר list של וריאציות כתיב full/חסר
  static List<String> generateFullPartialSpellingVariations(String word) {
    if (word.isEmpty) return [word];
    final variations = <String>{};
    final chars = word.split('');
    final optionalIndices = <int>[];

    for (int i = 0; i < chars.length; i++) {
      if (['י', 'ו', "'", '"'].contains(chars[i])) {
        optionalIndices.add(i);
      }
    }

    final numCombinations = 1 << optionalIndices.length; // 2^n
    for (int i = 0; i < numCombinations; i++) {
      final variant = StringBuffer();
      int originalCharIndex = 0;
      for (int optionalCharIndex = 0;
          optionalCharIndex < optionalIndices.length;
          optionalCharIndex++) {
        int nextOptional = optionalIndices[optionalCharIndex];
        variant.write(word.substring(originalCharIndex, nextOptional));
        if ((i & (1 << optionalCharIndex)) != 0) {
          variant.write(chars[nextOptional]);
        }
        originalCharIndex = nextOptional + 1;
      }
      variant.write(word.substring(originalCharIndex));
      variations.add(variant.toString());
    }

    return variations.toList();
  }

  /// בודק אם מילה מכילה קידומת דקדוקית
  static bool hasGrammaticalPrefix(String word) {
    if (word.isEmpty) return false;
    return grammaticalPrefixes.hasMatch(word);
  }

  /// בודק אם מילה מכילה סיומת דקדוקית
  static bool hasGrammaticalSuffix(String word) {
    if (word.isEmpty) return false;
    return grammaticalSuffixes.hasMatch(word);
  }

  /// מחלץ את השורש של מילה (מסיר קידומות וendת)
  static String extractRoot(String word) {
    if (word.isEmpty) return word;
    String result = word;

    // הסרת קידומות
    result = result.replaceFirst(grammaticalPrefixes, '');

    // הסרת endת
    result = result.replaceFirst(grammaticalSuffixes, '');

    return result.isEmpty ? word : result;
  }

  // ===== רגקסים נוספים לעתיד =====

  /// רגקס לidentify מbooks עבריים (א', ב', ג' וכו')
  static final RegExp hebrewNumbers = RegExp(r"[א-ת]['״]");

  /// רגקס לidentify מbooks לועזיים
  static final RegExp latinNumbers = RegExp(r'\d+');

  /// רגקס לidentify כתובות (פרק, פסוק, page וכו')
  static final RegExp references =
      RegExp(r"(פרק|פסוק|page|page|סימן|הלכה)\s*[א-ת'״\d]+");

  /// רגקס לidentify ציטוטים (text בגרשיים)
  static final RegExp quotations = RegExp(r'"[^"]*"');

  /// רגקס לidentify Shortcuts נפוצים (רמב"ם, רש"י וכו')
  static final RegExp abbreviations = RegExp(r'[א-ת]+"[א-ת]');

  /// function לניקוי text מתווים מיוחדים
  static String cleanText(String text) {
    return text
        .replaceAll(
            RegExp(r'[^\u0590-\u05FF\u0020-\u007F]'), '') // רק עברית ואנגלית
        .replaceAll(RegExp(r'\s+'), ' ') // רווחים מרובים לרווח יחיד
        .trim();
  }

  /// function לidentify אם text הוא בעברית
  static bool isHebrew(String text) {
    final hebrewChars = RegExp(r'[\u0590-\u05FF]');
    return hebrewChars.hasMatch(text);
  }

  /// function לidentify אם text הוא באנגלית
  static bool isEnglish(String text) {
    final englishChars = RegExp(r'[a-zA-Z]');
    return englishChars.hasMatch(text);
  }

  /// יוצר רגקס משולב לכתיב full/חסר עם קידומות דקדוקיות
  static String createSpellingWithPrefixPattern(String word) {
    if (word.isEmpty) return word;
    final variations = generateFullPartialSpellingVariations(word);
    // הגבלה על מbook parentיאציות כדי למנוע רגקס ענק
    final limitedVariations =
        variations.length > 10 ? variations.take(10).toList() : variations;
    final patterns =
        limitedVariations.map((v) => createPrefixPattern(v)).toList();
    return '(${patterns.join('|')})';
  }

  /// יוצר רגקס משולב לכתיב full/חסר עם endת דקדוקיות
  static String createSpellingWithSuffixPattern(String word) {
    if (word.isEmpty) return word;
    final variations = generateFullPartialSpellingVariations(word);
    // הגבלה על מbook parentיאציות כדי למנוע רגקס ענק
    final limitedVariations =
        variations.length > 10 ? variations.take(10).toList() : variations;
    final patterns =
        limitedVariations.map((v) => createSuffixPattern(v)).toList();
    return '(${patterns.join('|')})';
  }

  /// יוצר רגקס משולב לכתיב full/חסר עם קידומות וendת דקדוקיות
  static String createSpellingWithFullMorphologyPattern(String word) {
    if (word.isEmpty) return word;
    final variations = generateFullPartialSpellingVariations(word);
    // הגבלה על מbook parentיאציות כדי למנוע רגקס ענק
    final limitedVariations =
        variations.length > 8 ? variations.take(8).toList() : variations;
    final patterns = limitedVariations
        .map((v) => createFullMorphologicalPattern(v))
        .toList();
    return '(${patterns.join('|')})';
  }

  /// function שמחליטה איזה סוג search להשתמש בהתבסס על אפשרויות הuser
  ///
  /// הלוגיקה:
  /// - אם selectedו גם קידומות וגם endת רגילות -> search "חלק ממילה"
  /// - אם selectedו קידומות דקדוקיות וendת דקדוקיות -> search מורפולוגי full
  /// - אחרת -> search לפי האפשרות הspecificת שselectedה
// lib/search/utils/regex_patterns.dart

  static String createSearchPattern(
    String word, {
    bool hasPrefix = false,
    bool hasSuffix = false,
    bool hasGrammaticalPrefixes = false,
    bool hasGrammaticalSuffixes = false,
    bool hasPartialWord = false,
    bool hasFullPartialSpelling = false,
  }) {
    if (word.isEmpty) return word;

    // --- לוגיקה עבור שילובים עם "כתיב full/חסר" ---
    if (hasFullPartialSpelling) {
      final hasMorphologyOrPartial = hasGrammaticalPrefixes ||
          hasGrammaticalSuffixes ||
          hasPrefix ||
          hasSuffix ||
          hasPartialWord;

      // ניצור את הווריאציות פעם אחת בלבד
      final variations = generateFullPartialSpellingVariations(word);

      // order העדיפויות חשוב כאן! מהspecific ביותר לgeneral ביותר
      if (hasPrefix && hasSuffix) {
        final patterns =
            variations.map((v) => createPartialWordPattern(v)).toList();
        return '(${patterns.join('|')})';
      } else if (hasGrammaticalPrefixes && hasGrammaticalSuffixes) {
        return createSpellingWithFullMorphologyPattern(word);
      } else if (hasPrefix) {
        final patterns =
            variations.map((v) => createPrefixSearchPattern(v)).toList();
        return '(${patterns.join('|')})';
      } else if (hasSuffix) {
        final patterns =
            variations.map((v) => createSuffixSearchPattern(v)).toList();
        return '(${patterns.join('|')})';
      } else if (hasGrammaticalPrefixes) {
        return createSpellingWithPrefixPattern(word);
      } else if (hasGrammaticalSuffixes) {
        return createSpellingWithSuffixPattern(word);
      } else if (hasPartialWord) {
        final patterns =
            variations.map((v) => createPartialWordPattern(v)).toList();
        return '(${patterns.join('|')})';
      } else {
        // רק "כתיב full/חסר" לno שום אפשרות אחרת
        return createFullPartialSpellingPattern(
          word,
          tokenAnchors: !hasMorphologyOrPartial,
        );
      }
    }

    // --- לוגיקה עבור searchים לno "כתיב full/חסר" ---
    // order העדיפויות חשוב גם כאן
    if (hasPrefix && hasSuffix) {
      return createPartialWordPattern(word);
    } else if (hasGrammaticalPrefixes && hasGrammaticalSuffixes) {
      return createFullMorphologicalPattern(word);
    } else if (hasPrefix) {
      return createPrefixSearchPattern(word);
    } else if (hasSuffix) {
      return createSuffixSearchPattern(word);
    } else if (hasGrammaticalPrefixes) {
      return createPrefixPattern(word);
    } else if (hasGrammaticalSuffixes) {
      return createSuffixPattern(word);
    } else if (hasPartialWord) {
      return createPartialWordPattern(word);
    }

    // ברירת מחדל - search מדויק
    return RegExp.escape(word);
  }
}
