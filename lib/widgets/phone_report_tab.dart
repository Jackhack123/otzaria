import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import '../models/phone_report_data.dart';
import '../widgets/reporting_numbers_widget.dart';

/// Tab widget for phone-based error reporting
class PhoneReportTab extends StatefulWidget {
  final String selectedText;
  final double fontSize;
  final String libraryVersion;
  final int? bookId;
  final int lineNumber;
  final void Function(
          String selectedText, int errorId, String moreInfo, int lineNumber)?
      onSubmit;
  final VoidCallback? onCancel;

  const PhoneReportTab({
    super.key,
    required this.selectedText,
    required this.fontSize,
    required this.libraryVersion,
    required this.bookId,
    required this.lineNumber,
    this.onSubmit,
    this.onCancel,
  });

  @override
  State<PhoneReportTab> createState() => _PhoneReportTabState();
}

class _PhoneReportTabState extends State<PhoneReportTab> {
  ErrorType? _selectedErrorType;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> get _validationErrors {
    final errors = <String>[];

    if (widget.selectedText.isEmpty) {
      errors.add('בחירת הtext שבו נמצאת הerror');
    }

    if (_selectedErrorType == null) {
      errors.add('סוג הerror');
    }

    if (widget.bookId == null) {
      errors.add('no ניתן למצוא את הbook במאגר הנתונים');
    }

    if (widget.libraryVersion == 'unknown') {
      errors.add('no ניתן לקרוא את גירסת the library');
    }

    return errors;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructions(context),
          const SizedBox(height: 16),
          _buildTextSelection(context),
          const SizedBox(height: 16),
          _buildErrorTypeSelection(context),
          const SizedBox(height: 16),
          _buildReportingNumbers(context),
          const SizedBox(height: 16),
          _buildValidationErrors(context),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'parentאות לדיווח טלפוני:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              '1. בחר את סוג הerror   •  '
              '2. השתמש במbooks המוצגים למטה כשתתקשר',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הtext שselected:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(
            maxHeight: 200,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.selectedText,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontFamily: Settings.getValue('key-font-family') ?? 'candara',
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorTypeSelection(BuildContext context) {
    final isEnabled = widget.selectedText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'בחר סוג error:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, // מרווח אופקי בין הbuttons
          runSpacing: 8, // מרווח אנכי בין הlines
          children: ErrorType.errorTypes.map((errorType) {
            final isSelected = _selectedErrorType?.id == errorType.id;

            return FilterChip(
              label: Text(
                errorType.hebrewLabel,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : isEnabled
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).disabledColor,
                ),
              ),
              selected: isSelected,
              onSelected: isEnabled
                  ? (bool selected) {
                      setState(() {
                        _selectedErrorType = selected ? errorType : null;
                      });
                    }
                  : null,
              backgroundColor: isEnabled
                  ? null
                  : Theme.of(context).disabledColor.withValues(alpha: 0.1),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : isEnabled
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).disabledColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReportingNumbers(BuildContext context) {
    return ReportingNumbersWidget(
      libraryVersion: widget.libraryVersion,
      bookId: widget.bookId,
      lineNumber: widget.lineNumber,
      errorId: _selectedErrorType?.id,
    );
  }

  Widget _buildValidationErrors(BuildContext context) {
    final errors = _validationErrors;
    if (errors.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FluentIcons.error_circle_24_regular,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'אי אפשר להתקדם... עדיין no מיnoתם בטופס...',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...errors.take(errors.length - 1).map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          error,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                )),
            // הline האחרונה עם button cancel בצד שמאל
            if (errors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        errors.last,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // button cancel בצד שמאל של הline האחרונה
                    Container(
                      padding:
                          const EdgeInsets.all(3), // מרווח לבן מסביב הbutton
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius:
                            BorderRadius.circular(20), // עיגול כמו button רגיל
                      ),
                      child: TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('cancel הדיווח'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // אם יש errors ולידציה, הbutton cancel מוצג במלבן הerrors
    // אחרת, מציגים button cancel רגיל
    final errors = _validationErrors;
    if (errors.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('cancel הדיווח'),
        ),
      ],
    );
  }
}
