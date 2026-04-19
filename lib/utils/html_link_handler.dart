import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/core/ui_snack.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';

/// class לטיפול בקישורי HTML בתוך הtext
class HtmlLinkHandler {
  /// מנסה לפענח URL בצורה בטוחה, תומך בtext רגיל ו-URL encoded
  static String _safeDecode(String text) {
    if (text.isEmpty) return text;

    try {
      // אם הtext מכיל % זה כנראה מקודד
      if (text.contains('%')) {
        return Uri.decodeComponent(text);
      }
      // אחרת, זה כבר text רגיל
      return text;
    } catch (e) {
      // אם הפענוח נכשל, נחזיר את הtext המקורי
      debugPrint('Failed to decode URL component: $text, error: $e');
      return text;
    }
  }

  /// מטפל בקישורים מבוססי תווים (inline links)
  static Future<void> _handleInlineLink(
    BuildContext context,
    String url,
    Function(TextBookTab) openBookCallback,
  ) async {
    try {
      // פענוח ה-URL ולקיחת הפרמטרים
      final uri = Uri.parse(url);
      final path = _safeDecode(uri.queryParameters['path'] ?? '');
      final indexStr = uri.queryParameters['index'] ?? '';
      final ref = _safeDecode(uri.queryParameters['ref'] ?? '');

      if (path.isEmpty) {
        throw Exception('path no תקין בקישור');
      }

      // המרת the index למbook (index2 מגיע כ-1-based, אבל אנחנו צריכים 0-based)
      final index = int.tryParse(indexStr);
      if (index == null) {
        throw Exception('אינדקס no תקין בקישור');
      }

      // מציאת הbook על פי הpath
      final bookTitle = _getTitleFromPath(path);
      final library = await DataRepository.instance.library;
      final foundBook = library.findBookByTitle(bookTitle, TextBook);

      if (foundBook == null) {
        throw Exception('no נמצא book בname: $bookTitle');
      }

      if (foundBook is! TextBook) {
        throw Exception('הbook $bookTitle אינו book text');
      }

      // פתיחת הbook באינדקס הtrue (המרה ל-0-based)
      final tab = TextBookTab(
        book: foundBook,
        index: index - 1, // המרה מ-1-based ל-0-based
        openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
            (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
      );

      openBookCallback(tab);

      if (context.mounted && ref.isNotEmpty) {
        UiSnack.show('נOpen: $ref');
      }
    } catch (e) {
      debugPrint('error בטיפול בקישור מבוסס תווים: $e');

      if (context.mounted) {
        UiSnack.show('no ניתן לopen את הקישור: $e');
      }
    }
  }

  /// מחלץ name book מpath file
  static String _getTitleFromPath(String path) {
    // הסרת סיומת file וpath
    String title = path.split('/').last.split('\\').last;
    if (title.endsWith('.txt')) {
      title = title.substring(0, title.length - 4);
    }
    return title;
  }

  /// מטפל בtap על קישור HTML
  ///
  /// הfunction commentatorת קישורים בפורמטים nextים:
  /// - book://name_הסxxxxxxxxח book בתחילת הbook
  /// - book://name_הbook#כותרת - פותח book ומנווט לכותרת specificת
  /// - #כותרת - מנווט לכותרת באותו book
  /// - otzaria://inline-link?path={path}&index={index}&ref={ref} - קישור מבוסס תווים
  ///
  /// examples:
  /// - <a href="book://ברכות">ברכות</a>
  /// - <a href="book://ברכות#page ב">ברכות page ב</a>
  /// - <a href="#page ג">page ג</a>
  static Future<bool> handleLink(
    BuildContext context,
    String url,
    Function(TextBookTab) openBookCallback,
  ) async {
    try {
      // check אם זה קישור מבוסס תווים (inline-link)
      if (url.startsWith('otzaria://inline-link')) {
        await _handleInlineLink(context, url, openBookCallback);
        return true;
      }

      // check אם זה קישור פנימי לכותרת באותו book
      if (url.startsWith('#')) {
        final headerName = _safeDecode(url.substring(1));
        await _navigateToHeader(context, headerName);
        return true;
      }

      // check אם זה קישור לbook
      if (url.startsWith('book://')) {
        final bookUrl = url.substring(7); // הסרת "book://"

        String bookTitle;
        String? headerName;

        // check אם יש כותרת specificת
        if (bookUrl.contains('#')) {
          final parts = bookUrl.split('#');
          bookTitle = _safeDecode(parts[0]);

          // טיפול במבנה Talmudי: book#page#צד
          if (parts.length >= 2) {
            if (parts.length == 3) {
              // מבנה full: book#page#צד
              headerName = _safeDecode('${parts[1]} ${parts[2]}');
            } else {
              // מבנה רגיל: book#כותרת
              headerName = _safeDecode(parts[1]);
            }
          }
        } else {
          bookTitle = _safeDecode(bookUrl);
        }

        await _openBookWithHeader(
            context, bookTitle, headerName, openBookCallback);
        return true;
      }

      // אם זה no קישור שאנחנו מטפלים בו, נחזיר false
      return false;
    } catch (e, stackTrace) {
      debugPrint('error בטיפול בקישור: $e');
      debugPrint('Stack trace: $stackTrace');

      // הצגת הודעת error לuser
      if (context.mounted) {
        UiSnack.show('error בפתיחת הקישור: $e');
      }

      return false;
    }
  }

  /// מנווט לכותרת באותו book הcurrent
  static Future<void> _navigateToHeader(
      BuildContext context, String headerName) async {
    try {
      // נקבל את הbook הcurrent מה-BLoC
      final textBookBloc = context.read<TextBookBloc>();
      final state = textBookBloc.state;

      if (state is! TextBookLoaded) {
        throw Exception('no ניתן לנווט - הbook no נטען');
      }

      // search הכותרת בcontent הspecific
      final index = await _findHeaderIndex(state.book, headerName);

      if (index != null) {
        // ניווט noינדקס שנמצא
        state.scrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
        );

        if (context.mounted) {
          UiSnack.show('נווט ל: $headerName');
        }
      } else {
        throw Exception('no נמצאה הכותרת: $headerName');
      }
    } catch (e) {
      debugPrint('error בניווט לכותרת: $e');

      if (context.mounted) {
        UiSnack.show('no ניתן לנווט לכותרת: $headerName');
      }
    }
  }

