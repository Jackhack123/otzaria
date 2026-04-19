import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/search/view/search_options_dropdown.dart';
import 'package:otzaria/widgets/rtl_text_field.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class EnhancedSearchField extends StatefulWidget {
  final dynamic widget;

  /// האם להציג את button הsearch המובנה בתוך הfield.
  final bool showInlineSearchButton;

  /// callback חיצוני שיופעל במקום לוגיקת הsearch הפנימית כשמוגדר.
  /// משמש בדיאלוג הsearch המתקדם כך ש-Enter מוליך לsearch הtrue.
  final VoidCallback? onSubmit;

  const EnhancedSearchField({
    super.key,
    required this.widget,
    this.showInlineSearchButton = true,
    this.onSubmit,
  });

  SearchingTab get tab {
    // Support both TantivyFullTextSearch and _SearchDialogWrapper
    if (widget is TantivyFullTextSearch) {
      return (widget as TantivyFullTextSearch).tab;
    } else {
      // Assume it's _SearchDialogWrapper or similar with a tab property
      return widget.tab as SearchingTab;
    }
  }

  @override
  State<EnhancedSearchField> createState() => _EnhancedSearchFieldState();
}

// GlobalKey לגישה ל-State מבחוץ
final GlobalKey enhancedSearchFieldKey = GlobalKey();

class _EnhancedSearchFieldState extends State<EnhancedSearchField> {
  final GlobalKey _textFieldKey = GlobalKey();
  OverlayEntry? _searchOptionsOverlay;

  static const double _kSearchFieldMinWidth = 300;
  static const double _kControlHeight = 48;

  @override
  void initState() {
    super.initState();
    widget.tab.queryController.addListener(_onTextChanged);
    widget.tab.searchFieldFocusNode.addListener(_onCursorPositionChanged);
  }

  @override
  void deactivate() {
    debugPrint('⏸️ EnhancedSearchField deactivating - clearing overlays');
    _hideSearchOptionsOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    debugPrint('🗑️ EnhancedSearchField disposing');
    _hideSearchOptionsOverlay();
    widget.tab.queryController.removeListener(_onTextChanged);
    widget.tab.searchFieldFocusNode.removeListener(_onCursorPositionChanged);
    widget.tab.searchOptions.clear();
    super.dispose();
  }

