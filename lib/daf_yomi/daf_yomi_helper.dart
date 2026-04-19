
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/core/ui_snack.dart';

// Cache של outlines - key: title של הbook, value: outline
final Map<String, List<PdfOutlineNode>> _outlineCache = {};

// Lock mechanism למניעת טעינות מרובות במקביל
final Map<String, Future<List<PdfOutlineNode>>> _loadingOutlines = {};

// Generic tree search for outlines
typedef EntryTextGetter<T> = String Function(T entry);
typedef ChildrenGetter<T> = Future<List<T>> Function(T entry);

Future<T?> findEntryInTree<T>(Future<List<T>> rootEntries, String daf,
    EntryTextGetter<T> getText, ChildrenGetter<T> getChildren) async {
  final entries = await rootEntries;
  for (var entry in entries) {
    String ref = getText(entry);
    if (ref.contains(daf)) {
      return entry;
    }
    T? result =
        await findEntryInTree(getChildren(entry), daf, getText, getChildren);
    if (result != null) return result;
  }
  return null;
}

void openDafYomiBook(BuildContext context, String tractate, String daf,
    {String categoryName = 'Talmud בבלי'}) async {
  _openDafYomiBookInCategory(context, tractate, daf, categoryName);
}

void _openDafYomiBookInCategory(BuildContext context, String tractate,
    String daf, String categoryName) async {
  final libraryBlocState = BlocProvider.of<LibraryBloc>(context).state;
  final library = libraryBlocState.library;

  if (library == null) return;

  // מחפש את הcategory הרלוונטית
  Category? talmudCategory;
  for (var category in library.getAllCategories()) {
    if (category.title == categoryName) {
      talmudCategory = category;
      break;
    }
  }

  if (talmudCategory == null) {
    // נסה לחפש בכל הcategories אם no נמצאה הcategory הspecificת
    final allBooks = library.getAllBooks();
    Book? book;

    // search מדויק יותר - גם בname הfull וגם בsearch חלקי
    for (var bookInLibrary in allBooks) {
      if (bookInLibrary.title == tractate ||
          bookInLibrary.title.contains(tractate) ||
          tractate.contains(bookInLibrary.title)) {
        // בדוק אם הbook נמצא בcategory הנכונה על ידי בדיקת הcategory
        if (bookInLibrary.category?.title == categoryName) {
          book = bookInLibrary;
          break;
        }
      }
    }

    if (book == null) {
      UiSnack.showError('no נמצאה category: $categoryName');
      return;
    } else {
      // נמצא book, נמשיך עם הפתיחה
      await _openBook(context, book, daf);
      return;
    }
  }

  // מחפש את הbook בcategory הspecificת - מעדיף PDF על TXT
  Book? book;
  Book? textBookFallback;
  final allBooksInCategory = talmudCategory.getAllBooks();

  // search מדויק יותר - מעדיף PDF
  for (var bookInCategory in allBooksInCategory) {
    if (bookInCategory.title == tractate ||
        bookInCategory.title.contains(tractate) ||
        tractate.contains(bookInCategory.title)) {
      if (bookInCategory is PdfBook) {
        // מצאנו PDF - זה מה שאנחנו רוצים
        book = bookInCategory;
        break;
      } else {
        // שומרים את ה-TextBook כגיבוי (רק אם עוד no שמרנו)
        textBookFallback ??= bookInCategory;
      }
    }
  }

  // אם no מצאנו PDF, נשתמש ב-TextBook
  book ??= textBookFallback;

  if (book != null) {
    await _openBook(context, book, daf);
  } else {
    // הצג רשימת books זמינים לדיבוג
    final availableBooks =
        allBooksInCategory.map((b) => b.title).take(5).join(', ');
    UiSnack.showError(
        'no נמצא book: $tractate ב$categoryName\nbooks זמינים: $availableBooks...');
  }
}

Future<void> _openBook(BuildContext context, Book book, String daf) async {
  final index = await findReference(book, 'page ${daf.trim()}') ?? 0;
  if (!context.mounted) return;
  openBook(context, book, index, '', ignoreHistory: true);
}

Future<int?> findReference(Book book, String ref) async {
  if (book is TextBook) {
    final tocEntry = await _findDafInToc(book, ref);
    return tocEntry?.index;
  } else if (book is PdfBook) {
    final outline = await getDafYomiOutline(book, ref);
    final pageNum = outline?.dest?.pageNumber;
    return pageNum;
  }
  return null;
}

Future<TocEntry?> _findDafInToc(TextBook book, String daf) async {
  final toc = await book.tableOfContents;
  return await findEntryInTree(
    Future.value(toc),
    daf,
    (entry) => entry.text,
    (entry) => Future.value(entry.children),
  );
}

Future<PdfOutlineNode?> getDafYomiOutline(PdfBook book, String daf) async {
  List<PdfOutlineNode> outlines = const [];
  try {
    // check אם ה-outline כבר ב-cache
    if (_outlineCache.containsKey(book.title)) {
      outlines = _outlineCache[book.title]!;
    } else if (_loadingOutlines.containsKey(book.title)) {
      // אם כבר בתהליך loading, נחכה לתוצאה
      outlines = await _loadingOutlines[book.title]!;
    } else {
      // יצירת Future לloading וsave ב-map
      final loadFuture = _loadOutlineFromFile(book);
      _loadingOutlines[book.title] = loadFuture;

      try {
        outlines = await loadFuture;
        // save ב-cache
        _outlineCache[book.title] = outlines;
      } finally {
        // ניקוי ה-loading map
        _loadingOutlines.remove(book.title);
      }
    }
  } catch (e, stackTrace) {
    debugPrint('❌ getDafYomiOutline error: $e\n$stackTrace');
    _loadingOutlines.remove(book.title);
    return null;
  }

  final result = await findEntryInTree(
    Future.value(outlines),
    daf,
    (entry) => entry.title,
    (entry) => Future.value(entry.children),
  );

  return result;
}

Future<List<PdfOutlineNode>> _loadOutlineFromFile(PdfBook book) async {
  final document = await PdfDocument.openFile(book.path);
  final outlines = await document.loadOutline();
  return outlines;
}

Future<void> openPdfBookFromRef(String bookname, String ref, BuildContext context) async {
  await _openBookFromRefHelper(bookname, ref, context, PdfBook);
}

Future<void> openTextBookFromRef(String bookname, String ref, BuildContext context) async {
  await _openBookFromRefHelper(bookname, ref, context, TextBook);
}

Future<void> _openBookFromRefHelper(
    String bookname, String ref, BuildContext context, Type bookType) async {
  final libraryBlocState = BlocProvider.of<LibraryBloc>(context).state;
  final book = libraryBlocState.library?.findBookByTitle(bookname, bookType);

  if (book != null) {
    final index = await findReference(book, ref);
    if (!context.mounted) return;
    if (index != null) {
      openBook(context, book, index, '', ignoreHistory: true);
    } else {
      UiSnack.showError(UiSnack.sectionNotFound);
    }
  } else {
    UiSnack.showError(UiSnack.bookNotFound);
  }
}
