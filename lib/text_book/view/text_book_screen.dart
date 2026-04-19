import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:otzaria/core/ui_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/core/focus_repository.dart';
import 'package:otzaria/settings/settings_exports.dart' hide UpdateFontSize;
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/data/data_providers/database_library_provider.dart';
// [EDITING DISABLED] import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/data_providers/sqlite_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/printing/printing_screen.dart';
import 'package:otzaria/text_book/view/text_book_scaffold.dart';
import 'package:otzaria/text_book/view/text_book_search_screen.dart';
import 'package:otzaria/text_book/view/toc_navigator_screen.dart';
import 'package:otzaria/text_book/view/alt_toc_sidebar_view.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/data/book_locator.dart';
import 'package:otzaria/utils/page_converter.dart';
import 'package:otzaria/utils/ref_helper.dart';
// [EDITING DISABLED] import 'package:otzaria/text_book/editing/widgets/text_section_editor_dialog.dart';
import 'package:otzaria/text_book/view/book_source_dialog.dart';
// [EDITING DISABLED] import 'package:otzaria/text_book/editing/helpers/editor_settings_helper.dart';
import 'package:otzaria/personal_notes/personal_notes_system.dart';
import 'package:otzaria/shortcuts/shortcut_helper.dart';
import 'package:otzaria/shortcuts/shortcut_validator.dart';
import 'package:otzaria/utils/fullscreen_helper.dart';

import 'package:otzaria/widgets/responsive_action_bar.dart';
import 'package:otzaria/tools/shamor_zachor/providers/shamor_zachor_data_provider.dart';
import 'package:otzaria/tools/shamor_zachor/providers/shamor_zachor_progress_provider.dart';
import 'package:otzaria/tools/shamor_zachor/models/book_model.dart';
import 'package:otzaria/settings/services/per_book_settings_service.dart';
import 'package:otzaria/widgets/app_menu.dart';
import 'package:otzaria/widgets/adaptive_side_pane.dart';
import 'package:otzaria/settings/services/nikud_display_service.dart';
import 'package:otzaria/text_book/view/page_shape/page_shape_settings_dialog.dart';
import 'package:otzaria/text_book/view/page_shape/utils/page_shape_settings_manager.dart';
import 'package:otzaria/text_book/view/page_shape/utils/default_commentators.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// constants למצבי תצוגה (למניעת magic strings)
const String _viewModeSplit = 'split';
const String _viewModeBelow = 'below';
const String _viewModePage = 'page';

class TextBookViewerBloc extends StatefulWidget {
  final void Function(OpenedTab) openBookCallback;
  final TextBookTab tab;
  final bool isInCombinedView;

  const TextBookViewerBloc({
    super.key,
    required this.openBookCallback,
    required this.tab,
    this.isInCombinedView = false,
  });

  @override
  State<TextBookViewerBloc> createState() => _TextBookViewerBlocState();
}

