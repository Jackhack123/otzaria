import 'package:otzaria/models/links.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:otzaria/data/data_providers/sqlite_data_provider.dart';
import 'dart:isolate';

/// מייצג קבוצת קטעי פירוש רצופים מאותו book
///
/// note: שונה מ-CommentatorGroup שמייצג קבוצת Commentators לפי תקופה.
/// LinkGroup מייצג group של קישורים (Links) שכולם מאותו book.
class LinkGroup {
  final String bookTitle;
  final List<Link> links;

  const LinkGroup({
    required this.bookTitle,
    required this.links,
  });

  /// מbook הקישורים בgroup
  int get count => links.length;

  /// האם הgroup emptyה
  bool get isEmpty => links.isEmpty;

  /// האם הgroup no emptyה
  bool get isNotEmpty => links.isNotEmpty;
}

/// order הדורות למיון
enum CommentaryEra {
  torahShebichtav(0, 'תורה שבFont'),
  chazal(1, 'חז"ל'),
  rishonim(2, 'ראשונים'),
  acharonim(3, 'אחרונים'),
  modern(4, 'מחברי זמננו'),
  other(5, 'שאר Commentators');

  final int order;
  final String hebrewName;

  const CommentaryEra(this.order, this.hebrewName);
}

/// שירות מרכזי לטיפול בלוגיקת הCommentators
///
/// מרכז את כל הactions הנפוצות על Commentators וקישורים:
/// - קיבוץ קישורים לפי book
/// - מיון לפי דורות
/// - סינון לפי Commentators פעילים
class CommentaryService {
  static const int _asyncGroupingThreshold = 80;

  /// מקבץ רשימת קישורים לgroups לפי name הbook (רק קטעים רצופים)
  ///
  /// [links] - רשימת הקישורים לקיבוץ
  ///
  /// מחזיר רשימת groups כאשר כל group מכילה קישורים רצופים מאותו book
  static List<LinkGroup> groupConsecutiveLinks(List<Link> links) {
    if (links.isEmpty) return [];

    final groups = <LinkGroup>[];
    String? currentTitle;
    List<Link> currentGroup = [];
    String? lastPath;

    for (final link in links) {
      final String title;
      if (link.path2 == lastPath) {
        title = currentTitle!;
      } else {
        title = utils.getTitleFromPath(link.path2);
      }

      if (currentTitle == null || currentTitle != title) {
        // new book - שומר את הgroup הקודמת ומתחיל group חדשה
        if (currentGroup.isNotEmpty) {
          groups.add(LinkGroup(
            bookTitle: currentTitle!,
            links: List.unmodifiable(currentGroup),
          ));
        }
        currentTitle = title;
        lastPath = link.path2;
        currentGroup = [link];
      } else {
        // אותו book - מוסיף לgroup הcurrent
        currentGroup.add(link);
      }
    }

    // מוסיף את הgroup האחרונה
    if (currentGroup.isNotEmpty) {
      groups.add(LinkGroup(
        bookTitle: currentTitle!,
        links: List.unmodifiable(currentGroup),
      ));
    }

    return groups;
  }

  /// מקבץ רשימת קישורים לgroups בצורה אסינכרונית כדי no לחסום את ה-UI
  static Future<List<LinkGroup>> groupConsecutiveLinksAsync(
    List<Link> links,
  ) async {
    if (links.isEmpty) {
      return const [];
    }

    if (links.length <= _asyncGroupingThreshold) {
      return groupConsecutiveLinks(links);
    }

    return Isolate.run(() => groupConsecutiveLinks(links));
  }

  /// מחזיר את הדור של book לפי שמו
  ///
  /// [bookTitle] - name הbook
  ///
  /// מחזיר את הדור המתאים, או [CommentaryEra.other] אם no נמצא
  static Future<CommentaryEra> getBookEra(String bookTitle) async {
    try {
      final repo = SqliteDataProvider.instance.repository;
      if (repo == null) {
        // אם ה-DB no מאותחל, נחזיר "שאר Commentators"
        return CommentaryEra.other;
      }

      final generationInfo = await repo.getBookGenerationInfoByTitle(bookTitle);

      if (generationInfo == null) {
        return CommentaryEra.other;
      }

      // מיפוי name הדור ל-CommentaryEra
      return _mapGenerationNameToEra(generationInfo.generationName);
    } catch (e) {
      // במקרה של error, מחזירים "שאר Commentators"
      return CommentaryEra.other;
    }
  }