  void _onTextChanged() {
    final bool drawerWasOpen = _searchOptionsOverlay != null;
    final text = widget.tab.queryController.text;

    // אם field הsearch התרוקן, נקה הכל ונclosed את המגירה
    if (text.trim().isEmpty) {
      widget.tab.searchOptions.clear();
      if (drawerWasOpen) {
        _hideSearchOptionsOverlay();
        _notifyDropdownClosed();
      }
      return;
    }

    // update המגירה אם היא openה
    if (drawerWasOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSearchOptionsOverlay();
      });
    }
  }

  void _onCursorPositionChanged() {
    // update המגירה כשהסמן זז (אם היא openה)
    if (_searchOptionsOverlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSearchOptionsOverlay();
      });
    }
  }

  void _updateSearchOptionsOverlay() {
    // update המגירה אם היא openה
    if (_searchOptionsOverlay != null) {
      // save location הסמן לפני הupdate
      final currentSelection = widget.tab.queryController.selection;

      _hideSearchOptionsOverlay();
      _showSearchOptionsOverlay();

      // החזרת location הסמן אחרי הupdate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint(
            'DEBUG: Restoring cursor position in update: ${currentSelection.baseOffset}',
          );
          widget.tab.queryController.selection = currentSelection;
        }
      });
    }
  }

  void _showSearchOptionsOverlay() {
    if (_searchOptionsOverlay != null) return;

    final currentSelection = widget.tab.queryController.selection;
    final overlayState = Overlay.of(context);
    final RenderBox? textFieldBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;
    final textFieldGlobalPosition = textFieldBox.localToGlobal(Offset.zero);

    _searchOptionsOverlay = OverlayEntry(
      builder: (context) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            final clickPosition = event.position;
            final textFieldRect = Rect.fromLTWH(
              textFieldGlobalPosition.dx,
              textFieldGlobalPosition.dy,
              textFieldBox.size.width,
              textFieldBox.size.height,
            );

            // אזור המגירה המשוער - אנחנו no יודעים את הגובה המדויק אז ניקח טווח סביר
            final drawerRect = Rect.fromLTWH(
              textFieldGlobalPosition.dx,
              textFieldGlobalPosition.dy + textFieldBox.size.height,
              textFieldBox.size.width,
              120.0, // גובה משוער מקסימלי לשתי lines
            );

            if (!textFieldRect.contains(clickPosition) &&
                !drawerRect.contains(clickPosition)) {
              _hideSearchOptionsOverlay();
              _notifyDropdownClosed();
            }
          },
          child: Stack(
            children: [
              Positioned(
                left: textFieldGlobalPosition.dx,
                top: textFieldGlobalPosition.dy + textFieldBox.size.height,
                width: textFieldBox.size.width,
                // ======== התיקון מתחיל כאן ========
                child: AnimatedSize(
                  // 1. עוטפים ב-AnimatedSize
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Container(
                    // height: 40.0, // 2. מסירים את הגובה הconstant
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade400, width: 1),
                        right: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 48.0,
                        right: 16.0,
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: _buildSearchOptionsContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    overlayState.insert(_searchOptionsOverlay!);

    // החזרת location הסמן אחרי יצירת ה-overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.tab.queryController.selection = currentSelection;
      }
    });

    // וידוא שה-overlay מוyes לקבל לחיצות
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ה-overlay כעת מוyes לקבל לחיצות
    });
  }

  // המילה הcurrent (לפי location הסמן)
  Map<String, dynamic>? _getCurrentWordInfo() {
    final text = widget.tab.queryController.text;
    final cursorPosition = widget.tab.queryController.selection.baseOffset;

    if (text.isEmpty || cursorPosition < 0) return null;

    final words = text.trim().split(RegExp(r'\s+'));
    int currentPos = 0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final wordStart = text.indexOf(word, currentPos);
      if (wordStart == -1) continue;
      final wordEnd = wordStart + word.length;

      if (cursorPosition >= wordStart && cursorPosition <= wordEnd) {
        return {'word': word, 'index': i, 'start': wordStart, 'end': wordEnd};
      }

      currentPos = wordEnd;
    }

    return null;
  }

  Widget _buildSearchOptionsContent() {
    final wordInfo = _getCurrentWordInfo();

    // אם אין מילה current, נציג Message המתאימה
    if (wordInfo == null ||
        wordInfo['word'] == null ||
        wordInfo['word'].isEmpty) {
      return const Center(
        child: Text(
          'הקלד או הצב את הסמן על מילה כלשהיא, כדי לselected אפשרויות search',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SearchOptionsRow(
      isVisible: true,
      currentWord: wordInfo['word'],
      wordIndex: wordInfo['index'],
      wordOptions: widget.tab.searchOptions,
      onOptionsChanged: _onSearchOptionsChanged,
      key: ValueKey(
        '${wordInfo['word']}_${wordInfo['index']}',
      ), // key ייoverrideי לupdate
    );
  }

  void _hideSearchOptionsOverlay() {
    _searchOptionsOverlay?.remove();
    _searchOptionsOverlay = null;
  }

  void _notifyDropdownClosed() {
    // update מצב הbutton כשהמגירה נסגרת מבחוץ
    setState(() {
      // זה יגרום לupdate של הbutton ב-build
    });
  }

  void _onSearchOptionsChanged() {
    // update התצוגה כשuser מyear אפשרויות
    setState(() {
      // זה יגרום לupdate של התצוגה
    });

    // update ה-notifier כדי שהתצוגה של מילות הsearch תתעדyes
    widget.tab.searchOptionsChanged.value++;
  }

  void _performSearch() {
    // אם קיים callback חיצוני (למשל מהדיאלוג), users בו במקום לוגיקת הsearch הפנימית
    if (widget.onSubmit != null) {
      widget.onSubmit!();
      return;
    }

    String query = widget.tab.queryController.text.trim();
    if (query.isNotEmpty) {
      // הsearch עובד תמיד על text לno ניקוד.
      if (utils.hasNikud(query)) {
        query = utils.removeVolwels(query);
      }

      widget.tab.updateTitleFromAppliedQuery(query);
      context.read<HistoryBloc>().add(AddHistory(widget.tab));
      context.read<SearchBloc>().add(
            UpdateSearchQuery(
              query,
              customSpacing: widget.tab.spacingValues,
              alternativeWords: widget.tab.alternativeWords,
              searchOptions: widget.tab.searchOptions,
            ),
          );
      widget.tab.isLeftPaneOpen.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<NavigationBloc, NavigationState>(
          listener: (context, state) {
            debugPrint('🔄 Navigation changed to: ${state.currentScreen}');
            // סגירת מגירת האפשרויות כשמשנים מסך
            if (_searchOptionsOverlay != null) {
              _hideSearchOptionsOverlay();
            }
          },
        ),
      ],
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          // טיפול ב-Enter גם כשהfocus no בתיבת הsearch
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !widget.tab.searchFieldFocusNode.hasFocus) {
            _performSearch();
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: _kSearchFieldMinWidth,
                    minHeight: _kControlHeight,
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (KeyEvent event) {
                      // update המגירה כשusers בחצים במקלדת
                      if (event is KeyDownEvent) {
                        final isArrowKey =
                            event.logicalKey.keyLabel == 'Arrow Left' ||
                                event.logicalKey.keyLabel == 'Arrow Right' ||
                                event.logicalKey.keyLabel == 'Arrow Up' ||
                                event.logicalKey.keyLabel == 'Arrow Down';

                        if (isArrowKey) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_searchOptionsOverlay != null) {
                              _updateSearchOptionsOverlay();
                            }
                          });
                        }
                      }
                    },
                    child: RtlTextField(
                      focusNode: widget.tab.searchFieldFocusNode,
                      controller: widget.tab.queryController,
                      onChanged: (text) {
                        // update המגירה כשהtext variable
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_searchOptionsOverlay != null) {
                            _updateSearchOptionsOverlay();
                          }
                        });
                      },
                      onSubmitted: (e) {
                        _performSearch();
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHigh,
                        border: const OutlineInputBorder(),
                        hintText: "חפש כאן...",
                        labelText: "לsearch הקש אנטר או לחץ על סמל הsearch",
                        contentPadding: widget.showInlineSearchButton
                            ? null
                            : const EdgeInsets.only(
                                left: 12,
                                right: 48,
                                top: 16,
                                bottom: 16,
                              ),
                        prefixIcon: widget.showInlineSearchButton
                            ? IconButton(
                                onPressed: _performSearch,
                                icon: const Icon(FluentIcons.search_24_regular),
                              )
                            : null,
                        suffixIcon: IconButton(
                          icon: const Icon(FluentIcons.dismiss_24_regular),
                          onPressed: () {
                            // ניקוי full של כל הנתונים
                            widget.tab.queryController.clear();
                            widget.tab.searchOptions.clear();
                            context
                                .read<SearchBloc>()
                                .add(UpdateSearchQuery(''));
                            // ניקוי ספירות הפאסטים
                            context
                                .read<SearchBloc>()
                                .add(UpdateFacetCounts({}));
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // אזורי ריחוף הוסרו - no נחוצים יותר
            // buttonי ה+ וbuttonי המרווח הוסרו - עכשיו users בבקרים בדיאלוג
          ],
        ),
      ),
    );
  }
}