  /// פותח book ומנווט לכותרת specificת (אם צוינה)
  static Future<void> _openBookWithHeader(
    BuildContext context,
    String bookTitle,
    String? headerName,
    Function(TextBookTab) openBookCallback,
  ) async {
    try {
      // search הbook בlibrary
      final library = await DataRepository.instance.library;

      // קבלת רשימת כל הbooks לtest
      final allBooks = library.getAllBooks();

      final foundBook = library.findBookByTitle(bookTitle, TextBook);

      if (foundBook == null) {
        // נסה לחפש בלי להגביל לטיפוס TextBook
        final anyBook = library.findBookByTitle(bookTitle, null);

        if (anyBook != null) {
          throw Exception(
              'הbook "$bookTitle" נמצא אבל הוא מטיפוס ${anyBook.runtimeType}, no TextBook');
        }

        // הצגת רשימת books זמינים לuser
        final availableBooks = allBooks.take(10).map((b) => b.title).join(', ');
        throw Exception(
            'no נמצא book בname: "$bookTitle".\nbooks זמינים (examples): $availableBooks');
      }

      // וידוא שזה TextBook
      if (foundBook is! TextBook) {
        throw Exception('הbook $bookTitle אינו book text');
      }

      final book = foundBook;
      int startIndex = 0;

      // אם צוינה כותרת, נחפש את the index שלה
      if (headerName != null && headerName.isNotEmpty) {
        final headerIndex = await _findHeaderIndex(book, headerName);
        if (headerIndex != null) {
          startIndex = headerIndex;
        } else {
          // אם no נמצאה הכותרת, נציג Warning אבל עדיין נOpen את הbook
          if (context.mounted) {
            UiSnack.show(
                'no נמצאה הכותרת "$headerName" בbook $bookTitle, פותח את תחילת הbook');
          }
        }
      }

      // פתיחת הbook
      final tab = TextBookTab(
        book: book,
        index: startIndex,
        openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
            (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
      );

      openBookCallback(tab);

      if (context.mounted && headerName != null && headerName.isNotEmpty) {
        UiSnack.show('Open book: $bookTitle - $headerName');
      }
    } catch (e) {
      debugPrint('error בפתיחת book: $e');

      if (context.mounted) {
        UiSnack.show('no ניתן לopen את הbook: $bookTitle');
      }
    }
  }

  /// מחפש את the index של כותרת בbook
  static Future<int?> _findHeaderIndex(TextBook book, String headerName) async {
    try {
      // קבלת content הspecific
      final tableOfContents = await book.tableOfContents;

      // search בcontent העניינים - previous search מדויק
      for (final entry in tableOfContents) {
        if (isHeaderMatch(entry.text, headerName)) {
          return entry.index;
        }
      }

      // אם no נמצא, ננסה לחפש רק לפי מbook הpage (בלי page)
      // זה עוזר כשהקישור כולל page שno קיים בcontent העניינים
      final pageOnlyMatch = _extractPageNumber(headerName);
      if (pageOnlyMatch != null) {
        for (final entry in tableOfContents) {
          final entryPageMatch = _extractPageNumber(entry.text);
          if (entryPageMatch != null && entryPageMatch == pageOnlyMatch) {
            return entry.index;
          }
        }
      }

      // אם no נמצא בcontent העניינים, נחפש בcontent הbook עצמו
      final content = await book.text;
      final lines = content.split('\n');

      // search מדויק
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final cleanLine = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();

        if (isHeaderMatch(cleanLine, headerName)) {
          return i;
        }
      }

      // search לפי page בלבד
      if (pageOnlyMatch != null) {
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final cleanLine = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          final linePageMatch = _extractPageNumber(cleanLine);

          if (linePageMatch != null && linePageMatch == pageOnlyMatch) {
            return i;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('error בsearch כותרת: $e');
      return null;
    }
  }

  /// מחלץ את מbook הpage מכותרת (למשל "page כג א" -> "כג")
  static String? _extractPageNumber(String text) {
    // דפוס לidentify מbook page עברי
    final pagePattern = RegExp(r'page\s+([א-ת]{1,3})');
    final match = pagePattern.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }

    // אם אין "page", ננסה למצוא מbook עברי בתחילת המחרוזת
    final numberPattern = RegExp(r'^([א-ת]{1,3})(?:\s|$)');
    final numberMatch = numberPattern.firstMatch(text.trim());
    if (numberMatch != null) {
      return numberMatch.group(1);
    }

    return null;
  }

  /// check אם text תואם לכותרת המבוקשת
  static bool isHeaderMatch(String text, String headerName) {
    // ניקוי הtextים לצורך השוואה
    final cleanText = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanHeader = headerName.trim().replaceAll(RegExp(r'\s+'), ' ');

    // השוואה מדויקת
    if (cleanText == cleanHeader) {
      return true;
    }

    // השוואה לno רגישות לרווחים
    if (cleanText.replaceAll(' ', '') == cleanHeader.replaceAll(' ', '')) {
      return true;
    }

    // check אם הכותרת מכילה את הtext המבוקש
    if (cleanText.contains(cleanHeader)) {
      return true;
    }

    // check הפוכה - אם הtext המבוקש מכיל את הכותרת
    if (cleanHeader.contains(cleanText)) {
      return true;
    }

    return false;
  }
}
