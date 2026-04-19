import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:otzaria/data/data_providers/book_composite_key.dart';
import 'package:otzaria/data/data_providers/file_system_library_provider.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/data/data_providers/sqlite_data_provider.dart';
import 'package:otzaria/migration/core/models/book.dart' as migration_book;

/// מתווך מרכזי noיתור books בSystem
///
/// function זו מקבלת name book וcategory, ומחפשת את הbook
/// גם ב-DB וגם בfolders, ומחזירה את הbook המתאים.
///
/// זהו המתווך היחיד בין הקוד לבין הנתונים האמיתיים.
class BookLocator {
  /// איתור book לפי name וcategory
  ///
  /// [bookTitle] - name הbook
  /// [category] - הcategory שבה נמצא הbook (אופציונלי)
  ///
  /// מחזיר את הlocation של הbook אם נמצא, או null אם no נמצא
  static Future<BookLocation?> locateBook(
    String bookTitle, {
    Category? category,
    int? categoryId,
  }) async {
    try {
      // previous ננסה למצוא ב-DB
      final dbLocation = await _locateInDatabase(
        bookTitle,
        category,
        categoryId: categoryId,
      );
      if (dbLocation != null) {
        return dbLocation;
      }

      // אם no נמצא ב-DB, נחפש בfolders
      final fileLocation = await _locateInFileSystem(
        bookTitle,
        category,
        categoryId: categoryId,
      );
      return fileLocation;
    } catch (e) {
      debugPrint('❌ Error locating book "$bookTitle": $e');
      return null;
    }
  }

  /// איתור book במסד הנתונים
  static Future<BookLocation?> _locateInDatabase(
    String bookTitle,
    Category? category, {
    int? categoryId,
  }) async {
    final repository = SqliteDataProvider.instance.repository;
    if (repository == null) {
      return null;
    }

    try {
      if (categoryId != null) {
        final dbBook = await repository.getBookByTitleAndCategory(
          bookTitle,
          categoryId,
        );
        if (dbBook != null) {
          return BookLocation(
            book: dbBook,
            source: BookSource.database,
            filePath: null,
            categoryId: dbBook.categoryId,
          );
        }

        return null;
      }

      // אם יש category, נחפש לפי category
      if (category != null) {
        final dbBook = await _findBookInDatabaseByCategory(
          repository,
          bookTitle,
          category,
        );
        if (dbBook != null) {
          return BookLocation(
            book: dbBook,
            source: BookSource.database,
            filePath: null,
            categoryId: dbBook.categoryId,
          );
        }

        return null;
      }

      // אם no מצאנו לפי category, נחפש לפי name בלבד
      final dbBook = await repository.getBookByTitle(bookTitle);
      if (dbBook != null) {
        return BookLocation(
          book: dbBook,
          source: BookSource.database,
          filePath: null,
          categoryId: dbBook.categoryId,
        );
      }
    } catch (e) {
      debugPrint('❌ Error searching in database: $e');
    }

    return null;
  }

