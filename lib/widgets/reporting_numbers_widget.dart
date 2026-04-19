import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:otzaria/core/ui_snack.dart';

/// Widget that displays reporting numbers with copy functionality
class ReportingNumbersWidget extends StatelessWidget {
  final String libraryVersion;
  final int? bookId;
  final int lineNumber;
  final int? errorId;
  final bool showPhoneNumber;

  const ReportingNumbersWidget({
    super.key,
    required this.libraryVersion,
    required this.bookId,
    required this.lineNumber,
    this.errorId,
    this.showPhoneNumber = true,
  });

  static const String _phoneNumber = '(+972) 077-4636-198';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'נתוני הדיווח:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            // Wrap מאפשר לנתונים להיות באותה line ולעבור לline nextה אם אין מקום
            Wrap(
              spacing: 16, // מרווח אופקי בין הפריטים
              runSpacing: 8, // מרווח אנכי בין הlines
              children: [
                _buildCompactNumberItem(
                  context,
                  'מbook גירסה',
                  libraryVersion,
                ),
                _buildCompactNumberItem(
                  context,
                  'מbook book',
                  bookId?.toString() ?? 'no זמין',
                  enabled: bookId != null,
                ),
                _buildCompactNumberItem(
                  context,
                  'מbook line',
                  lineNumber.toString(),
                ),
                _buildCompactNumberItem(
                  context,
                  'מbook error',
                  errorId?.toString() ?? 'no selected',
                  enabled: errorId != null,
                ),
              ],
            ),

            if (showPhoneNumber) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildPhoneSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactNumberItem(
    BuildContext context,
    String label,
    String value, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: enabled ? null : Theme.of(context).disabledColor,
                ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: enabled ? () => _copyToClipboard(context, value) : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                FluentIcons.copy_24_regular,
                size: 16,
                color: enabled
                    ? Theme.of(context).iconTheme.color
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 1. הכותרת שתוצג בצד ימין
            Text(
              'קו Otzaria:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textDirection: TextDirection.rtl,
            ),

            // 2. Spacer שתופס את כל המקום הפנוי ודוחף את שאר הווידג'טים שמאלה
            const Spacer(),

            // 3. מbook הטלפון מודגש (כבר no צריך להיות בתוך Expanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: isMobile
                  ? InkWell(
                      onTap: () => _makePhoneCall(context),
                      child: Text(
                        _phoneNumber,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                        textDirection: TextDirection.ltr,
                      ),
                    )
                  : SelectableText(
                      _phoneNumber,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                      textDirection: TextDirection.ltr,
                    ),
            ),
            const SizedBox(width: 8),

            // 4. button הCopyה
            IconButton(
              onPressed: () => _copyToClipboard(context, _phoneNumber),
              icon: const Icon(FluentIcons.copy_24_regular, size: 18),
              tooltip: 'Copy מbook טלפון',
              visualDensity: VisualDensity.compact,
            ),

            // 5. button החיוג (למובייל)
            if (isMobile) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _makePhoneCall(context),
                icon: const Icon(FluentIcons.phone_24_regular, size: 18),
                tooltip: 'התקשר',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // text המyear נשאר כמו שהיה
        Text(
          'לפירוט נוסף, השאר הקלטה ברורה!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        UiSnack.show('הועתק ללוח: $text');
      }
    } catch (e) {
      if (context.mounted) {
        UiSnack.showError('error בCopyה ללוח');
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    try {
      final phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          UiSnack.showError('no ניתן לopen את אפליקציית הטלפון');
        }
      }
    } catch (e) {
      if (context.mounted) {
        UiSnack.showError('error בפתיחת אפליקציית הטלפון');
      }
    }
  }
}
