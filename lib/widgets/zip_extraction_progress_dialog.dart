import 'package:flutter/material.dart';
import 'package:otzaria/utils/zip_extractor_service.dart';

/// ווידג'ט לטיפול בהצגת דיאלוג התקדמות חילוץ ZIP
class ZipExtractionProgressDialog {
  /// מציג דיאלוג התקדמות ומבצע חילוץ ZIP אם נדרש
  ///
  /// [context] - הקונtext של המסך
  /// [path] - path הfolder לtest
  /// [onSuccess] - function שתופעל בsuccess (מקבלת את תוצאת החילוץ)
  /// [onError] - function שתופעל בerror (מקבלת הודעת error)
  static Future<void> showAndExtract({
    required BuildContext context,
    required String path,
    required Function(ZipExtractionResult) onSuccess,
    required Function(String) onError,
  }) async {
    final progressNotifier = ValueNotifier<double>(0.0);
    final messageNotifier = ValueNotifier<String>('בודק folder...');
    final isExtractingNotifier = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('מעבד folder'),
        content: ValueListenableBuilder<bool>(
          valueListenable: isExtractingNotifier,
          builder: (context, isExtracting, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExtracting) ...[
                  SizedBox(
                    width: 250,
                    child: ValueListenableBuilder<double>(
                      valueListenable: progressNotifier,
                      builder: (context, progress, _) {
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: messageNotifier,
                    builder: (context, message, _) {
                      return Text(message, textAlign: TextAlign.center);
                    },
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<double>(
                    valueListenable: progressNotifier,
                    builder: (context, progress, _) {
                      return Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<String>(
                    valueListenable: messageNotifier,
                    builder: (context, message, _) {
                      return Text(message);
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );

    try {
      final extractionResult =
          await ZipExtractorService.checkAndExtractZipIfNeeded(
        path,
        onProgress: (p, m) {
          progressNotifier.value = p;
          messageNotifier.value = m;
          isExtractingNotifier.value = true;
        },
        onAskDeleteZip: () async {
          // סגירת דיאלוג ההתקדמות
          if (context.mounted) {
            Navigator.of(context).pop();
          }

          // שאלת הuser
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('מחיקת file דחוס'),
              content: const Text(
                'האם לdeleted את file ה-ZIP המקורי?\n\n'
                'הfile הדחוס אינו נצרך עבור פעילות התוכנה והוא רק תופס מקום.\n'
                'מומלץ לdeleted אותו.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('השאר את הfile'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete את הfile'),
                ),
              ],
            ),
          );

          // פתיחה again של דיאלוג ההתקדמות
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                title: const Text('משלים...'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('משלים חילוץ...'),
                  ],
                ),
              ),
            );
          }

          return shouldDelete ?? false;
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!extractionResult.success) {
        onError(extractionResult.errorMessage ?? 'error no ידועה');
      } else {
        onSuccess(extractionResult);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      onError(e.toString());
    } finally {
      progressNotifier.dispose();
      messageNotifier.dispose();
      isExtractingNotifier.dispose();
    }
  }
}
