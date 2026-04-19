import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/core/app_restart.dart';
import 'package:otzaria/empty_library/bloc/empty_library_bloc.dart';
import 'package:otzaria/empty_library/bloc/empty_library_event.dart';
import 'package:otzaria/empty_library/bloc/empty_library_state.dart';
import 'package:otzaria/core/ui_snack.dart';
import 'package:otzaria/widgets/custom_ui_components.dart';

class EmptyLibraryScreen extends StatelessWidget {
  final VoidCallback onLibraryLoaded;
  final EmptyLibraryBloc? bloc;

  const EmptyLibraryScreen({
    super.key,
    required this.onLibraryLoaded,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: _EmptyLibraryView(onLibraryLoaded: onLibraryLoaded),
      );
    }
    return BlocProvider(
      create: (context) => EmptyLibraryBloc(),
      child: _EmptyLibraryView(onLibraryLoaded: onLibraryLoaded),
    );
  }
}

class _EmptyLibraryView extends StatefulWidget {
  final VoidCallback onLibraryLoaded;

  const _EmptyLibraryView({required this.onLibraryLoaded});

  @override
  State<_EmptyLibraryView> createState() => _EmptyLibraryViewState();
}

class _EmptyLibraryViewState extends State<_EmptyLibraryView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<EmptyLibraryBloc, EmptyLibraryState>(
        listener: (context, state) {
          if (state is EmptyLibraryDirectorySelected) {
            _showRestartDialog(context);
          }
          if (state is EmptyLibraryZipExtracted) {
            UiSnack.showSuccess(
              'הfile "${state.extractedFileName}" חולץ בsuccess!',
            );
          }
          if (state is EmptyLibraryError && state.errorMessage != null) {
            if (state.zipFiles != null && state.zipFiles!.isNotEmpty) {
              _showMultipleZipFilesDialog(context, state.zipFiles!);
            } else {
              UiSnack.showError(state.errorMessage!);
            }
          }
          if (state is EmptyLibraryAskingDeleteZip) {
            _showDeleteZipDialog(context, state);
          }
          if (state is EmptyLibraryAskingDbCopy) {
            if (state.errorMessage != null) {
              UiSnack.showError(state.errorMessage!);
            }
            _showDbCopyDialog(context, state);
          }
        },
        builder: (context, state) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(16),
              child: _buildContent(context, state),
            ),
          );
        },
      ),
    );
  }

  void _showRestartDialog(BuildContext context) {
    showRestartRequiredDialog(context: context).then((shouldCloseApp) async {
      if (shouldCloseApp == true) {
        await restartApplication();
      }
    });
  }

  /// מציג דיאלוג המסביר לuser את מגבלת Android Scoped Storage.
  /// הuser בוחר בין Copyה (save מקור) להעברה (מחיקת מקור לפנית מקום).
  void _showDbCopyDialog(
      BuildContext context, EmptyLibraryAskingDbCopy state) {
    final sizeText = state.dbSizeBytes > 0
        ? '${(state.dbSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB'
        : 'no ידוע';

    showDbCopyRequiredDialog(
      context: context,
      sizeText: sizeText,
    ).then((shouldMove) {
      if (shouldMove == null) {
        return;
      }

      if (!context.mounted) {
        return;
      }

      BlocProvider.of<EmptyLibraryBloc>(context).add(
        PickDbFileRequested(
          libraryPath: state.libraryPath,
          internalDbPath: state.internalDbPath,
          externalDbPath: state.externalDbPath,
          shouldMove: shouldMove,
        ),
      );
    });
  }

  void _showDeleteZipDialog(
      BuildContext context, EmptyLibraryAskingDeleteZip state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('מחיקת file דחוס'),
        content: const Text(
          'האם לdeleted את הfile הדחוס המקורי?\n\n'
          'הfile הדחוס אינו נצרך עבור פעילות התוכנה והוא רק תופס מקום.\n'
          'מומלץ לdeleted אותו.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              BlocProvider.of<EmptyLibraryBloc>(context).add(
                DeleteZipAnswered(
                  shouldDelete: false,
                  zipPath: state.zipPath,
                  extractedPath: state.extractedPath,
                ),
              );
            },
            child: const Text('השאר את הfile'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              BlocProvider.of<EmptyLibraryBloc>(context).add(
                DeleteZipAnswered(
                  shouldDelete: true,
                  zipPath: state.zipPath,
                  extractedPath: state.extractedPath,
                ),
              );
            },
            child: const Text('Delete את הfile'),
          ),
        ],
      ),
    );
  }

  void _showMultipleZipFilesDialog(
      BuildContext context, List<String> zipFiles) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('נמצאו מbook files דחוסים'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('נמצאו הfiles הדחוסים nextים:'),
            const SizedBox(height: 8),
            ...zipFiles.map((file) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $file'),
                )),
            const SizedBox(height: 16),
            const Text(
              'אנא השאר רק file דחוס אחד בfolder ונסה שוב.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('הבנתי'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, EmptyLibraryState state) {
    // אם בתהליך parentדה או חילוץ, נציג את ההתקדמות
    if (state is EmptyLibraryDownloading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.arrow_download_24_regular,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'מוריד library',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: state.progress > 0 ? state.progress : null,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                if (state.progress > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(state.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (state is EmptyLibraryExtracting) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.folder_zip_24_regular,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'מחלץ library',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(state.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // המסך הרגיל
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          FluentIcons.library_24_regular,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 24),
        const Text(
          'no נמצאה bookיית books',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 16),
        Text(
          'תוכל לselected folder קיימת המכילה את the library (ניתן להעתיק ממחשב אחר), או לחלץ מfile דחוס (ZIP/ZST).',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (state.selectedPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.selectedPath!,
                style: const TextStyle(fontSize: 14),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            FilledButton.icon(
              onPressed: state.isLoading ? null : () => _pickDirectory(context),
              icon: const Icon(FluentIcons.folder_open_24_regular),
              label: const Text('בחר תיקיית library'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed:
                  state.isLoading ? null : () => _pickArchiveFile(context),
              icon: const Icon(FluentIcons.folder_zip_24_regular),
              label: const Text('חלץ מfile דחוס'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: state.isLoading || state.downloadDisabledReason != null
              ? null
              : () {
                  BlocProvider.of<EmptyLibraryBloc>(context)
                      .add(DownloadLibraryRequested());
                },
          icon: const Icon(FluentIcons.arrow_download_24_regular),
          label: const Text(
            'עוד no parentדת את file the library? לחץ כאן כדי לparentיד אותה כעת',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
        if (state.downloadDisabledReason != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  FluentIcons.warning_24_regular,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.downloadDisabledReason!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (state.isLoading && state is EmptyLibraryLoading) ...[
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          const Text('בודק את הfolder...'),
        ],
      ],
    );
  }

  Future<void> _pickDirectory(BuildContext context) async {
    BlocProvider.of<EmptyLibraryBloc>(context).add(PickDirectoryRequested());
  }

  Future<void> _pickArchiveFile(BuildContext context) async {
    BlocProvider.of<EmptyLibraryBloc>(context).add(PickArchiveFileRequested());
  }
}
