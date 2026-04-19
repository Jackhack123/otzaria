import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:otzaria/library/bloc/library_state.dart';
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/indexing/repository/indexing_repository.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/migration/sync/file_sync_service.dart';
import 'package:otzaria/data/data_providers/sqlite_data_provider.dart';
import 'package:otzaria/settings/settings_exports.dart';
import 'package:otzaria/settings/services/custom_folders/custom_folder.dart';
import 'package:otzaria/utils/zip_extractor_service.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final DataRepository _repository = DataRepository.instance;

  LibraryBloc() : super(LibraryState.initial()) {
    on<LoadLibrary>(_onLoadLibrary);
    on<RefreshLibrary>(_onRefreshLibrary);
    on<UpdateLibraryPath>(_onUpdateLibraryPath);
    on<UpdateHebrewBooksPath>(_onUpdateHebrewBooksPath);
    on<NavigateToCategory>(_onNavigateToCategory);
    on<NavigateUp>(_onNavigateUp);
    on<SearchBooks>(_onSearchBooks);
    on<SelectTopics>(_onSelectTopics);
    on<UpdateSearchQuery>(_onUpdateSearchQuery);
    on<SelectBookForPreview>(_onSelectBookForPreview);
  }

  Future<void> _onLoadLibrary(
    LoadLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _pruneRemovedCustomFoldersIfNeeded();
      DataRepository.instance.library = FileSystemData.instance.getLibrary();
      DataRepository.instance.invalidateExternalBooksCache();
      Library library = await _repository.library;

      emit(state.copyWith(
        library: library,
        currentCategory: library,
        isLoading: false,
        searchResults: null,
        searchQuery: null,
        selectedTopics: null,
      ));
      developer.log('📚 LibraryBloc: State emitted with isLoading=false',
          name: 'LibraryBloc');
    } catch (e) {
      developer.log('📚 LibraryBloc: Error loading library: $e',
          name: 'LibraryBloc');
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onRefreshLibrary(
    RefreshLibrary event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _pruneRemovedCustomFoldersIfNeeded();

      // save the current location in the library
      final currentCategoryPath =
          _getCurrentCategoryPath(state.currentCategory);

      // save the book keys before the refresh to identify new books
      final keysBeforeRefresh = state.library
              ?.getAllBooks()
              .map((b) => IndexingRepository.catalogueOrderKey(b))
              .toSet() ??
          <String>{};

      final libraryPath =
          Settings.getValue<String>(SettingsRepository.keyLibraryPath);
      if (libraryPath != null) {
        FileSystemData.instance.libraryPath = libraryPath;
      }

      // refresh the library from the file system
      DataRepository.instance.library = FileSystemData.instance.getLibrary();
      DataRepository.instance.invalidateExternalBooksCache();
      final library = await _repository.library;

      try {
        await TantivyDataProvider.instance.reopenIndex();
      } catch (e) {
        // if there is an issue with reopening the index, continue without it
        // the library will still refresh but search may not work until restart
        developer.log('Warning: Could not reopen search index',
            name: 'LibraryBloc', error: e);
      }

      // identify new books שנוספו בrefresh
      final newBooksToIndex = library
          .getAllBooks()
          .where((b) => !keysBeforeRefresh
              .contains(IndexingRepository.catalogueOrderKey(b)))
          .toList();

      // return to the folder that was open previously
      final targetCategory = _findCategoryByPath(library, currentCategoryPath);

      emit(state.copyWith(
        library: library,
        currentCategory: targetCategory ?? library,
        isLoading: false,
        newBooksToIndex: newBooksToIndex.isNotEmpty ? newBooksToIndex : null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _pruneRemovedCustomFoldersIfNeeded() async {
    final sqliteProvider = SqliteDataProvider.instance;
    if (!sqliteProvider.isInitialized) {
      await sqliteProvider.initialize();
    }

    final repository = sqliteProvider.repository;
    if (repository == null) {
      return;
    }

    final customFoldersJson =
        Settings.getValue<String>(SettingsRepository.keyCustomFolders);
    final customFolders = CustomFoldersManager.loadFolders(customFoldersJson);

    final syncService = await FileSyncService.getInstance(repository);
    if (syncService == null) {
      return;
    }

    await syncService.refreshSourcesAndPruneRemovedCustomFolders(customFolders);
  }

  /// מחזיר את הpath של הfolder הcurrent
  List<String> _getCurrentCategoryPath(Category? category) {
    if (category == null) return [];

    final path = <String>[];
    Category? current = category;
    final visited = <Category>{}; // למניעת לוnoות אינסופיות

    while (current != null &&
        current.parent != null &&
        current.parent != current) {
      // check שno ביקרנו כבר בcategory הזו (למניעת לוnoה אינסופית)
      if (visited.contains(current)) {
        break;
      }
      visited.add(current);

      path.insert(0, current.title);
      current = current.parent;
    }

    return path;
  }

  /// מוצא folder לפי path
  Category? _findCategoryByPath(Category rootCategory, List<String> path) {
    if (path.isEmpty) return rootCategory;

    Category current = rootCategory;

    for (final categoryName in path) {
      try {
        final found = current.subCategories
            .where((cat) => cat.title == categoryName)
            .first;
        current = found;
      } catch (e) {
        // אם no מצאנו את הfolder, נחזיר את הקרובה ביותר
        return current;
      }
    }

    return current;
  }

  Future<void> _onUpdateLibraryPath(
    UpdateLibraryPath event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      // check וחילוץ file ZIP אם קיים
      final extractionResult =
          await ZipExtractorService.checkAndExtractZipIfNeeded(event.path);

      if (!extractionResult.success) {
        emit(state.copyWith(
          error: extractionResult.errorMessage ?? 'error בחילוץ file דחוס',
          isLoading: false,
        ));
        return;
      }

      // אם חולץ file, נמתין רגע
      if (extractionResult.successfullyExtracted) {
        developer.log(
            'ZIP file extracted: ${extractionResult.extractedFileName}',
            name: 'LibraryBloc');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await Settings.setValue<String>(
          SettingsRepository.keyLibraryPath, event.path);
      await Settings.setValue<String>(
          SettingsRepository.keyLibraryFolderName, '');
      // ניקוי override Android — DB החדש נמצא ישירות בlibrary
      await Settings.setValue<String>(
          SettingsRepository.keyDbEffectivePath, '');

      FileSystemData.instance.libraryPath = event.path;
      DataRepository.instance.library = FileSystemData.instance.getLibrary();
      DataRepository.instance.invalidateExternalBooksCache();

      // פתיחה again של אינדקס הsearch
      try {
        await TantivyDataProvider.instance.reopenIndex();
      } catch (e) {
        developer.log('Warning: Could not reopen search index',
            name: 'LibraryBloc', error: e);
      }

      final library = await _repository.library;

      emit(state.copyWith(
        library: library,
        currentCategory: library,
        isLoading: false,
        searchResults: null,
        searchQuery: null,
        selectedTopics: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> _onUpdateHebrewBooksPath(
    UpdateHebrewBooksPath event,
    Emitter<LibraryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      // check וחילוץ file ZIP אם קיים
      final extractionResult =
          await ZipExtractorService.checkAndExtractZipIfNeeded(event.path);

      if (!extractionResult.success) {
        emit(state.copyWith(
          error: extractionResult.errorMessage ?? 'error בחילוץ file דחוס',
          isLoading: false,
        ));
        return;
      }

      // אם חולץ file, נמתין רגע
      if (extractionResult.successfullyExtracted) {
        developer.log(
            'ZIP file extracted: ${extractionResult.extractedFileName}',
            name: 'LibraryBloc');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await Settings.setValue<String>('key-hebrew-books-path', event.path);

      // refresh the library כדי לטעון את הbooks החדשים
      DataRepository.instance.library = FileSystemData.instance.getLibrary();
      DataRepository.instance.invalidateExternalBooksCache();

      final library = await _repository.library;

      emit(state.copyWith(
        library: library,
        currentCategory: library,
        isLoading: false,
        searchResults: null,
        searchQuery: null,
        selectedTopics: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  void _onNavigateToCategory(
    NavigateToCategory event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(
      currentCategory: event.category,
      searchQuery: null,
      searchResults: null,
      selectedTopics: null,
    ));
  }

  void _onNavigateUp(
    NavigateUp event,
    Emitter<LibraryState> emit,
  ) {
    if (state.currentCategory?.parent != null) {
      emit(state.copyWith(
        currentCategory: state.currentCategory!.parent!,
        searchQuery: null,
        searchResults: null,
        selectedTopics: null,
      ));
    }
  }

  void _onUpdateSearchQuery(
    UpdateSearchQuery event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<LibraryState> emit,
  ) async {
    if (state.searchQuery == null || state.searchQuery!.length < 3) {
      emit(state.copyWith(
        searchResults: null,
      ));
      return;
    }

    try {
      final results = await _repository.findBooks(
        state.searchQuery!,
        state.currentCategory,
        topics: state.selectedTopics,
        includeOtzar: event.showOtzarHachochma ?? false,
        includeHebrewBooks: event.showHebrewBooks ?? false,
      );

      // בחירת הbook הראשון מresults הsearch לתצוגה מקדימה
      Book? firstBook;
      if (results.isNotEmpty) {
        // העדפה לbook text על פני PDF
        firstBook = results.firstWhere(
          (book) => book is TextBook,
          orElse: () => results.first,
        );
      }

      emit(state.copyWith(
        searchResults: results,
        previewBook: firstBook,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        searchResults: null,
      ));
    }
  }

  void _onSelectTopics(
    SelectTopics event,
    Emitter<LibraryState> emit,
  ) {
    // כשמשנים את הנושאים, צריך לעדyes את הbook המוצג
    // אם יש results search, selected את הbook הראשון מהlist המסוננת
    Book? firstBook;
    if (state.searchResults != null && state.searchResults!.isNotEmpty) {
      final filteredResults = event.topics.isEmpty
          ? state.searchResults!
          : state.searchResults!.where((book) {
              return event.topics.any((topic) => book.topics.contains(topic));
            }).toList();

      if (filteredResults.isNotEmpty) {
        firstBook = filteredResults.firstWhere(
          (book) => book is TextBook,
          orElse: () => filteredResults.first,
        );
      }
    }

    emit(state.copyWith(
      selectedTopics: event.topics,
      previewBook: firstBook,
    ));
  }

  void _onSelectBookForPreview(
    SelectBookForPreview event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(
      previewBook: event.book,
      searchResults: state.searchResults,
    ));
  }
}