  /// search book במסד הנתונים לפי category
  static Future<migration_book.Book?> _findBookInDatabaseByCategory(
    dynamic repository,
    String bookTitle,
    Category category,
  ) async {
    try {
      // מציאת ID של הcategory ב-DB
      final categories = await repository.getRootCategories();
      final categoryId = await _findCategoryIdByPath(
        repository,
        categories,
        category.path,
      );

      if (categoryId != null) {
        // search הbook בcategory הspecificת
        final booksInCategory = await repository.getBooksByCategory(categoryId);
        for (final dbBook in booksInCategory) {
          if (dbBook.title == bookTitle) {
            return dbBook;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error finding book by category in DB: $e');
    }

    return null;
  }

  /// search ID של category לפי path
  static Future<int?> _findCategoryIdByPath(
    dynamic repository,
    List<dynamic> categories,
    String path,
  ) async {
    final pathParts = path.split('/');

    for (final category in categories) {
      if (category.title == pathParts.first) {
        if (pathParts.length == 1) {
          return category.id;
        }
        // search רקורסיבי בתת-categories
        final subCategories = await repository.getCategoryChildren(category.id);
        final remainingPath = pathParts.sublist(1).join('/');
        return await _findCategoryIdByPath(
          repository,
          subCategories,
          remainingPath,
        );
      }
    }
    return null;
  }

  /// איתור book בSystem הfiles
  static Future<BookLocation?> _locateInFileSystem(
    String bookTitle,
    Category? category, {
    int? categoryId,
  }) async {
    try {
      final keyToPath = await FileSystemLibraryProvider.instance.keyToPath;
      String? filePath;

      final resolvedCategoryId = categoryId ??
          category?.path
              .split('/')
              .where((part) => part.isNotEmpty)
              .join(', ')
              .hashCode;

      if (resolvedCategoryId != null) {
        for (final entry in keyToPath.entries) {
          final key = BookCompositeKey.tryParse(entry.key);
          if (key == null) continue;
          if (key.title == bookTitle && key.categoryId == resolvedCategoryId) {
            filePath = entry.value;
            break;
          }
        }

        if (filePath == null) {
          return null;
        }
      }

      // If not found or no category, try fuzzy match by title
      if (filePath == null) {
        for (final entry in keyToPath.entries) {
          final key = BookCompositeKey.tryParse(entry.key);
          if (key == null) continue;
          if (key.title == bookTitle) {
            filePath = entry.value;
            break;
          }
        }
      }

      if (filePath == null) {
        return null;
      }

      // check שהfile קיים
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      return BookLocation(
        book: null,
        source: BookSource.fileSystem,
        filePath: filePath,
        categoryId: null,
      );
    } catch (e) {
      debugPrint('❌ Error searching in file system: $e');
      return null;
    }
  }

  /// מחיקת book (מ-DB או מהfile)
  ///
  /// [bookTitle] - name הbook
  /// [category] - הcategory שבה נמצא הbook (אופציונלי)
  ///
  /// מחזיר true אם הdelete הצליחה, false אחרת
  static Future<bool> deleteBook(
    String bookTitle, {
    Category? category,
    int? categoryId,
  }) async {
    try {
      final location = await locateBook(
        bookTitle,
        category: category,
        categoryId: categoryId,
      );
      if (location == null) {
        debugPrint('❌ Book "$bookTitle" not found');
        return false;
      }

      if (location.source == BookSource.database) {
        return await _deleteFromDatabase(location);
      } else {
        return await _deleteFromFileSystem(location);
      }
    } catch (e) {
      debugPrint('❌ Error deleting book "$bookTitle": $e');
      return false;
    }
  }

  /// מחיקת book ממסד הנתונים
  static Future<bool> _deleteFromDatabase(BookLocation location) async {
    final repository = SqliteDataProvider.instance.repository;
    if (repository == null || location.book == null) {
      return false;
    }

    try {
      await repository.deleteBookCompletely(location.book!.id);
      debugPrint('✅ Book deleted from database: ${location.book!.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting from database: $e');
      return false;
    }
  }

  /// מחיקת file book
  static Future<bool> _deleteFromFileSystem(BookLocation location) async {
    if (location.filePath == null) {
      return false;
    }

    try {
      final file = File(location.filePath!);
      if (!await file.exists()) {
        debugPrint('❌ File not found: ${location.filePath}');
        return false;
      }

      await file.delete();
      debugPrint('✅ File deleted: ${location.filePath}');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      return false;
    }
  }

  /// check אם book קיים
  ///
  /// [bookTitle] - name הbook
  /// [category] - הcategory שבה נמצא הbook (אופציונלי)
  ///
  /// מחזיר true אם הbook קיים, false אחרת
  static Future<bool> bookExists(
    String bookTitle, {
    Category? category,
    int? categoryId,
  }) async {
    final location = await locateBook(
      bookTitle,
      category: category,
      categoryId: categoryId,
    );
    return location != null;
  }

  /// קבלת book מ-DB (אם קיים)
  ///
  /// [bookTitle] - name הbook
  /// [category] - הcategory שבה נמצא הbook (אופציונלי)
  ///
  /// מחזיר את הbook מ-DB אם נמצא, או null אחרת
  static Future<migration_book.Book?> getBookFromDatabase(
    String bookTitle, {
    Category? category,
    int? categoryId,
  }) async {
    final location = await locateBook(
      bookTitle,
      category: category,
      categoryId: categoryId,
    );
    if (location == null || location.source != BookSource.database) {
      return null;
    }
    return location.book;
  }
}

/// location book בSystem
class BookLocation {
  /// הbook מ-DB (אם נמצא ב-DB)
  final migration_book.Book? book;

  /// מקור הbook
  final BookSource source;

  /// path הfile (אם נמצא בfolders)
  final String? filePath;

  /// ID של הcategory ב-DB (אם נמצא ב-DB)
  final int? categoryId;

  BookLocation({
    required this.book,
    required this.source,
    required this.filePath,
    required this.categoryId,
  });
}

/// מקור הbook
enum BookSource {
  /// book נמצא במסד הנתונים
  database,

  /// book נמצא בSystem הfiles
  fileSystem,
}