class _TextBookViewerBlocState extends State<TextBookViewerBloc>
    with TickerProviderStateMixin {
  final FocusNode textSearchFocusNode = FocusNode();
  final FocusNode navigationSearchFocusNode = FocusNode();
  final FocusNode _bookContentFocusNode = FocusNode(); // FocusNode לcontent הbook
  late TabController tabController;
  late final ValueNotifier<double> _sidebarWidth;
  late final StreamSubscription<SettingsState> _settingsSub;
  int? _sidebarTabIndex; // אינדקס הכרטיסייה בסרגל הצדי
  bool _isInitialFocusDone = false;
  FocusRepository? _focusRepository; // save הפניה לשימוש ב-dispose
  final GlobalKey _viewModeMenuKey = GlobalKey(); // key לתפריט בחירת התצוגה
  String? _selectedTextForSearch;
  Book? _pdfBook; // Companion PDF
  bool _hasPdfBook = false;
  bool _leftPaneAutoCloseQueuedByScroll = false;

  // Key עבור PageShapeScreen - שינוי הkey יגרום לבנייה again
  Key _pageShapeKey = UniqueKey();

  // RepaintBoundary key עבור הדפסה של "צורת הpage" כפי שמוצג
  final GlobalKey _pageShapePrintBoundaryKey = GlobalKey();

  // בקשות לפתיחת חלונית פנימית ב"צורת הpage": 0=קישורים, 1=notes
  final ValueNotifier<int?> _pageShapeSidebarTabNotifier =
      ValueNotifier<int?>(null);

  // Cache לרשימת אינדקסי TOC ממוינת - למניעת חישוב again בכל tap
  List<int>? _cachedTocIndices;
  String? _cachedTocBookTitle;
  List<TocEntry>? _cachedToc;

  /// Check if book is already being tracked in Shamor Zachor
  bool _isBookTrackedInShamorZachor(String bookTitle) {
    try {
      final dataProvider = context.read<ShamorZachorDataProvider>();
      if (!dataProvider.hasData) {
        return false;
      }

      // Extract clean book name
      String cleanBookName = bookTitle;
      if (bookTitle.contains(' - ')) {
        final parts = bookTitle.split(' - ');
        cleanBookName = parts.last.trim();
      }

      // Search for the book

      // Legacy: Search for the book
      final searchResults = dataProvider.searchBooks(cleanBookName);

      // If found in existing categories, it's tracked
      return searchResults.any((result) =>
          result.bookName == cleanBookName ||
          result.bookName.contains(cleanBookName) ||
          cleanBookName.contains(result.bookName));
    } catch (e) {
      debugPrint('Error checking if book is tracked: $e');
      return false;
    }
  }

  /// סימון V בSave וזכור
  Future<void> _markShamorZachorProgress(String bookTitle) async {
    try {
      final dataProvider = context.read<ShamorZachorDataProvider>();
      final progressProvider = context.read<ShamorZachorProgressProvider>();
      final state = context.read<TextBookBloc>().state as TextBookLoaded;

      if (!dataProvider.hasData) {
        UiSnack.showError('נתוני Save וזכור no נטענו');
        return;
      }

      // check אם יש ID לbook - אם no, נחפש לפי כותרת
      int? bookId = state.book.id;
      if (bookId == null) {
        final dbProvider = SqliteDataProvider.instance;
        if (dbProvider.isInitialized && dbProvider.repository != null) {
          final dbBook = state.book.categoryId != null
              ? await dbProvider.repository!
                  .getBookByTitleAndCategory(bookTitle, state.book.categoryId!)
              : await dbProvider.repository!.getBookByTitle(bookTitle);
          bookId = dbBook?.id;
        }
      }

      if (bookId == null) {
        UiSnack.showError('הbook no נמצא במסד הנתונים');
        return;
      }

      // search הbook לפי ID ב-shamor zachor
      final result = dataProvider.getBookById(bookId);

      if (result == null) {
        UiSnack.showError('הbook no נמצא בSave וזכור');
        return;
      }

      final (bookDetails, bookName, topLevelCategoryKey) = result;
      debugPrint('Book found: $bookName (ID: $bookId)');

      // קבלת הפרק הcurrent
      final currentIndex =
          state.positionsListener.itemPositions.value.isNotEmpty
              ? state.positionsListener.itemPositions.value.first.index
              : 0;

      // קבלת הכותרת הcurrent
      String currentRef =
          await refFromIndex(currentIndex, state.book.tableOfContents);

      // אם הכותרת זהה לname הbook, סימן שאנחנו לפני כל פרק - נחפש את ה-H2 הראשונה
      if (currentRef == state.book.title || currentRef.isEmpty) {
        debugPrint('Current ref is book title, looking for first H2...');
        final toc = await state.book.tableOfContents;

        for (final entry in toc) {
          if (entry.index >= currentIndex) {
            currentRef = entry.text;
            debugPrint('Found first H2: $currentRef');
            break;
          }
          for (final child in entry.children) {
            if (child.index >= currentIndex) {
              currentRef = '${entry.text}, ${child.text}';
              debugPrint('Found first H2 child: $currentRef');
              break;
            }
          }
          if (currentRef != state.book.title && currentRef.isNotEmpty) break;
        }
      }

      debugPrint('Current ref: $currentRef');

      // חילוץ name הפרק מהפניה
      String? chapterName = _extractChapterName(currentRef);

      // אם no הצלחנו לחלץ name פרק, נשתמש בכל הפניה
      if (chapterName == null || chapterName.isEmpty) {
        chapterName = currentRef;
      }

      debugPrint('Chapter name: $chapterName');
      debugPrint('Book content type: ${bookDetails.contentType}');
      debugPrint('Book is daf type: ${bookDetails.isDafType}');
      debugPrint('Total learnable items: ${bookDetails.learnableItems.length}');

      // מציאת הפריט הרלוונטי בSave וזכור
      final learnableItems = bookDetails.learnableItems;

      // search הפריט המתאים לפי name הכותרת (כפי שהיא מופיעה בtext)
      LearnableItem? targetItem;

      // נחפש לפי name הכותרת הcurrent
      final searchTitle = chapterName;

      debugPrint('Searching for title: "$searchTitle"');
      debugPrint('Available learnable items:');
      for (int i = 0; i < learnableItems.length && i < 10; i++) {
        final item = learnableItems[i];
        debugPrint(
            '  [$i] displayLabel: "${item.displayLabel}", partName: "${item.partName}", hierarchyPath: ${item.hierarchyPath}');
      }
      if (learnableItems.length > 10) {
        debugPrint('  ... and ${learnableItems.length - 10} more items');
      }

      try {
        // search לפי displayLabel או partName שמכיל את name הכותרת
        targetItem = learnableItems.firstWhere(
          (item) {
            // check לפי displayLabel
            if (item.displayLabel != null &&
                item.displayLabel!.contains(searchTitle)) {
              return true;
            }
            // check לפי partName
            if (item.partName.contains(searchTitle)) {
              return true;
            }
            // check לפי hierarchyPath
            if (item.hierarchyPath.any((path) => path.contains(searchTitle))) {
              return true;
            }
            return false;
          },
        );
      } catch (e) {
        // אם no מצאנו בsearch מדויק, ננסה search חלקי
        try {
          targetItem = learnableItems.firstWhere(
            (item) {
              final itemTitle = item.displayLabel ?? item.partName;
              final searchWords = searchTitle.split(' ');
              return searchWords
                  .any((word) => word.length > 2 && itemTitle.contains(word));
            },
          );
        } catch (e2) {
          targetItem = null;
        }
      }

      if (targetItem == null) {
        throw Exception('$searchTitle no נמצא בSave וזכור');
      }

      debugPrint(
          'Found target item: displayLabel="${targetItem.displayLabel}", partName="${targetItem.partName}"');

      debugPrint(
          'Target item: ${targetItem.pageNumber}${targetItem.amudKey}, absoluteIndex: ${targetItem.absoluteIndex}');

      // בדיקת מצב הpageות עבור הפרק הspecific - users ב-ID!
      final itemProgress = progressProvider.getProgressForItemById(
          bookId, targetItem.absoluteIndex);

      // מציאת הpageה הראשונה שno מסומנת
      String? columnToMark;
      const columns = ['learn', 'review1', 'review2', 'review3'];

      for (final column in columns) {
        if (!itemProgress.getProperty(column)) {
          columnToMark = column;
          break;
        }
      }

      if (columnToMark == null) {
        UiSnack.show('אין מקום פנוי ב$chapterName, למדת הרבה!');
        return;
      }

      // סימון הפרק הspecific - users ב-ID!
      await progressProvider.updateProgressById(
        bookId,
        targetItem.absoluteIndex,
        columnToMark,
        true,
        bookDetails,
      );

      final columnName = _getColumnDisplayName(columnToMark);
      // השתמש בname המקורי מהכותרת
      final displayName = chapterName;
      UiSnack.show('$displayName סומן כ$columnName בsuccess!');
    } catch (e) {
      debugPrint('Error in _markShamorZachorProgress: $e');
      UiSnack.showError('error בסימון: ${e.toString()}');
    }
  }

  /// חילוץ name הפרק/page מהפניה (לתצוגה)
  String? _extractChapterName(String ref) {
    // examples: "בראשית, פרק א" -> "פרק א", "ברכות, page ו." -> "page ו"

    final patterns = [
      RegExp(r'(פרק\s+[א-ת]+)'),
      RegExp(r'(page\s+[א-ת]+[.:]?)'), // save הנקודה או הנקודתיים
      RegExp(r',\s*([א-ת]+[.:]?)$'), // אם זה רק האות בסוף עם הסימן
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(ref);
      if (match != null) {
        String result = match.group(1) ?? '';
        return result;
      }
    }

    // אם no מצאנו דפוס מיוחד, ננסה לחלץ רק את החלק האחרון
    final parts = ref.split(',');
    if (parts.length > 1) {
      String lastPart = parts.last.trim();
      return lastPart; // save הסימן המקורי
    }

    return null;
  }

  /// קבלת name הpageה להצגה
  String _getColumnDisplayName(String column) {
    switch (column) {
      case 'learn':
        return 'נלמד';
      case 'review1':
        return 'חזרה ראשונה';
      case 'review2':
        return 'חזרה שנייה';
      case 'review3':
        return 'חזרה שלישית';
      default:
        return column;
    }
  }

  Future<Uint8List?> _capturePageShapeViewPng() async {
    final boundaryContext = _pageShapePrintBoundaryKey.currentContext;
    if (boundaryContext == null) return null;

    final renderObject = boundaryContext.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    final pixelRatio = View.of(boundaryContext).devicePixelRatio;

    // ודא שהמסך צויר לפני צילום
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return null;

    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _handlePrintPress(TextBookLoaded state) async {
    if (state.showPageShapeView) {
      final png = await _capturePageShapeViewPng();
      if (!mounted) return;

      final settingsState = context.read<SettingsBloc>().state;

      if (png == null || png.isEmpty) {
        UiSnack.showError('no ניתן לsnapshot את תצוגת "צורת הpage" לצורך הדפסה');
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PrintingScreen(
            // במצב זה ה-PDF created מצילום המסך, ולyes אין צורך בנתוני הtext
            data: Future.value(''),
            bookId: state.book.title,
            removeNikud: state.removeNikud,
            removeTaamim: !settingsState.showTeamim,
            createPdfOverride: (PdfPageFormat format) async {
              final doc = pw.Document(compress: false);
              final img = pw.MemoryImage(png);
              doc.addPage(
                pw.Page(
                  pageFormat: format,
                  margin: pw.EdgeInsets.zero,
                  build: (context) => pw.Center(
                    child: pw.Image(
                      img,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              );
              return doc.save();
            },
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrintingScreen(
          data: Future.value(state.content.join('\n')),
          bookId: state.book.title,
          links: state.links,
          activeCommentators: state.activeCommentators,
          startLine: state.visibleIndices.first,
          removeNikud: state.removeNikud,
          removeTaamim: !context.read<SettingsBloc>().state.showTeamim,
          tableOfContents: state.tableOfContents,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // טעינת נתוני Save וזכור ברקע כדי שהמצב יהיה true בפתיחת book
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<ShamorZachorDataProvider>().ensureLoaded().then((_) {
        if (mounted) {
          context.read<ShamorZachorProgressProvider>().ensureLoaded();
        }
      });
    });

    // רישום ה-FocusNode ב-FocusRepository
    _focusRepository = context.read<FocusRepository>();
    _focusRepository!.registerBookContentFocusNode(_bookContentFocusNode);

    // טעינת settings פר-book
    _loadPerBookSettings();

    DataRepository.instance.library.then((library) {
      if (mounted) {
        setState(() {
          _pdfBook = library.getCompanionBook(widget.tab.book, PdfBook);
          _hasPdfBook = _pdfBook != null;
        });
      }
    });

    final pendingSidebarTab =
        Settings.getValue<int>('key-sidebar-tab-index-pending');
    if (pendingSidebarTab != null && pendingSidebarTab >= 0) {
      _sidebarTabIndex = pendingSidebarTab;
    }

    // וודא שcurrent location נשמר בטאב

    // אם יש text search (searchText), נתחיל בלשונית 'search' (שנמצאת במקום ה-2)
    // אחרת, נתחיל בלשונית 'ניווט' (שנמצאת במקום ה-0)
    // note: נעדyes את זה שוב אחרי הtest של כותרות
    final int initialIndex = widget.tab.searchText.isNotEmpty ? 2 : 0;

    // יוצרים את בקר הלשוניות עם the index ההתחלתי שקבענו
    tabController = TabController(
      length: 3, // ברירת מחדל, יעודyes ב-_checkAltTitles
      vsync: this,
      initialIndex: initialIndex,
    );

    // check האם יש כותרות חלופיות
    _checkAltTitles();

    _sidebarWidth = ValueNotifier<double>(
        Settings.getValue<double>('key-sidebar-width', defaultValue: 300)!);

    // save settings currentות כדי לזהות שינויים
    double previousFontSize = context.read<SettingsBloc>().state.fontSize;
    String previousFontFamily = context.read<SettingsBloc>().state.fontFamily;
    SettingsState previousSettingsState = context.read<SettingsBloc>().state;

    _settingsSub = context.read<SettingsBloc>().stream.listen((state) {
      _sidebarWidth.value = state.sidebarWidth;

      // אם גודל הגופן השתנה, עדyes אותו מיידית
      if (state.fontSize != previousFontSize) {
        previousFontSize = state.fontSize;

        if (!mounted) return;

        final currentState = context.read<TextBookBloc>().state;
        if (currentState is TextBookLoaded) {
          context.read<TextBookBloc>().add(UpdateFontSize(state.fontSize));
        }
      }

      // אם משפחת הגופן או הסרת ניקוד השתנו, טען again את הcontent
      final isNikudSettingsChange = shouldReloadForNikudSettingsChange(
        previous: previousSettingsState,
        current: state,
      );
      if (state.fontFamily != previousFontFamily || isNikudSettingsChange) {
        previousFontFamily = state.fontFamily;
        previousSettingsState = state;

        if (!mounted) return;

        final currentState = context.read<TextBookBloc>().state;
        if (currentState is TextBookLoaded) {
          context.read<TextBookBloc>().add(
                LoadContent(
                  fontSize: state.fontSize,
                  showSplitView: currentState.showSplitView,
                  removeNikud: state.defaultRemoveNikud,
                  forceCloseLeftPane: widget.isInCombinedView,
                  preserveState: true,
                  // save מצב הניקוד הcurrent של הuser רק כשרק הגופן
                  // השתנה - אם settings הניקוד עצמן השתנו, יש להחיל את
                  // הvalue החדש
                  preserveRemoveNikud: !isNikudSettingsChange,
                ),
              );
        }
      } else {
        previousSettingsState = state;
      }
    });
  }

  /// טעינת settings פר-book
  Future<void> _checkAltTitles() async {
    try {
      final structures = await DatabaseLibraryProvider.instance
          .getAlternativeStructuresForBook(widget.tab.book.title);

      if (!mounted) return;

      final hasAltTitles = structures.isNotEmpty;
      if (hasAltTitles != _hasAltTitles) {
        setState(() {
          _hasAltTitles = hasAltTitles;

          // Recreate tab controller with correct length
          final int newLength = hasAltTitles ? 3 : 2;
          // Adjust index if needed
          int newIndex = tabController.index;
          if (newIndex >= newLength) {
            newIndex = newLength - 1;
          }

          tabController.dispose();
          tabController = TabController(
            length: newLength,
            vsync: this,
            initialIndex: newIndex,
          );
        });
      }
    } catch (e) {
      debugPrint('Error checking alt titles: $e');
    }
  }

  Future<void> _loadPerBookSettings() async {
    final settingsBloc = context.read<SettingsBloc>();

    if (!settingsBloc.state.enablePerBookSettings) {
      return;
    }

    final settings = await TextBookPerBookSettings.load(widget.tab.book.title);

    if (settings == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final textBookBloc = context.read<TextBookBloc>();

    // המתן עד שה-TextBookBloc יהיה במצב TextBookLoaded
    await for (final state in textBookBloc.stream) {
      if (state is TextBookLoaded) {
        // החלת הsettings
        if (settings.fontSize != null) {
          textBookBloc.add(UpdateFontSize(settings.fontSize!));
        }
        if (settings.commentatorsBelow != null) {
          textBookBloc.add(ToggleSplitView(!settings.commentatorsBelow!));
        }
        if (settings.removeNikud != null) {
          textBookBloc.add(ToggleNikud(settings.removeNikud!));
        }
        if (settings.removePunctuation != null) {
          textBookBloc.add(TogglePunctuation(settings.removePunctuation!));
        }
        break;
      }
    }
  }

  /// איפוס settings פר-book
  Future<void> _resetPerBookSettings() async {
    await TextBookPerBookSettings.delete(widget.tab.book.title);

    // loading again של הsettings הgeneralות
    if (!mounted) return;
    final settingsBloc = context.read<SettingsBloc>();
    final textBookBloc = context.read<TextBookBloc>();

    textBookBloc.add(LoadContent(
      fontSize: settingsBloc.state.fontSize,
      // בתצוגה משולבת, Commentators תמיד מתחת
      showSplitView: widget.isInCombinedView
          ? false
          : (Settings.getValue<bool>('key-splited-view') ?? false),
      removeNikud: settingsBloc.state.defaultRemoveNikud,
      preserveState: true,
      // בתצוגה משולבת, חלונית הצד תמיד closedה
      forceCloseLeftPane: widget.isInCombinedView,
    ));

    if (mounted) {
      UiSnack.show('הsettings הפר-bookיות אופסו בsuccess');
    }
  }

  bool _hasAltTitles = true; // נניח שיש בstart, נעדyes אחרי check

  @override
  void dispose() {
    // cancel רישום ה-FocusNode מ-FocusRepository (שימוש בהפניה שנשמרה)
    _focusRepository?.unregisterBookContentFocusNode(_bookContentFocusNode);

    tabController.dispose();
    textSearchFocusNode.dispose();
    navigationSearchFocusNode.dispose();
    _bookContentFocusNode.dispose();
    _sidebarWidth.dispose();
    _pageShapeSidebarTabNotifier.dispose();
    _settingsSub.cancel();
    super.dispose();
  }

  void _openPersonalNotesForCurrentView(TextBookLoaded state) {
    if (state.showPageShapeView) {
      _pageShapeSidebarTabNotifier.value = 1;
      return;
    }

    setState(() {
      _sidebarTabIndex = 2;
    });
    context.read<TextBookBloc>().add(const ToggleSplitView(true));
  }

  void _openLeftPaneTab(int index, {String? searchText}) {
    context.read<TextBookBloc>().add(const ToggleLeftPane(true));

    // טיפול מיוחד noינדקס 1 - אם זה אמור להיות search
    // צריך לבדוק אם יש כותרות חלופיות
    int targetIndex = index;
    if (index == 1) {
      // אם מבקשים אינדקס 1, זה יכול להיות search או כותרות
      // נבדוק אם יש כותרות חלופיות - אם yes, search הוא באינדקס 2
      targetIndex = _hasAltTitles ? 2 : 1;

      // אם זה search ויש text, נעדyes את text הsearch
      if (searchText != null && searchText.trim().isNotEmpty) {
        context.read<TextBookBloc>().add(UpdateSearchText(searchText.trim()));
      }
    }

    // וידוא שthe index תקף לפני setting
    final validIndex = targetIndex.clamp(0, tabController.length - 1);
    tabController.index = validIndex;

    // אם זה search, נתן focus לfield הsearch
    if (targetIndex == (_hasAltTitles ? 2 : 1)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          textSearchFocusNode.requestFocus();
        }
      });
    }
  }

  void _onSelectedTextChanged(String? selectedText) {
    _selectedTextForSearch = selectedText;
  }

  void _openSearchFromToolbar() {
    _openLeftPaneTab(1, searchText: _selectedTextForSearch);
  }

  void _openSearchWithText(String? selectedText) {
    _openLeftPaneTab(1,
        searchText: selectedText?.trim().isNotEmpty == true
            ? selectedText
            : _selectedTextForSearch);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocConsumer<TabsBloc, TabsState>(
          listenWhen: (previous, current) =>
              previous.currentTabIndex != current.currentTabIndex,
          listener: (context, tabsState) {
            // בקשת focus כשהטאב הcurrent הוא הטאב של הbook הזה
            // הסרת החזרה אוטומטית של focus כדי noפשר לדיאלוגים וחלוניות לקבל focus
            // final currentTab = tabsState.tabs.isNotEmpty &&
            //         tabsState.currentTabIndex < tabsState.tabs.length
            //     ? tabsState.tabs[tabsState.currentTabIndex]
            //     : null;
            // if (currentTab == widget.tab && mounted) {
            //   WidgetsBinding.instance.addPostFrameCallback((_) {
            //     if (mounted && !_bookContentFocusNode.hasFocus) {
            //       _bookContentFocusNode.requestFocus();
            //     }
            //   });
            // }
          },
          builder: (context, tabsState) {
            // סגירת חלונית הצד כשנמצאים במצב side-by-side
            if (tabsState.isSideBySideMode) {
              final currentState = context.read<TextBookBloc>().state;
              if (currentState is TextBookLoaded && currentState.showLeftPane) {
                // check אם הטאב הcurrent הוא אחד מהטאבים המוצגים
                final currentTabIndex = tabsState.currentTabIndex;
                final isInSideBySide = currentTabIndex ==
                        tabsState.sideBySideMode!.leftTabIndex ||
                    currentTabIndex == tabsState.sideBySideMode!.rightTabIndex;

                if (isInSideBySide) {
                  // סגירה מיידית
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context
                          .read<TextBookBloc>()
                          .add(const ToggleLeftPane(false));
                    }
                  });
                }
              }
            }

            return BlocConsumer<TextBookBloc, TextBookState>(
              bloc: context.read<TextBookBloc>(),
              listener: (context, state) {
                // [EDITING DISABLED]
                // if (state is TextBookLoaded &&
                //     state.isEditorOpen &&
                //     state.editorIndex != null) {
                //   _openEditorDialog(context, state);
                // }

                if (state is TextBookLoaded) {
                  if (!state.showLeftPane) {
                    _leftPaneAutoCloseQueuedByScroll = false;
                  }
                  final pendingSidebarTab =
                      Settings.getValue<int>('key-sidebar-tab-index-pending');
                  if (pendingSidebarTab != null && pendingSidebarTab >= 0) {
                    if (_sidebarTabIndex != pendingSidebarTab) {
                      setState(() {
                        _sidebarTabIndex = pendingSidebarTab;
                      });
                    }
                    if (state.showSplitView) {
                      Settings.setValue<int>(
                          'key-sidebar-tab-index-pending', -1);
                    }
                  } else if (!state.showSplitView && _sidebarTabIndex != null) {
                    setState(() {
                      _sidebarTabIndex = null;
                    });
                  }
                }
              },
              builder: (context, state) {
                if (state is TextBookInitial) {
                  // איפוס אינדקס הכרטיסייה כשטוענים new book
                  final pendingSidebarTab =
                      Settings.getValue<int>('key-sidebar-tab-index-pending');
                  if (_sidebarTabIndex != null &&
                      (pendingSidebarTab == null || pendingSidebarTab < 0)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _sidebarTabIndex = null;
                      });
                    });
                  }

                  context.read<TextBookBloc>().add(
                        LoadContent(
                          fontSize: settingsState.fontSize,
                          // בתצוגה משולבת, Commentators תמיד מתחת (showSplitView = false)
                          // אחרת, users בvalue שנשמר ב-state של הטאב
                          showSplitView: widget.isInCombinedView
                              ? false
                              : state.splitedView,
                          removeNikud: settingsState.defaultRemoveNikud,
                          // בתצוגה משולבת, חלונית הצד תמיד closedה
                          forceCloseLeftPane: widget.isInCombinedView,
                        ),
                      );
                }

                if (state is TextBookInitial || state is TextBookLoading) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  return Scaffold(
                    appBar: AppBar(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      shape: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 0.3,
                        ),
                      ),
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      centerTitle: false,
                      title: Text(
                        widget.tab.book.title,
                        style: const TextStyle(fontSize: 17),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: IconButton(
                        icon: const Icon(FluentIcons.navigation_24_regular),
                        tooltip: "ניווט וsearch",
                        onPressed: null,
                      ),
                      actions: [
                        ResponsiveActionBar(
                          key: ValueKey('loading_actions_$screenWidth'),
                          overflowMenuOffset: const Offset(0, 8),
                          actions: [
                            // NOTE: PDF button intentionally omitted during loading
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(
                                    FluentIcons.panel_left_24_regular),
                                tooltip: 'הצגת Commentators',
                                onPressed: null,
                              ),
                              icon: FluentIcons.panel_left_24_regular,
                              tooltip: 'הצגת Commentators',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(
                                    FluentIcons.text_font_24_regular),
                                tooltip: 'הצג או hide ניקוד',
                                onPressed: null,
                              ),
                              icon: FluentIcons.text_font_24_regular,
                              tooltip: 'הצג או hide ניקוד',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(FluentIcons
                                    .text_clear_formatting_24_regular),
                                tooltip: 'hide פיסוק',
                                onPressed: null,
                              ),
                              icon:
                                  FluentIcons.text_clear_formatting_24_regular,
                              tooltip: 'hide פיסוק',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(FluentIcons.search_24_regular),
                                tooltip: 'search',
                                onPressed: null,
                              ),
                              icon: FluentIcons.search_24_regular,
                              tooltip: 'search',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon:
                                    const Icon(FluentIcons.zoom_in_24_regular),
                                tooltip: 'הגדל את גודל הtext',
                                onPressed: null,
                              ),
                              icon: FluentIcons.zoom_in_24_regular,
                              tooltip: 'הגדל את גודל הtext',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon:
                                    const Icon(FluentIcons.zoom_out_24_regular),
                                tooltip: 'הsmall את גודל הtext',
                                onPressed: null,
                              ),
                              icon: FluentIcons.zoom_out_24_regular,
                              tooltip: 'הsmall את גודל הtext',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(
                                    FluentIcons.arrow_previous_24_filled),
                                tooltip: 'תחילת הbook',
                                onPressed: null,
                              ),
                              icon: FluentIcons.arrow_previous_24_filled,
                              tooltip: 'תחילת הbook',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(
                                    FluentIcons.chevron_left_24_regular),
                                tooltip: 'הקטע הprevious',
                                onPressed: null,
                              ),
                              icon: FluentIcons.chevron_left_24_regular,
                              tooltip: 'הקטע הprevious',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(
                                    FluentIcons.chevron_right_24_regular),
                                tooltip: 'הקטע next',
                                onPressed: null,
                              ),
                              icon: FluentIcons.chevron_right_24_regular,
                              tooltip: 'הקטע next',
                              onPressed: null,
                            ),
                            ActionButtonData(
                              widget: IconButton(
                                icon: const Icon(
                                    FluentIcons.arrow_next_24_filled),
                                tooltip: 'סוף הbook',
                                onPressed: null,
                              ),
                              icon: FluentIcons.arrow_next_24_filled,
                              tooltip: 'סוף הbook',
                              onPressed: null,
                            ),
                          ],
                          // כך שהbutton "..." יוצג גם במצב loading
                          alwaysInMenu: [
                            ActionButtonData(
                              widget: const SizedBox.shrink(),
                              icon: FluentIcons.more_horizontal_24_regular,
                              tooltip: 'actions נוספות',
                              onPressed: null,
                              submenuItems: [
                                ActionButtonData(
                                  widget: const SizedBox.shrink(),
                                  icon: FluentIcons.more_horizontal_24_regular,
                                  tooltip: '',
                                  onPressed: null,
                                ),
                              ],
                            ),
                          ],
                          maxVisibleButtons: screenWidth < 400
                              ? 2
                              : screenWidth < 500
                                  ? 4
                                  : screenWidth < 600
                                      ? 6
                                      : screenWidth < 700
                                          ? 8
                                          : screenWidth < 800
                                              ? 10
                                              : screenWidth < 900
                                                  ? 12
                                                  : screenWidth < 1100
                                                      ? 14
                                                      : 999,
                        ),
                      ],
                    ),
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is TextBookError) {
                  return Center(child: Text('Error: ${(state).message}'));
                }

                if (state is TextBookLoaded) {
                  // בקשת focus אוטומטית כשהbook נטען
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }

                    if (state.showPageShapeView) {
                      if (_bookContentFocusNode.hasFocus) {
                        _bookContentFocusNode.unfocus();
                      }
                      return;
                    }

                    if (!_bookContentFocusNode.hasFocus &&
                        !textSearchFocusNode.hasFocus &&
                        !navigationSearchFocusNode.hasFocus) {
                      _bookContentFocusNode.requestFocus();
                    }
                  });

                  return LayoutBuilder(
                    builder: (context, constrains) {
                      final wideScreen =
                          (MediaQuery.of(context).size.width >= 600);
                      return KeyboardListener(
                        focusNode: _bookContentFocusNode,
                        autofocus: false,
                        onKeyEvent: (event) => _handleGlobalKeyEvent(
                            event, context, state, widget.tab),
                        child: Scaffold(
                          appBar: _buildAppBar(context, state, wideScreen),
                          body: _buildBody(context, state),
                        ),
                      );
                    },
                  );
                }

                // Fallback
                return const Center(child: Text('Unknown state'));
              },
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TextBookLoaded state,
    bool wideScreen,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.3,
        ),
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: _buildTitle(state),
      leadingWidth:
          state.showPageShapeView ? 96 : null, // רוחב מורחב לשני buttons
      leading: state.showPageShapeView
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuButton(context, state),
                _buildPageShapeSettingsButton(context, state),
              ],
            )
          : _buildMenuButton(context, state),
      actions: _buildActions(context, state, wideScreen),
    );
  }

  /// button settings צורת הpage
  Widget _buildPageShapeSettingsButton(
      BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.settings_24_regular, size: 20),
      tooltip: 'settings צורת הpage',
      onPressed: () async {
        // טעינת הsettings הcurrentות
        final config = PageShapeSettingsManager.loadConfiguration(
          state.book.title,
          heCategories: state.book.heCategories,
        );

        // אם אין settings Saveות, נשתמש בברירות מחדל
        final currentSettings = config ??
            await DefaultCommentators.getDefaults(
              state.book,
              availableCommentators: state.availableCommentators,
            );

        if (!context.mounted) return;

        final availableCommentators = state.availableCommentators;
        final bookTitle = state.book.title;
        final hadChanges = await showDialog<bool>(
          context: context,
          builder: (builderContext) => PageShapeSettingsDialog(
            availableCommentators: availableCommentators,
            bookTitle: bookTitle,
            heCategories: state.book.heCategories,
            currentLeft: currentSettings['left'],
            currentRight: currentSettings['right'],
            currentBottom: currentSettings['bottom'],
            currentBottomRight: currentSettings['bottomRight'],
          ),
        );
        // אם היו שינויים, נyear את הkey כדי לגרום ל-PageShapeScreen להיבנות again
        if (hadChanges == true && context.mounted) {
          setState(() {
            _pageShapeKey = UniqueKey();
          });
        }
      },
    );
  }

  Widget _buildTitle(TextBookLoaded state) {
    if (state.currentTitle == null) {
      return const SizedBox.shrink();
    }

    const titleStyle = TextStyle(fontSize: 17);
    const authorStyle = TextStyle(fontSize: 12, color: Colors.grey);

    // שימוש בfunction העזר להוספת name הbook
    String displayText =
        addBookTitleToRef(state.currentTitle!, state.book.title);

    final author = state.book.author;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: displayText, style: titleStyle),
          maxLines: 1,
          textDirection: TextDirection.rtl,
        )..layout(minWidth: 0, maxWidth: constraints.maxWidth);

        final titleWidget = SelectionArea(
          child: Text(
            displayText,
            style: titleStyle,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

        // אם יש מחבר, מציגים אותו מתחת לכותרת
        final child = author != null && author.isNotEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  Text(
                    author,
                    style: authorStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : titleWidget;

        if (textPainter.didExceedMaxLines) {
          return Tooltip(
            message: author != null ? '$displayText\n$author' : displayText,
            child: child,
          );
        }

        return child;
      },
    );
  }

  Widget _buildMenuButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.navigation_24_regular),
      tooltip: "ניווט וsearch",
      onPressed: () =>
          context.read<TextBookBloc>().add(ToggleLeftPane(!state.showLeftPane)),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    TextBookLoaded state,
    bool wideScreen,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    // נקבע כמה buttons להציג בהתאם לרוחב המסך
    // שים לב: הbuttons יוסתרו בorder ההצגה (מימין לשמאל, כך שהימני ביותר יעלם אחרון)
    int maxButtons;

    if (screenWidth < 400) {
      maxButtons = 2; // 2 buttons + "..." במסכים קטנים מאוד
    } else if (screenWidth < 500) {
      maxButtons = 4; // 4 buttons + "..." במסכים קטנים
    } else if (screenWidth < 600) {
      maxButtons = 6; // 6 buttons + "..." במסכים mediumים קטנים
    } else if (screenWidth < 700) {
      maxButtons = 8; // 8 buttons + "..." במסכים mediumים
    } else if (screenWidth < 800) {
      maxButtons = 10; // 10 buttons + "..." במסכים mediumים largeים
    } else if (screenWidth < 900) {
      maxButtons = 12; // 12 buttons + "..." במסכים largeים
    } else if (screenWidth < 1100) {
      maxButtons = 14; // 14 buttons + "..." במסכים largeים יותר
    } else {
      maxButtons =
          999; // כל הbuttons החיצוניים במסכים רחבים מאוד (ה-5 הconstants תמיד בתפריט)
    }

    return [
      Consumer<ShamorZachorDataProvider>(
        builder: (context, _, __) => ResponsiveActionBar(
          key: ValueKey('responsive_actions_$screenWidth'),
          overflowMenuOffset: const Offset(0, 8),
          actions: _buildDisplayOrderActions(context, state),
          alwaysInMenu: _buildAlwaysInMenuActions(context, state),
          maxVisibleButtons: maxButtons,
        ),
      ),
    ];
  }

  /// בניית רשימת buttons בorder ההצגה (מימין לשמאל ב-RTL)
  /// הbuttons יוסתרו מהסוף לתחילה, כך שהbutton הימני ביותר (ראשון בlist) יעלם אחרון
  List<ActionButtonData> _buildDisplayOrderActions(
    BuildContext context,
    TextBookLoaded state,
  ) {
    return [
      // 1) PDF Button (ראשון מימין - יעלם אחרון!)
      if (_hasPdfBook)
        ActionButtonData(
          widget: IconButton(
            icon: const Icon(FluentIcons.document_pdf_24_regular),
            tooltip: 'Open book במהדורה מודפסת',
            onPressed: () => _handlePdfButtonPress(context, state),
          ),
          icon: FluentIcons.document_pdf_24_regular,
          tooltip: 'Open book במהדורה מודפסת',
          onPressed: () => _handlePdfButtonPress(context, state),
        ),

      // 2) View Mode Dropdown (מאחד את Split View ו-Page Shape View)
      ActionButtonData(
        widget: _buildViewModeDropdown(context, state, key: _viewModeMenuKey),
        icon: _getViewModeIcon(state),
        tooltip: _getViewModeTooltip(state),
        onPressed: () {
          // פתיחת התפריט באופן פרוגרמטי (למקרה שהbutton עבר לתפריט overflow)
          final dynamic menuState = _viewModeMenuKey.currentState;
          menuState?.showButtonMenu();
        },
      ),

      // 3) Nikud Button
      ActionButtonData(
        widget: _buildNikudButton(context, state),
        icon: state.removeNikud
            ? FluentIcons.text_font_24_regular
            : FluentIcons.text_font_info_24_regular,
        tooltip: state.removeNikud ? 'הצג ניקוד' : 'hide ניקוד',
        onPressed: () async {
          final newValue = !state.removeNikud;
          context.read<TextBookBloc>().add(ToggleNikud(newValue));
          await _savePerBookSettingsDirectly(context, state,
              removeNikud: newValue);
        },
      ),

      // 3b) Punctuation Button - מוסתר בbookי Written Torah
      if (!state.isTanach)
        ActionButtonData(
          widget: _buildPunctuationButton(context, state),
          icon: state.removePunctuation
              ? FluentIcons.text_quote_24_regular
              : FluentIcons.text_clear_formatting_24_regular,
          tooltip: state.removePunctuation ? 'הצג פיסוק' : 'hide פיסוק',
          onPressed: () => _toggleAndSavePunctuation(context, state),
        ),

      // 4) Search Button
      ActionButtonData(
        widget: _buildSearchButton(context, state),
        icon: FluentIcons.search_24_regular,
        tooltip: 'search',
        onPressed: _openSearchFromToolbar,
      ),

      // 5) Zoom In Button
      ActionButtonData(
        widget: _buildZoomInButton(context, state),
        icon: FluentIcons.zoom_in_24_regular,
        tooltip: 'הגדל את גודל הtext',
        onPressed: () async {
          final newSize = min(50.0, state.fontSize + 3);
          context.read<TextBookBloc>().add(UpdateFontSize(newSize));
          await _savePerBookSettingsDirectly(context, state, fontSize: newSize);
        },
      ),

      // 6) Zoom Out Button
      ActionButtonData(
        widget: _buildZoomOutButton(context, state),
        icon: FluentIcons.zoom_out_24_regular,
        tooltip: 'הsmall את גודל הtext',
        onPressed: () async {
          final newSize = max(15.0, state.fontSize - 3);
          context.read<TextBookBloc>().add(UpdateFontSize(newSize));
          await _savePerBookSettingsDirectly(context, state, fontSize: newSize);
        },
      ),

      // 7) Navigation Buttons - רק אם no בתצוגה משולבת
      if (!widget.isInCombinedView) ...[
        ActionButtonData(
          widget: _buildPreviousTocButton(state),
          icon: FluentIcons.arrow_previous_24_filled,
          tooltip: 'הpage/פרק הprevious',
          onPressed: () => _navigateToPreviousToc(state),
        ),
        ActionButtonData(
          widget: _buildPreviousPageButton(state),
          icon: FluentIcons.chevron_left_24_regular,
          tooltip: 'הקטע הprevious',
          onPressed: () {
            state.scrollController.scrollTo(
              duration: const Duration(milliseconds: 300),
              index: max(
                0,
                state.positionsListener.itemPositions.value.first.index - 1,
              ),
            );
          },
        ),
        ActionButtonData(
          widget: _buildNextPageButton(state),
          icon: FluentIcons.chevron_right_24_regular,
          tooltip: 'הקטע next',
          onPressed: () {
            state.scrollController.scrollTo(
              index: max(
                state.positionsListener.itemPositions.value.first.index + 1,
                state.positionsListener.itemPositions.value.length - 1,
              ),
              duration: const Duration(milliseconds: 300),
            );
          },
        ),
        ActionButtonData(
          widget: _buildNextTocButton(state),
          icon: FluentIcons.arrow_next_24_filled,
          tooltip: 'הpage/פרק next',
          onPressed: () => _navigateToNextToc(state),
        ),
      ],
    ];
  }

  /// buttons שתמיד יהיו בתפריט "..." (בorder הרצוי)
  List<ActionButtonData> _buildAlwaysInMenuActions(
    BuildContext context,
    TextBookLoaded state,
  ) {
    return [
      // buttonי ניווט - רק בתצוגה משולבת
      if (widget.isInCombinedView) ...[
        ActionButtonData(
          widget: _buildPreviousTocButton(state),
          icon: FluentIcons.arrow_previous_24_filled,
          tooltip: 'הpage/פרק הprevious',
          onPressed: () => _navigateToPreviousToc(state),
        ),
        ActionButtonData(
          widget: _buildPreviousPageButton(state),
          icon: FluentIcons.chevron_left_24_regular,
          tooltip: 'הקטע הprevious',
          onPressed: () {
            state.scrollController.scrollTo(
              duration: const Duration(milliseconds: 300),
              index: max(
                0,
                state.positionsListener.itemPositions.value.first.index - 1,
              ),
            );
          },
        ),
        ActionButtonData(
          widget: _buildNextPageButton(state),
          icon: FluentIcons.chevron_right_24_regular,
          tooltip: 'הקטע next',
          onPressed: () {
            state.scrollController.scrollTo(
              index: max(
                state.positionsListener.itemPositions.value.first.index + 1,
                state.positionsListener.itemPositions.value.length - 1,
              ),
              duration: const Duration(milliseconds: 300),
            );
          },
        ),
        ActionButtonData(
          widget: _buildNextTocButton(state),
          icon: FluentIcons.arrow_next_24_filled,
          tooltip: 'הpage/פרק next',
          onPressed: () => _navigateToNextToc(state),
        ),
      ],

      // 1) הוספת סימניה
      ActionButtonData(
        widget: _buildBookmarkButton(context, state),
        icon: FluentIcons.bookmark_add_24_regular,
        tooltip: 'Add סימניה',
        onPressed: () => _handleBookmarkPress(context, state),
      ),

      // 2) הצג notes אישיות
      ActionButtonData(
        widget: IconButton(
          onPressed: () => _openPersonalNotesForCurrentView(state),
          icon: const Icon(FluentIcons.note_24_regular),
          tooltip: 'הצג notes אישיות',
        ),
        icon: FluentIcons.note_24_regular,
        tooltip: 'הצג notes אישיות',
        onPressed: () => _openPersonalNotesForCurrentView(state),
      ),

      // 3) Save וזכור - סמן כנלמד או Add למעקב
      ActionButtonData(
        widget: _buildShamorZachorButton(context, state),
        icon: _isBookTrackedInShamorZachor(state.book.title)
            ? FluentIcons.checkmark_circle_24_regular
            : FluentIcons.add_circle_24_regular,
        tooltip: _isBookTrackedInShamorZachor(state.book.title)
            ? 'סמן קטע open כנלמד בSave וזכור'
            : 'Add למעקב לימוד בSave וזכור',
        onPressed: () {
          if (_isBookTrackedInShamorZachor(state.book.title)) {
            _markShamorZachorProgress(state.book.title);
          } else {
            _addBookToShamorZachorTracking(state.book);
          }
        },
      ),

      // 4) איפוס settings פר-book (מוצג רק כשהsetting activeת) - no בתצוגה משולבת
      if (!widget.isInCombinedView &&
          context.read<SettingsBloc>().state.enablePerBookSettings)
        ActionButtonData(
          widget: IconButton(
            icon: const Icon(FluentIcons.arrow_reset_24_regular),
            tooltip: 'אפס settings book זה',
            onPressed: () => _resetPerBookSettings(),
          ),
          icon: FluentIcons.arrow_reset_24_regular,
          tooltip: 'אפס settings book זה',
          onPressed: () => _resetPerBookSettings(),
        ),

      // [EDITING DISABLED]
      // // 5) ערוך את הbook - no בתצוגה משולבת
      // if (!widget.isInCombinedView)
      //   ActionButtonData(
      //     widget: _buildFullFileEditorButton(context, state),
      //     icon: FluentIcons.document_edit_24_regular,
      //     tooltip: 'ערוך את הbook',
      //     onPressed: () => _handleFullFileEditorPress(context, state),
      //   ),

      // 6) הדפסה - no בתצוגה משולבת
      if (!widget.isInCombinedView)
        ActionButtonData(
          widget: _buildPrintButton(context, state),
          icon: FluentIcons.print_24_regular,
          tooltip: 'הדפסה',
          onPressed: () => _handlePrintPress(state),
        ),

      // 7) About הbook - no בתצוגה משולבת
      if (!widget.isInCombinedView)
        ActionButtonData(
          widget: IconButton(
            icon: const Icon(FluentIcons.info_24_regular),
            tooltip: 'About הbook',
            onPressed: () => showBookSourceDialog(context, state),
          ),
          icon: FluentIcons.info_24_regular,
          tooltip: 'About הbook',
          onPressed: () => showBookSourceDialog(context, state),
        ),

      // תת-תפריט "actions נוספות" - רק בתצוגה משולבת
      if (widget.isInCombinedView)
        ActionButtonData(
          widget: const SizedBox.shrink(), // no נראה כי זה בתפריט
          icon: FluentIcons.more_horizontal_24_regular,
          tooltip: 'actions נוספות',
          onPressed: null, // no ניתן לtap - זה submenu
          submenuItems: [
            // איפוס settings פר-book (מוצג רק כשהsetting activeת)
            if (context.read<SettingsBloc>().state.enablePerBookSettings)
              ActionButtonData(
                widget: const SizedBox.shrink(),
                icon: FluentIcons.arrow_reset_24_regular,
                tooltip: 'אפס settings book זה',
                onPressed: () => _resetPerBookSettings(),
              ),
            // [EDITING DISABLED]
            // ActionButtonData(
            //   widget: const SizedBox.shrink(),
            //   icon: FluentIcons.document_edit_24_regular,
            //   tooltip: 'ערוך את הbook',
            //   onPressed: () => _handleFullFileEditorPress(context, state),
            // ),
            ActionButtonData(
              widget: const SizedBox.shrink(),
              icon: FluentIcons.print_24_regular,
              tooltip: 'הדפסה',
              onPressed: () => _handlePrintPress(state),
            ),
            ActionButtonData(
              widget: const SizedBox.shrink(),
              icon: FluentIcons.info_24_regular,
              tooltip: 'About הbook',
              onPressed: () => showBookSourceDialog(context, state),
            ),
          ],
        ),
    ];
  }

  /// קבלת האייקון המתאים למצב התצוגה הcurrent
  IconData _getViewModeIcon(TextBookLoaded state) {
    if (state.showPageShapeView) {
      return FluentIcons.book_open_24_filled;
    }
    // Commentators בצד/מתחת - אותו אייקון (הסיבוב מתבצע מחוץ לfunction)
    return FluentIcons.panel_left_24_regular;
  }

  /// קבלת ה-tooltip למצב התצוגה הcurrent
  String _getViewModeTooltip(TextBookLoaded state) {
    if (state.showPageShapeView) {
      return 'תצוגה: צורת הpage';
    } else if (state.showSplitView) {
      return 'תצוגה: Commentators בצד';
    } else {
      return 'תצוגה: Commentators מתחת';
    }
  }

  /// בניית תפריט נOpen לבחירת מצב תצוגה
  Widget _buildViewModeDropdown(BuildContext context, TextBookLoaded state,
      {Key? key}) {
    // אייקון מסובב כשCommentators מתחת
    final iconWidget = state.showPageShapeView
        ? Icon(_getViewModeIcon(state))
        : RotatedBox(
            quarterTurns: state.showSplitView ? 0 : 3,
            child: Icon(_getViewModeIcon(state)),
          );

    final isSplit = !state.showPageShapeView && state.showSplitView;
    final isBelow = !state.showPageShapeView && !state.showSplitView;
    final isPage = state.showPageShapeView;

    return AppPopupMenuButton<String>(
      key: key,
      tooltip: 'בחר סוג תצוגת Commentators',
      icon: iconWidget,
      enabled: !widget.isInCombinedView,
      initialValue: state.showPageShapeView
          ? _viewModePage
          : (state.showSplitView ? _viewModeSplit : _viewModeBelow),
      onSelected: (value) async {
        final bloc = context.read<TextBookBloc>();

        // קביעת מצב היעד לפי הבחירה
        final bool isPageSelected = value == _viewModePage;
        final bool isSplitSelected = value == _viewModeSplit;

        // update תצוגת צורת הpage במידת הצורך
        if (isPageSelected != state.showPageShapeView) {
          bloc.add(TogglePageShapeView(isPageSelected));
        }

        // update תצוגת הCommentators במידת הצורך (רק במצבים שאינם 'צורת הpage')
        if (!isPageSelected && isSplitSelected != state.showSplitView) {
          bloc.add(ToggleSplitView(isSplitSelected));
          await _savePerBookSettingsDirectly(context, state,
              showSplitView: isSplitSelected);
        }
      },
      entries: [
        AppMenuEntry(
          value: _viewModeSplit,
          label: 'Commentators בצד',
          icon: isSplit
              ? FluentIcons.panel_left_24_filled
              : FluentIcons.panel_left_24_regular,
        ),
        AppMenuEntry(
          value: _viewModeBelow,
          label: 'Commentators מתחת',
          icon: isBelow
              ? FluentIcons.panel_left_24_filled
              : FluentIcons.panel_left_24_regular,
        ),
        AppMenuEntry(
          value: _viewModePage,
          label: 'צורת הpage',
          icon: isPage
              ? FluentIcons.book_open_24_filled
              : FluentIcons.book_open_24_regular,
        ),
      ],
    );
  }

  Widget _buildNikudButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () async {
        final newValue = !state.removeNikud;
        context.read<TextBookBloc>().add(ToggleNikud(newValue));
        // save עם הvalue החדש
        await _savePerBookSettingsDirectly(context, state,
            removeNikud: newValue);
      },
      icon: Icon(state.removeNikud
          ? FluentIcons.text_font_24_regular
          : FluentIcons.text_font_info_24_regular),
      tooltip: state.removeNikud ? 'הצג ניקוד' : 'hide ניקוד',
    );
  }

  Future<void> _toggleAndSavePunctuation(
      BuildContext context, TextBookLoaded state) async {
    final newValue = !state.removePunctuation;
    context.read<TextBookBloc>().add(TogglePunctuation(newValue));
    await _savePerBookSettingsDirectly(context, state,
        removePunctuation: newValue);
  }

  Widget _buildPunctuationButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () => _toggleAndSavePunctuation(context, state),
      icon: Icon(state.removePunctuation
          ? FluentIcons.text_quote_24_regular
          : FluentIcons.text_clear_formatting_24_regular),
      tooltip: state.removePunctuation ? 'הצג פיסוק' : 'hide פיסוק',
    );
  }

  Widget _buildBookmarkButton(BuildContext context, TextBookLoaded state) {
    final shortcut =
        Settings.getValue<String>('key-shortcut-add-bookmark') ?? 'ctrl+b';
    return IconButton(
      onPressed: () async {
        int index = state.positionsListener.itemPositions.value.first.index;
        final toc = state.book.tableOfContents;
        String ref = await refFromIndex(index, toc);
        // הוספת name הbook לכותרת
        ref = addBookTitleToRef(ref, state.book.title);
        if (!mounted || !context.mounted) return;

        bool bookmarkAdded = context.read<BookmarkBloc>().addBookmark(
              ref: ref,
              book: state.book,
              index: index,
              commentatorsToShow: state.activeCommentators,
            );
        UiSnack.showQuick(
            bookmarkAdded ? 'הסימניה נוספה בsuccess' : 'הסימניה כבר קיימת');
      },
      icon: const Icon(FluentIcons.bookmark_add_24_regular),
      tooltip: 'Add סימניה (${shortcut.toUpperCase()})',
    );
  }

  Widget _buildSearchButton(BuildContext context, TextBookLoaded state) {
    final shortcut = ShortcutValidator.getShortcutValue(
          ShortcutValidator.currentWindowSearchKey,
        ) ??
        'ctrl+f';
    return IconButton(
      onPressed: _openSearchFromToolbar,
      icon: const Icon(FluentIcons.search_24_regular),
      tooltip: 'search (${shortcut.toUpperCase()})',
    );
  }

  Widget _buildZoomInButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.zoom_in_24_regular),
      tooltip: 'הגדל את גודל הtext (CTRL + +)',
      onPressed: () async {
        final newSize = min(50.0, state.fontSize + 3);
        context.read<TextBookBloc>().add(UpdateFontSize(newSize));
        await _savePerBookSettingsDirectly(context, state, fontSize: newSize);
      },
    );
  }

  Widget _buildZoomOutButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.zoom_out_24_regular),
      tooltip: 'הsmall את גודל הtext (CTRL + -)',
      onPressed: () async {
        final newSize = max(15.0, state.fontSize - 3);
        context.read<TextBookBloc>().add(UpdateFontSize(newSize));
        await _savePerBookSettingsDirectly(context, state, fontSize: newSize);
      },
    );
  }

  Widget _buildPreviousPageButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.chevron_left_24_regular),
      tooltip: 'הקטע הprevious',
      onPressed: () {
        state.scrollController.scrollTo(
          duration: const Duration(milliseconds: 300),
          index: max(
            0,
            state.positionsListener.itemPositions.value.first.index - 1,
          ),
        );
      },
    );
  }

  Widget _buildNextPageButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.chevron_right_24_regular),
      tooltip: 'הקטע next',
      onPressed: () {
        state.scrollController.scrollTo(
          index: max(
            state.positionsListener.itemPositions.value.first.index + 1,
            state.positionsListener.itemPositions.value.length - 1,
          ),
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  /// מחזיר list ממוינת של כל אינדקסי ה-TOC (עם cache)
  List<int> _getSortedTocIndices(List<TocEntry> entries, String bookTitle) {
    // אם יש cache תקף, נשתמש בו (בודקים גם את זהות רשימת ה-TOC)
    if (_cachedTocIndices != null &&
        _cachedTocBookTitle == bookTitle &&
        identical(_cachedToc, entries)) {
      return _cachedTocIndices!;
    }

    // יוצרים list שטוחה של כל the indexים
    final allIndices = <int>[];

    void collectIndices(List<TocEntry> toc) {
      for (final entry in toc) {
        allIndices.add(entry.index);
        collectIndices(entry.children);
      }
    }

    collectIndices(entries);
    allIndices.sort();

    // שומרים ב-cache
    _cachedTocIndices = allIndices;
    _cachedTocBookTitle = bookTitle;
    _cachedToc = entries;

    return allIndices;
  }

  /// מוצא את הכותרת nextה (page/פרק) מתוך content העניינים
  /// מחזיר את the index של הכותרת nextה, או null אם אין
  int? _findNextTocIndex(
      List<TocEntry> entries, int currentIndex, String bookTitle) {
    final allIndices = _getSortedTocIndices(entries, bookTitle);

    // search בינארי יעיל יותר
    int low = 0;
    int high = allIndices.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (allIndices[mid] <= currentIndex) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return low < allIndices.length ? allIndices[low] : null;
  }

  /// מוצא את הכותרת הקודמת (page/פרק) מתוך content העניינים
  /// מחזיר את the index של הכותרת הקודמת, או null אם אין
  int? _findPreviousTocIndex(
      List<TocEntry> entries, int currentIndex, String bookTitle) {
    final allIndices = _getSortedTocIndices(entries, bookTitle);

    // search בינארי יעיל יותר
    int low = 0;
    int high = allIndices.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (allIndices[mid] < currentIndex) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return high >= 0 ? allIndices[high] : null;
  }

  /// ניווט לכותרת הקודמת ב-TOC
  void _navigateToPreviousToc(TextBookLoaded state) {
    final currentIndex = state.positionsListener.itemPositions.value.isNotEmpty
        ? state.positionsListener.itemPositions.value.first.index
        : 0;
    final prevIndex = _findPreviousTocIndex(
        state.tableOfContents, currentIndex, state.book.title);
    if (prevIndex != null) {
      state.scrollController.scrollTo(
        index: prevIndex,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  /// ניווט לכותרת nextה ב-TOC
  void _navigateToNextToc(TextBookLoaded state) {
    final currentIndex = state.positionsListener.itemPositions.value.isNotEmpty
        ? state.positionsListener.itemPositions.value.first.index
        : 0;
    final nextIndex = _findNextTocIndex(
        state.tableOfContents, currentIndex, state.book.title);
    if (nextIndex != null) {
      state.scrollController.scrollTo(
        index: nextIndex,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Widget _buildPreviousTocButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.arrow_previous_24_filled),
      tooltip: 'הpage/פרק הprevious',
      onPressed: () => _navigateToPreviousToc(state),
    );
  }

  Widget _buildNextTocButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.arrow_next_24_filled),
      tooltip: 'הpage/פרק next',
      onPressed: () => _navigateToNextToc(state),
    );
  }

  Widget _buildPrintButton(BuildContext context, TextBookLoaded state) {
    final shortcut =
        Settings.getValue<String>('key-shortcut-print') ?? 'ctrl+p';
    return IconButton(
      icon: const Icon(FluentIcons.print_24_regular),
      tooltip: 'הדפסה (${shortcut.toUpperCase()})',
      onPressed: () {
        final settingsState = context.read<SettingsBloc>().state;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PrintingScreen(
              data: Future.value(state.content.join('\n')),
              bookId: state.book.title,
              links: state.links,
              activeCommentators: state.activeCommentators,
              startLine: state.visibleIndices.first,
              removeNikud: state.removeNikud,
              removeTaamim: !settingsState.showTeamim,
              tableOfContents: state.tableOfContents,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShamorZachorButton(BuildContext context, TextBookLoaded state) {
    final isTracked = _isBookTrackedInShamorZachor(state.book.title);
    return IconButton(
      onPressed: () {
        if (isTracked) {
          _markShamorZachorProgress(state.book.title);
        } else {
          _addBookToShamorZachorTracking(state.book);
        }
      },
      icon: isTracked
          ? Image.asset(
              'assets/icon/shamor_zachor_with_v.png',
              width: 24,
              height: 24,
            )
          : const Icon(FluentIcons.add_circle_24_regular, size: 24),
      tooltip: isTracked
          ? 'סמן קטע open כנלמד בSave וזכור'
          : 'Add למעקב לימוד בSave וזכור',
    );
  }

  /// Add book to Shamor Zachor tracking
  Future<void> _addBookToShamorZachorTracking(Book book) async {
    try {
      final dataProvider = context.read<ShamorZachorDataProvider>();

      final bookTitle = book.title;

      // 1. Get book path from library or database
      String? bookPath = book.filePath;

      if (bookPath == null) {
        final location = await BookLocator.locateBook(
          bookTitle,
          categoryId: book.categoryId,
        );
        bookPath = location?.filePath;
      }

      // If not found in file system, try to get category from database
      if (bookPath == null) {
        String categoryPath = '';
        // Try to use the category path from the book object first
        if (book.categoryPath != null && book.categoryPath!.isNotEmpty) {
          categoryPath = book.categoryPath!.replaceAll(', ', '/');
        } else {
          final dbProvider = SqliteDataProvider.instance;
          if (await dbProvider.databaseExists() && dbProvider.isInitialized) {
            try {
              final repository = dbProvider.repository;
              if (repository != null) {
                final dbBook = book.categoryId != null
                    ? await repository.getBookByTitleAndCategory(
                        bookTitle, book.categoryId!)
                    : await repository.getBookByTitle(bookTitle);
                if (dbBook != null) {
                  final category =
                      await repository.getCategory(dbBook.categoryId);
                  if (category != null) {
                    final categoryParts = <String>[];
                    dynamic currentCategory = category;
                    while (currentCategory != null) {
                      categoryParts.insert(0, currentCategory.title);
                      if (currentCategory.parentId != null) {
                        currentCategory = await repository
                            .getCategory(currentCategory.parentId!);
                      } else {
                        break;
                      }
                    }
                    categoryPath = categoryParts.join('/');
                  }
                }
              }
            } catch (e) {
              debugPrint('Error getting category from DB: $e');
            }
          }
        }

        if (categoryPath.isNotEmpty) {
          final libraryPath =
              Settings.getValue<String>('key-library-path') ?? '.';
          bookPath =
              '$libraryPath${Platform.pathSeparator}Otzaria${Platform.pathSeparator}$categoryPath${Platform.pathSeparator}$bookTitle.txt';
          debugPrint('Book path from DB: $bookPath');
        }
      }

      if (bookPath == null) {
        UiSnack.showError('no נמצא path לbook');
        return;
      }

      debugPrint('Adding book to tracking - Path: $bookPath');

      // 2. Use the actual book title as-is (don't modify it)
      // The title should match exactly what's in the DB
      String cleanBookName = bookTitle;

      // 3. Show loading indicator
      UiSnack.show('מוסיף book למעקב...');

      // 4. Add book via provider (only needs book name)
      await dataProvider.addCustomBook(
        bookName: cleanBookName,
        categoryId: book.categoryId,
      );

      // 5. Success message
      UiSnack.show('הbook "$cleanBookName" נוסף למעקב בsuccess!');

      // 6. Update UI to reflect the change
      setState(() {});
    } catch (e, stackTrace) {
      debugPrint('Error adding book to Shamor Zachor: $e');
      debugPrint('Stack trace: $stackTrace');
      UiSnack.showError('error בהוספת הbook למעקב: ${e.toString()}');
    }
  }

  /// functions עזר לטיפול בלחיצות על buttons בתפריט הנOpen
  void _handlePdfButtonPress(BuildContext context, TextBookLoaded state) async {
    if (_pdfBook == null) {
      UiSnack.showError('no נמצא book PDF עבור "${state.book.title}"');
      return;
    }

    final currentIndex = state.positionsListener.itemPositions.value.isNotEmpty
        ? state.positionsListener.itemPositions.value.first.index
        : 0;
    widget.tab.index = currentIndex;

    final index = await textToPdfPage(state.book, currentIndex);

    if (!context.mounted) return;

    openBook(context, _pdfBook!, index ?? 1, '', ignoreHistory: true);
  }

  void _handleBookmarkPress(BuildContext context, TextBookLoaded state) async {
    final index = state.positionsListener.itemPositions.value.first.index;
    final toc = state.book.tableOfContents;
    final bookmarkBloc = context.read<BookmarkBloc>();
    String ref = await refFromIndex(index, toc);
    // הוספת name הbook לכותרת
    ref = addBookTitleToRef(ref, state.book.title);
    if (!mounted || !context.mounted) return;

    final bookmarkAdded = bookmarkBloc.addBookmark(
      ref: ref,
      book: state.book,
      index: index,
      commentatorsToShow: state.activeCommentators,
    );

    UiSnack.showQuick(
        bookmarkAdded ? 'הסימניה נוספה בsuccess' : 'הסימניה כבר קיימת');
  }

  Widget _buildBody(
    BuildContext context,
    TextBookLoaded state,
  ) {
    return ValueListenableBuilder<double>(
      valueListenable: _sidebarWidth,
      builder: (context, width, child) => AdaptiveSidePane(
        isOpen: state.showLeftPane,
        alignment: AlignmentDirectional.centerEnd,
        paneWidth: width,
        minMainContentWidth: 520,
        onClose: () =>
            context.read<TextBookBloc>().add(const ToggleLeftPane(false)),
        paneContent: _buildLeftPaneContent(state),
        mainContent: _buildHTMLViewer(state),
        isResizable: true,
        minPaneWidth: 200,
        maxPaneWidth: 600,
        onPaneWidthChanged: (nextWidth) {
          _sidebarWidth.value = nextWidth;
        },
        onPaneResizeEnd: () {
          context
              .read<SettingsBloc>()
              .add(UpdateSidebarWidth(_sidebarWidth.value));
        },
        autoHandleResponsiveVisibility: false,
      ),
    );
  }

  Widget _buildHTMLViewer(TextBookLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
      child: GestureDetector(
        onScaleUpdate: (details) {
          context.read<TextBookBloc>().add(
                UpdateFontSize((state.fontSize * details.scale).clamp(15, 60)),
              );
        },
        onScaleEnd: (details) {
          // save גודל הגופן בfinish המחווה
          final textBookBloc = context.read<TextBookBloc>();
          final currentState = textBookBloc.state;
          if (currentState is TextBookLoaded) {
            _savePerBookSettingsDirectly(context, currentState,
                fontSize: currentState.fontSize);
          }
        },
        child: NotificationListener<UserScrollNotification>(
          onNotification: (scrollNotification) {
            final isSidebarPinned = state.pinLeftPane ||
                (Settings.getValue<bool>('key-pin-sidebar') ?? false);
            final shouldAutoCloseLeftPane =
                scrollNotification.direction != ScrollDirection.idle &&
                    state.showLeftPane &&
                    !isSidebarPinned &&
                    !_leftPaneAutoCloseQueuedByScroll;
            if (shouldAutoCloseLeftPane) {
              _leftPaneAutoCloseQueuedByScroll = true;
              Future.microtask(() {
                if (!mounted || !context.mounted) {
                  _leftPaneAutoCloseQueuedByScroll = false;
                  return;
                }
                final currentState = context.read<TextBookBloc>().state;
                if (currentState is! TextBookLoaded ||
                    !currentState.showLeftPane) {
                  _leftPaneAutoCloseQueuedByScroll = false;
                  return;
                }
                context.read<TextBookBloc>().add(const ToggleLeftPane(false));
              });
            }
            return false;
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyF,
              ): _openSearchFromToolbar,
            },
            child: TextBookScaffold(
              content: state.content,
              openBookCallback: widget.openBookCallback,
              openLeftPaneTab: _openLeftPaneTab,
              onSelectedTextChanged: _onSelectedTextChanged,
              searchTextController: TextEditingValue(text: state.searchText),
              tab: widget.tab,
              initialSidebarTabIndex: _sidebarTabIndex,
              pageShapeKey: _pageShapeKey,
              pageShapePrintBoundaryKey: _pageShapePrintBoundaryKey,
              pageShapeSidebarTabNotifier: _pageShapeSidebarTabNotifier,
              openSearch: _openSearchWithText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPaneContent(TextBookLoaded state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.showLeftPane && !Platform.isAndroid && !_isInitialFocusDone) {
        final hasSearchText = state.searchText.trim().isNotEmpty;
        if (hasSearchText) {
          if (tabController.index == (_hasAltTitles ? 2 : 1)) {
            textSearchFocusNode.requestFocus();
          } else if (tabController.index == 0) {
            navigationSearchFocusNode.requestFocus();
          }
        }
        _isInitialFocusDone = true;
      }
    });
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: tabController,
                    tabs: [
                      const Tab(
                        icon: Icon(FluentIcons.navigation_24_regular, size: 16),
                        iconMargin: EdgeInsets.only(bottom: 1),
                        height: 44,
                        child: Text('ניווט', style: TextStyle(fontSize: 11)),
                      ),
                      if (_hasAltTitles)
                        const Tab(
                          icon: Icon(FluentIcons.list_24_regular, size: 16),
                          iconMargin: EdgeInsets.only(bottom: 1),
                          height: 44,
                          child: Text('כותרות', style: TextStyle(fontSize: 11)),
                        ),
                      const Tab(
                        icon: Icon(FluentIcons.search_24_regular, size: 16),
                        iconMargin: EdgeInsets.only(bottom: 1),
                        height: 44,
                        child: Text('search', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    dividerColor: Colors.transparent,
                  ),
                ),
                if (MediaQuery.of(context).size.width >= 600)
                  IconButton(
                    onPressed:
                        (Settings.getValue<bool>('key-pin-sidebar') ?? false)
                            ? null
                            : () => context.read<TextBookBloc>().add(
                                  TogglePinLeftPane(!state.pinLeftPane),
                                ),
                    icon: AnimatedRotation(
                      turns: (state.pinLeftPane ||
                              (Settings.getValue<bool>('key-pin-sidebar') ??
                                  false))
                          ? -0.125
                          : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        (state.pinLeftPane ||
                                (Settings.getValue<bool>('key-pin-sidebar') ??
                                    false))
                            ? FluentIcons.pin_24_filled
                            : FluentIcons.pin_24_regular,
                      ),
                    ),
                    color: (state.pinLeftPane ||
                            (Settings.getValue<bool>('key-pin-sidebar') ??
                                false))
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    isSelected: state.pinLeftPane ||
                        (Settings.getValue<bool>('key-pin-sidebar') ?? false),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _buildTocViewer(context, state),
              if (_hasAltTitles)
                AltTocSidebarView(
                  book: widget.tab.book,
                  closeLeftPaneCallback: () => context
                      .read<TextBookBloc>()
                      .add(const ToggleLeftPane(false)),
                  scrollController: state.scrollController,
                ),
              CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  LogicalKeySet(
                    LogicalKeyboardKey.control,
                    LogicalKeyboardKey.keyF,
                  ): () {
                    context.read<TextBookBloc>().add(
                          const ToggleLeftPane(true),
                        );
                    tabController.index = _hasAltTitles ? 2 : 1;
                    textSearchFocusNode.requestFocus();
                  },
                },
                child: _buildSearchView(context, state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchView(BuildContext context, TextBookLoaded state) {
    return TextBookSearchView(
      focusNode: textSearchFocusNode,
      data: state.content.join('\n'),
      scrollControler: state.scrollController,
      // הוא מעביר את text הsearch מה-state הcurrent אל תוך רכיב הsearch
      initialQuery: state.searchText,
      initialSearchOptions: widget.tab.searchOptions,
      initialAlternativeWords: widget.tab.alternativeWords,
      initialSpacingValues: widget.tab.spacingValues,
      initialSearchMode: widget.tab.searchMode,
      initialTypoToleranceEnabled: widget.tab.typoToleranceEnabled,
      closeLeftPaneCallback: () =>
          context.read<TextBookBloc>().add(const ToggleLeftPane(false)),
    );
  }

  Widget _buildTocViewer(BuildContext context, TextBookLoaded state) {
    return TocViewer(
      scrollController: state.scrollController,
      focusNode: navigationSearchFocusNode,
      closeLeftPaneCallback: () =>
          context.read<TextBookBloc>().add(const ToggleLeftPane(false)),
    );
  }
}

// [EDITING DISABLED]
// // החלף את כל הclass הזו בfile text_book_screen.TXT
//
// Widget _buildFullFileEditorButton(BuildContext context, TextBookLoaded state) {
//   final shortcut =
//       Settings.getValue<String>('key-shortcut-edit-section') ?? 'ctrl+e';
//   return IconButton(
//     onPressed: () => _handleFullFileEditorPress(context, state),
//     icon: const Icon(FluentIcons.document_edit_24_regular),
//     tooltip: 'ערוך את הbook (${shortcut.toUpperCase()})',
//   );
// }
//
// void _handleTextEditorPress(BuildContext context, TextBookLoaded state) {
//   final positions = state.positionsListener.itemPositions.value;
//   if (positions.isEmpty) return;
//
//   final currentIndex = positions.first.index;
//   context.read<TextBookBloc>().add(OpenEditor(index: currentIndex));
// }
//
// void _handleFullFileEditorPress(BuildContext context, TextBookLoaded state) {
//   context.read<TextBookBloc>().add(OpenFullFileEditor());
// }

bool _handleGlobalKeyEvent(KeyEvent event, BuildContext context,
    TextBookLoaded state, TextBookTab tab) {
  // קריאת Shortcuts מהsettings
  // [EDITING DISABLED]
  // final editSectionShortcut =
  //     Settings.getValue<String>('key-shortcut-edit-section') ?? 'ctrl+e';
  final searchInBookShortcut = ShortcutValidator.getShortcutValue(
        ShortcutValidator.currentWindowSearchKey,
      ) ??
      'ctrl+f';
  final printShortcut =
      Settings.getValue<String>('key-shortcut-print') ?? 'ctrl+p';
  final addBookmarkShortcut =
      Settings.getValue<String>('key-shortcut-add-bookmark') ?? 'ctrl+b';
  final addNoteShortcut =
      Settings.getValue<String>('key-shortcut-add-note') ?? 'ctrl+n';
  final togglePdfShortcut =
      Settings.getValue<String>('key-shortcut-toggle-pdf-view') ??
          ShortcutValidator.defaultShortcuts['key-shortcut-toggle-pdf-view'] ??
          'ctrl+shift+p';

  // [EDITING DISABLED]
  // // עריכת קטע
  // if (ShortcutHelper.matchesShortcut(event, editSectionShortcut)) {
  //   if (!state.isEditorOpen) {
  //     if (HardwareKeyboard.instance.isShiftPressed) {
  //       _handleFullFileEditorPress(context, state);
  //     } else {
  //       _handleTextEditorPress(context, state);
  //     }
  //     return true;
  //   }
  // }

  // search בbook
  if (ShortcutHelper.matchesShortcut(event, searchInBookShortcut)) {
    context.read<TextBookBloc>().add(const ToggleLeftPane(true));
    final tabController = context
        .findAncestorStateOfType<_TextBookViewerBlocState>()
        ?.tabController;
    if (tabController != null) {
      tabController.index = 1;
    }
    return true;
  }

  // הדפסה
  if (ShortcutHelper.matchesShortcut(event, printShortcut)) {
    final settingsState = context.read<SettingsBloc>().state;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrintingScreen(
          data: Future.value(state.content.join('\n')),
          bookId: state.book.title,
          links: state.links,
          activeCommentators: state.activeCommentators,
          startLine: state.visibleIndices.first,
          removeNikud: state.removeNikud,
          removeTaamim: !settingsState.showTeamim,
          tableOfContents: state.tableOfContents,
        ),
      ),
    );
    return true;
  }

  // הוספת סימניה
  if (ShortcutHelper.matchesShortcut(event, addBookmarkShortcut)) {
    _addBookmarkFromKeyboard(context, state);
    return true;
  }

  // הוספת note
  if (ShortcutHelper.matchesShortcut(event, addNoteShortcut)) {
    _addNoteFromKeyboard(context, state);
    return true;
  }

  // מעבר ל-PDF
  if (ShortcutHelper.matchesShortcut(event, togglePdfShortcut)) {
    _togglePdfView(context, state, tab);
    return true;
  }

  // Shortcuts constants (no ניתנים להתאמה אישית)
  if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed) {
    switch (event.logicalKey) {
      // הגדל את גודל הtext (Ctrl++ או Ctrl+=)
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
        final newSize = min(50.0, state.fontSize + 3);
        context.read<TextBookBloc>().add(UpdateFontSize(newSize));
        _savePerBookSettingsDirectly(context, state, fontSize: newSize);
        return true;

      // הsmall את גודל הtext (Ctrl+-)
      case LogicalKeyboardKey.minus:
        final newSize = max(15.0, state.fontSize - 3);
        context.read<TextBookBloc>().add(UpdateFontSize(newSize));
        _savePerBookSettingsDirectly(context, state, fontSize: newSize);
        return true;

      // איפוס גודל text (Ctrl+0)
      case LogicalKeyboardKey.digit0:
        context.read<TextBookBloc>().add(const UpdateFontSize(25.0));
        _savePerBookSettingsDirectly(context, state, fontSize: 25.0);
        return true;
    }
  }

  // ניווט עם Ctrl+Home ו-Ctrl+End
  if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed) {
    switch (event.logicalKey) {
      // Ctrl+Home - תחילת הbook
      case LogicalKeyboardKey.home:
        state.scrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 300),
        );
        return true;

      // Ctrl+End - סוף הbook
      case LogicalKeyboardKey.end:
        state.scrollController.scrollTo(
          index: state.content.length - 1,
          duration: const Duration(milliseconds: 300),
        );
        return true;
    }
  }

  // מקשי function לno Ctrl
  if (event is KeyDownEvent && !HardwareKeyboard.instance.isControlPressed) {
    switch (event.logicalKey) {
      // F11 - מסך full
      case LogicalKeyboardKey.f11:
        if (!Platform.isAndroid && !Platform.isIOS) {
          final settingsBloc = context.read<SettingsBloc>();
          final newFullscreenState = !settingsBloc.state.isFullscreen;
          FullscreenHelper.toggleFullscreen(context, newFullscreenState);
          return true;
        }
        break;

      // ESC - יציאה ממסך full
      case LogicalKeyboardKey.escape:
        if (!Platform.isAndroid && !Platform.isIOS) {
          final settingsBloc = context.read<SettingsBloc>();
          if (settingsBloc.state.isFullscreen) {
            FullscreenHelper.toggleFullscreen(context, false);
            return true;
          }
        }
        break;
    }
  }

  return false;
}

/// Helper function to save per-book settings directly from global functions
Future<void> _savePerBookSettingsDirectly(
  BuildContext context,
  TextBookLoaded state, {
  double? fontSize,
  bool? showSplitView,
  bool? removeNikud,
  bool? removePunctuation,
}) async {
  final settingsBloc = context.read<SettingsBloc>();
  if (!settingsBloc.state.enablePerBookSettings) {
    return;
  }

  // טעינת הsettings הקיימות
  final existingSettings = await TextBookPerBookSettings.load(state.book.title);

  // קבלת ברירות המחדל הגלובליות
  final defaultFontSize = settingsBloc.state.fontSize;
  final defaultRemoveNikud = settingsBloc.state.defaultRemoveNikud;
  final defaultShowSplitView =
      Settings.getValue<bool>('key-splited-view') ?? false;

  // בניית settings חדשות - רק fields ששונו מברירת המחדל
  double? newFontSize = existingSettings?.fontSize;
  bool? newCommentatorsBelow = existingSettings?.commentatorsBelow;
  bool? newRemoveNikud = existingSettings?.removeNikud;
  bool? newRemovePunctuation = existingSettings?.removePunctuation;

  // update רק הfield שהשתנה
  if (fontSize != null) {
    // אם הvalue שווה לברירת המחדל, מוחקים את הfield
    newFontSize = (fontSize == defaultFontSize) ? null : fontSize;
  }

  if (showSplitView != null) {
    final commentatorsBelow = !showSplitView;
    // אם הvalue שווה לברירת המחדל, מוחקים את הfield
    newCommentatorsBelow =
        (showSplitView == defaultShowSplitView) ? null : commentatorsBelow;
  }

  if (removeNikud != null) {
    // אם הvalue שווה לברירת המחדל, מוחקים את הfield
    newRemoveNikud = (removeNikud == defaultRemoveNikud) ? null : removeNikud;
  }

  if (removePunctuation != null) {
    newRemovePunctuation = removePunctuation ? true : null;
  }

  // אם כל הfields null, מוחקים את הfile כולו
  if (newFontSize == null &&
      newCommentatorsBelow == null &&
      newRemoveNikud == null &&
      newRemovePunctuation == null) {
    await TextBookPerBookSettings.delete(state.book.title);
    return;
  }

  // save הsettings המעודכנות
  final settings = TextBookPerBookSettings(
    fontSize: newFontSize,
    commentatorsBelow: newCommentatorsBelow,
    removeNikud: newRemoveNikud,
    removePunctuation: newRemovePunctuation,
  );

  await settings.save(state.book.title);
}

/// Helper function to add bookmark from keyboard shortcut
void _addBookmarkFromKeyboard(
    BuildContext context, TextBookLoaded state) async {
  final index = state.positionsListener.itemPositions.value.first.index;
  final toc = state.book.tableOfContents;
  final bookmarkBloc = context.read<BookmarkBloc>();
  String ref = await refFromIndex(index, toc);
  // הוספת name הbook לכותרת
  ref = addBookTitleToRef(ref, state.book.title);

  if (!context.mounted) return;

  final bookmarkAdded = bookmarkBloc.addBookmark(
    ref: ref,
    book: state.book,
    index: index,
    commentatorsToShow: state.activeCommentators,
  );

  UiSnack.showQuick(
      bookmarkAdded ? 'הסימניה נוספה בsuccess' : 'הסימניה כבר קיימת');
}

/// Helper function to add note from keyboard shortcut
Future<void> _addNoteFromKeyboard(
    BuildContext context, TextBookLoaded state) async {
  // user בline הselectedת אם קיימת, אחרת בline הראשונה הנראית
  final currentIndex = state.selectedIndex ??
      (state.visibleIndices.isNotEmpty ? state.visibleIndices.first : 0);
  // no צריך text selected - הnote חלה על כל הline
  final textBookBloc = context.read<TextBookBloc>();

  // קבלת הtext המזהה של הline (כמו שיוצג ככותרת הnote)
  final referenceText = extractDisplayTextFromLines(
    state.content,
    currentIndex + 1,
    excludeBookTitle: state.book.title,
  );

  // טען טיוטה אם קיימת
  final draftService = PersonalNoteDraftService();
  final draft = await draftService.loadDraft(
    bookId: state.book.title,
    lineNumber: currentIndex + 1,
  );

  if (!context.mounted) return;

  // שלח event לפתיחת מצב יצירה בסיידבר
  context.read<PersonalNotesBloc>().add(StartCreatingPersonalNote(
        bookId: state.book.title,
        lineNumber: currentIndex + 1,
        referenceText: referenceText,
        initialContent: draft?.content ?? '',
        initialFormat: draft?.contentFormat ?? PersonalNoteContentFormat.plain,
      ));

  if (state.showPageShapeView) {
    final viewerState =
        context.findAncestorStateOfType<_TextBookViewerBlocState>();
    viewerState?._pageShapeSidebarTabNotifier.value = 1;
    return;
  }

  // Open את ה-split view אם הוא closed
  if (!state.showSplitView) {
    textBookBloc.add(const ToggleSplitView(true));
  }
}

// [EDITING DISABLED]
// void _openEditorDialog(BuildContext context, TextBookLoaded state) async {
//   if (state.editorIndex == null || state.editorSectionId == null) return;
//
//   final settings = EditorSettingsHelper.getSettings();
//
//   // Reload the content from file system to ensure fresh data
//   String freshContent = '';
//   try {
//     // Try to reload content from file system
//     final dataProvider = FileSystemData.instance;
//     freshContent = await dataProvider.getBookText(
//       state.book.title,
//       categoryId: state.book.categoryId,
//       fileType: state.book.fileType,
//     );
//   } catch (e) {
//     debugPrint('Failed to load fresh content: $e');
//     // Fall back to cached content
//     freshContent = state.editorText ?? '';
//   }
//
//   if (!context.mounted) return;
//
//   await showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (dialogContext) => BlocProvider.value(
//       value: context.read<TextBookBloc>(),
//       child: TextSectionEditorDialog(
//         bookId: state.book.title,
//         category: state.book.categoryPath,
//         categoryId: state.book.categoryId,
//         fileType: state.book.fileType,
//         sectionIndex: state.editorIndex!,
//         sectionId: state.editorSectionId!,
//         initialContent:
//             freshContent.isNotEmpty ? freshContent : state.editorText ?? '',
//         hasLinksFile: state.hasLinksFile,
//         hasDraft: state.hasDraft,
//         settings: settings,
//       ),
//     ),
//   );
//
//   if (!context.mounted) return;
//
//   // Close editor when dialog is dismissed
//   context.read<TextBookBloc>().add(const CloseEditor());
// }

void _togglePdfView(
    BuildContext context, TextBookLoaded state, TextBookTab tab) async {
  final currentIndex = state.positionsListener.itemPositions.value.isNotEmpty
      ? state.positionsListener.itemPositions.value.first.index
      : 0;
  tab.index = currentIndex;

  final library = await DataRepository.instance.library;
  if (!context.mounted) return;

  final book = library.getCompanionBook(state.book, PdfBook);
  if (book == null) {
    UiSnack.showError('no נמצא book PDF עבור "${state.book.title}"');
    return;
  }

  final index = await textToPdfPage(
    state.book,
    currentIndex,
  );

  if (!context.mounted) return;

  openBook(context, book, index ?? 1, '', ignoreHistory: true);
}
