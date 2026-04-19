import 'package:otzaria/models/links.dart';

/// עוזר לסנכרון Commentators - מוצא את הקישור הטוב ביותר
class CommentarySyncHelper {
  /// check אם line היא כותרת (H1, H2, H3, H4...)
  static bool isHeaderLine(String line) {
    final headerPattern = RegExp(r'^\s*<h[1-6]', caseSensitive: false);
    return headerPattern.hasMatch(line);
  }

  /// מציאת the index הלוגי (עם טיפול בכותרות)
  /// אם הline היא כותרת, מחזיר את הline nextה
  static int getLogicalIndex(int currentIndex, List<String> content) {
    if (currentIndex < 0 || currentIndex >= content.length) {
      return currentIndex;
    }

    // אם הline הcurrent היא כותרת, נדלג לline nextה
    int logicalIndex = currentIndex;
    while (
        logicalIndex < content.length && isHeaderLine(content[logicalIndex])) {
      logicalIndex++;
    }

    // אם הגענו לסוף הtext, נBack noינדקס המקורי
    if (logicalIndex >= content.length) {
      return currentIndex;
    }

    return logicalIndex;
  }

  /// מציאת הקישור הטוב ביותר לcommentator
  /// מחזיר null אם אין קישורים כלל
  static Link? findBestLink({
    required List<Link> linksForCommentary,
    required int logicalMainIndex,
  }) {
    if (linksForCommentary.isEmpty) {
      return null;
    }

    final mainLineNumber = logicalMainIndex + 1; // המרה ל-1-based

    // ניסיון למצוא קישור מדויק
    try {
      return linksForCommentary.firstWhere(
        (link) => link.index1 == mainLineNumber,
      );
    } catch (e) {
      // אין קישור מדויק - מחפשים את הקרוב ביותר
    }

    // search L_before (הקישור הprevious הכי קרוב)
    Link? lBefore;
    int minDistanceBefore = double.maxFinite.toInt();

    for (final link in linksForCommentary) {
      if (link.index1 < mainLineNumber) {
        final distance = mainLineNumber - link.index1;
        if (distance < minDistanceBefore) {
          minDistanceBefore = distance;
          lBefore = link;
        }
      }
    }

    // אם יש קישור previous - תמיד מעדיפים אותו
    if (lBefore != null) {
      return lBefore;
    }

    // אין קישור previous - מחפשים L_after (הקישור next הכי קרוב)
    Link? lAfter;
    int minDistanceAfter = double.maxFinite.toInt();

    for (final link in linksForCommentary) {
      if (link.index1 > mainLineNumber) {
        final distance = link.index1 - mainLineNumber;
        if (distance < minDistanceAfter) {
          minDistanceAfter = distance;
          lAfter = link;
        }
      }
    }

    return lAfter; // יכול להיות null אם אין גם קישור next
  }

  /// חישוב the index היעד בcommentator
  static int? getCommentaryTargetIndex(Link? link) {
    if (link == null) {
      return null;
    }
    return link.index2 - 1; // המרה ל-0-based
  }
}