  /// מmap name דור מה-DB ל-CommentaryEra enum
  static CommentaryEra _mapGenerationNameToEra(String generationName) {
    switch (generationName) {
      case 'תורה שבFont':
        return CommentaryEra.torahShebichtav;
      case 'חז"ל':
        return CommentaryEra.chazal;
      case 'ראשונים':
        return CommentaryEra.rishonim;
      case 'אחרונים':
        return CommentaryEra.acharonim;
      case 'מחברי זמננו':
        return CommentaryEra.modern;
      default:
        return CommentaryEra.other;
    }
  }

  /// ממיין groups Commentators לפי order הדורות
  ///
  /// [groups] - רשימת הgroups למיון
  ///
  /// מחזיר list ממוינת לפי: תורה שבFont -> חז"ל -> ראשונים -> אחרונים -> מחברי זמננו -> שאר Commentators
  /// בתוך כל דור, המיון הוא אלפביתי לפי name הbook
  static Future<List<LinkGroup>> sortGroupsByEra(List<LinkGroup> groups) async {
    if (groups.isEmpty) return groups;

    // יצירת map של כל name book לדור שלו - הרצה במקביל לשיפור ביצועים
    final eraFutures = groups.map((group) => getBookEra(group.bookTitle));
    final eras = await Future.wait(eraFutures);
    final Map<String, CommentaryEra> eraMap = {
      for (int i = 0; i < groups.length; i++) groups[i].bookTitle: eras[i],
    };

    // מיון הgroups לפי הדור
    final sortedGroups = List<LinkGroup>.from(groups);
    sortedGroups.sort((a, b) {
      final eraA = eraMap[a.bookTitle] ?? CommentaryEra.other;
      final eraB = eraMap[b.bookTitle] ?? CommentaryEra.other;

      if (eraA.order != eraB.order) {
        return eraA.order.compareTo(eraB.order);
      }

      // אם שני הbooks באותו דור, ממיינים לפי name
      return a.bookTitle.compareTo(b.bookTitle);
    });

    return sortedGroups;
  }

  /// מקבץ וממיין קישורים בaction אחת
  ///
  /// [links] - רשימת הקישורים
  ///
  /// מחזיר groups ממוינות לפי דור
  static Future<List<LinkGroup>> groupAndSortLinks(List<Link> links) async {
    final groups = await groupConsecutiveLinksAsync(links);
    return sortGroupsByEra(groups);
  }

  /// מסנן קישורים לפי אינדקסים וCommentators פעילים
  ///
  /// זהו wrapper ל-getLinksforIndexs הקיימת, לsave API אחיד
  static Future<List<Link>> filterLinks({
    required List<int> indexes,
    required List<Link> links,
    required List<String> activeCommentators,
  }) async {
    return getLinksforIndexs(
      indexes: indexes,
      links: links,
      commentatorsToShow: activeCommentators,
    );
  }

  /// מסנן, מקבץ וממיין קישורים בaction אחת
  ///
  /// [indexes] - אינדקסים של lines להצגת Commentators
  /// [links] - כל הקישורים
  /// [activeCommentators] - רשימת הCommentators הפעילים
  ///
  /// מחזיר groups ממוינות של קישורים מסוננים
  static Future<List<LinkGroup>> getGroupedCommentaries({
    required List<int> indexes,
    required List<Link> links,
    required List<String> activeCommentators,
  }) async {
    final filteredLinks = await filterLinks(
      indexes: indexes,
      links: links,
      activeCommentators: activeCommentators,
    );
    return groupAndSortLinks(filteredLinks);
  }

  /// בודק אם יש Commentators זמינים noינדקסים מסוימים
  ///
  /// [indexes] - אינדקסים לtest
  /// [links] - כל הקישורים
  /// [activeCommentators] - רשימת הCommentators הפעילים
  static bool hasCommentaries({
    required List<int> indexes,
    required List<Link> links,
    required List<String> activeCommentators,
  }) {
    if (activeCommentators.isEmpty || indexes.isEmpty) return false;

    final indexSet = indexes.map((i) => i + 1).toSet();
    final commentatorsSet = activeCommentators.toSet();
    String? lastPath;
    String? lastTitle;

    return links.any((link) {
      if (!indexSet.contains(link.index1)) return false;
      final type = link.connectionType.toUpperCase();
      if (type != "COMMENTARY" && type != "TARGUM") return false;
      if (link.path2 != lastPath) {
        lastPath = link.path2;
        lastTitle = utils.getTitleFromPath(link.path2);
      }
      return commentatorsSet.contains(lastTitle);
    });
  }
}
