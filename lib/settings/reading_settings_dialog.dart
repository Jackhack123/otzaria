import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/constants/fonts.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/settings/per_book_settings.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:otzaria/widgets/dialogs.dart';

/// Global function to display book display settings dialog
/// Can be called from anywhere in the application
void showReadingSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return AlertDialog(
          title: const Text(
            'Book Display Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section title: Font and Formatting Settings
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Text(
                      'Font and Formatting Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // שורה ראשונה: גודל גופן הספר וגופן טקסט
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // גודל גופן הספר - 1/2
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              double currentFontSize =
                                  settingsState.fontSize.clamp(15, 60);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons
                                          .text_font_size_24_regular),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Book Font Size',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      Text(
                                        currentFontSize.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: currentFontSize,
                                    min: 15,
                                    max: 60,
                                    divisions: 45,
                                    label: currentFontSize.toStringAsFixed(0),
                                    onChanged: (value) {
                                      setState(() {});
                                      context
                                          .read<SettingsBloc>()
                                          .add(UpdateFontSize(value));
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // גופן טקסט ראשי - 1/2
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return _FontSelector(
                                label: 'Text Font',
                                icon: FluentIcons.text_font_24_regular,
                                value: settingsState.fontFamily,
                                onChanged: (value) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateFontFamily(value));
                                  setState(() {});
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // שורה שנייה: גודל גופן מפרשים וגופן מפרשים
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // גודל גופן מפרשים - 1/2
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              double currentCommentatorsFontSize = settingsState
                                  .commentatorsFontSize
                                  .clamp(10, 40);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons
                                          .text_font_size_24_regular),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Commentary Font Size and Links',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      Text(
                                        currentCommentatorsFontSize
                                            .toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: currentCommentatorsFontSize,
                                    min: 10,
                                    max: 40,
                                    divisions: 30,
                                    label: currentCommentatorsFontSize
                                        .toStringAsFixed(0),
                                    onChanged: (value) {
                                      setState(() {});
                                      context.read<SettingsBloc>().add(
                                          UpdateCommentatorsFontSize(value));
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // גופן מפרשים - 1/2
                        Expanded(
                          flex: 1,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return _FontSelector(
                                label: 'Commentary Font',
                                icon: FluentIcons.book_24_regular,
                                value: settingsState.commentatorsFontFamily,
                                onChanged: (value) {
                                  context.read<SettingsBloc>().add(
                                      UpdateCommentatorsFontFamily(value));
                                  setState(() {});
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // רוחב הטקסט
                  StatefulBuilder(
                    builder: (context, setState) {
                      // רוחב המסך לחישוב פיקסלים
                      final screenWidth = MediaQuery.of(context).size.width;
                      final currentMaxWidth = settingsState.textMaxWidth;

                      // חישוב הרמה הנוכחית מהרוחב השמור
                      // ערך שלילי = רמה דינמית (ברירת מחדל)
                      // 0 = רוחב מלא
                      // ערך חיובי = פיקסלים קבועים
                      int currentLevel;
                      if (currentMaxWidth < 0) {
                        // ערך שלילי = רמה דינמית
                        currentLevel = (-currentMaxWidth).toInt();
                      } else if (currentMaxWidth == 0) {
                        currentLevel = 0;
                      } else {
                        // ערך חיובי = פיקסלים, נחשב את הרמה המקבילה
                        final ratio = currentMaxWidth / screenWidth;
                        currentLevel =
                            ((1.0 - ratio) / 0.05).round().clamp(0, 14);
                      }

                      // תיאור לפי אחוז הרוחב
                      String getLevelDescription(int level) {
                        if (level == 0) return 'Full';
                        final percent = 100 - (level * 5);
                        return '$percent%';
                      }

                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                                FluentIcons.text_align_justify_24_regular),
                            title: const Text('Text Width'),
                            subtitle: Text(
                              currentLevel == 0
                                  ? 'Text will fill all available width'
                                  : 'Text will be narrower and centered on screen',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: Text(
                              getLevelDescription(currentLevel),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Slider(
                              value: currentLevel.toDouble(),
                              min: 0,
                              max: 14,
                              divisions: 14,
                              label: getLevelDescription(currentLevel),
                              onChanged: (value) {
                                setState(() {});
                                // שומרים פיקסלים קבועים (לא רמה דינמית)
                                final level = value.toInt();
                                double newMaxWidth;
                                if (level == 0) {
                                  newMaxWidth = 0; // רוחב מלא
                                } else {
                                  // מחשבים פיקסלים לפי רוחב המסך הנוכחי
                                  final widthPercent = 1.0 - (level * 0.05);
                                  newMaxWidth = screenWidth * widthPercent;
                                }
                                context
                                    .read<SettingsBloc>()
                                    .add(UpdateTextMaxWidth(newMaxWidth));
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // כותרת: הסרת ניקוד וטעמים
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Text(
                      'Remove Vowels and Cantillation Marks',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // הצגת טעמי המקרא
                  SwitchListTile(
                    title: const Text('Display Cantillation Marks'),
                    subtitle: Text(settingsState.showTeamim
                        ? 'Scripture will display with cantillation marks'
                        : 'Scripture will display without cantillation marks'),
                    value: settingsState.showTeamim,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(UpdateShowTeamim(value));
                    },
                  ),
                  const Divider(),

                  // הסרת ניקוד כברירת מחדל
                  SwitchListTile(
                    title: const Text('Remove Vowels by Default'),
                    subtitle: Text(settingsState.defaultRemoveNikud
                        ? 'Vowels will be removed by default'
                        : 'Vowels will be displayed by default'),
                    value: settingsState.defaultRemoveNikud,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateDefaultRemoveNikud(value));
                    },
                  ),
                  if (settingsState.defaultRemoveNikud)
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: CheckboxListTile(
                        title: const Text('Remove Vowels from Torah Books'),
                        subtitle: const Text('Torah books will also display without vowels'),
                        value: settingsState.removeNikudFromTanach,
                        onChanged: (bool? value) {
                          if (value != null) {
                            context.read<SettingsBloc>().add(
                                  UpdateRemoveNikudFromTanach(value),
                                );
                          }
                        },
                      ),
                    ),

                  // כותרת: הגדרות טאבים
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Text(
                      'Tab Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // יישור טאבים לימין
                  SwitchListTile(
                    title: const Text('Align Tabs to Right'),
                    subtitle: Text(settingsState.alignTabsToRight
                        ? 'Tabs will display on the right side'
                        : 'Tabs will display in the center'),
                    value: settingsState.alignTabsToRight,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateAlignTabsToRight(value));
                    },
                  ),

                  // כותרת: התנהגות סרגל צד
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Text(
                      'Sidebar Behavior',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // הצמדת סרגל צד
                  SwitchListTile(
                    title: const Text('Pin Sidebar'),
                    subtitle: Text(settingsState.pinSidebar
                        ? 'Sidebar will always be pinned'
                        : 'Sidebar will behave normally'),
                    value: settingsState.pinSidebar,
                    onChanged: (value) {
                      context.read<SettingsBloc>().add(UpdatePinSidebar(value));
                      if (value) {
                        context
                            .read<SettingsBloc>()
                            .add(const UpdateDefaultSidebarOpen(true));
                      }
                    },
                  ),
                  const Divider(),

                  // פתיחת סרגל צד
                  SwitchListTile(
                    title: const Text('Open Sidebar by Default'),
                    subtitle: Text(settingsState.defaultSidebarOpen
                        ? 'Sidebar will open automatically'
                        : 'Sidebar will remain closed'),
                    value: settingsState.defaultSidebarOpen,
                    onChanged: settingsState.pinSidebar
                        ? null
                        : (value) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateDefaultSidebarOpen(value));
                          },
                  ),
                  const Divider(),

                  // ברירת מחדל להצגת מפרשים
                  StatefulBuilder(
                    builder: (context, setState) {
                      final splitedView =
                          Settings.getValue<bool>('key-splited-view') ?? false;
                      return SwitchListTile(
                        title: const Text('Default Commentary Display'),
                        subtitle: Text(splitedView
                            ? 'Commentaries will display next to the text'
                            : 'Commentaries will display below the text'),
                        value: splitedView,
                        onChanged: (value) {
                          setState(() {
                            Settings.setValue<bool>('key-splited-view', value);
                            // ניקוי קבצי per_book_settings מיותרים
                            final settingsBloc = context.read<SettingsBloc>();
                            PerBookSettings.cleanupRedundantSettings(
                              defaultFontSize: settingsBloc.state.fontSize,
                              defaultRemoveNikud:
                                  settingsBloc.state.defaultRemoveNikud,
                              defaultShowSplitView: value,
                            );
                          });
                        },
                      );
                    },
                  ),

                  // הגדרות העתקה
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Text(
                      'Copy Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // העתקה עם כותרות ועיצוב בשורה אחת
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // העתקה עם כותרות - 1/2
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons.copy_24_regular),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Copy with Headers',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: settingsState.copyWithHeaders,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    dropdownColor:
                                        Theme.of(context).colorScheme.surface,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'none', child: Text('None')),
                                      DropdownMenuItem(
                                          value: 'book_name',
                                          child: Text('Book Name Only')),
                                      DropdownMenuItem(
                                          value: 'book_and_path',
                                          child: Text('Book Name + Path')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        context
                                            .read<SettingsBloc>()
                                            .add(UpdateCopyWithHeaders(value));
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Copy Formatting - 1/2
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(FluentIcons
                                          .text_align_right_24_regular),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Copy Formatting',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        settingsState.copyHeaderFormat,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    dropdownColor:
                                        Theme.of(context).colorScheme.surface,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'same_line_after_brackets',
                                          child: Text(
                                              'Same line after (with brackets)')),
                                      DropdownMenuItem(
                                          value: 'same_line_after_no_brackets',
                                          child: Text(
                                              'Same line after (without brackets)')),
                                      DropdownMenuItem(
                                          value: 'same_line_before_brackets',
                                          child: Text(
                                              'Same line before (with brackets)')),
                                      DropdownMenuItem(
                                          value: 'same_line_before_no_brackets',
                                          child: Text(
                                              'Same line before (without brackets)')),
                                      DropdownMenuItem(
                                          value: 'separate_line_after',
                                          child: Text('Separate paragraph after')),
                                      DropdownMenuItem(
                                          value: 'separate_line_before',
                                          child: Text('Separate paragraph before')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        context
                                            .read<SettingsBloc>()
                                            .add(UpdateCopyHeaderFormat(value));
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // הגדרות פר-ספר
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Text(
                      'Per-Book Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  // הפעלת שמירת התאמות פר-ספר
                  SwitchListTile(
                    title: const Text('Save Per-Book Customizations'),
                    subtitle: Text(settingsState.enablePerBookSettings
                        ? 'Toolbar changes will be saved for each book separately'
                        : 'All books will use global settings'),
                    value: settingsState.enablePerBookSettings,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateEnablePerBookSettings(value));
                    },
                  ),

                  // כפתור איפוס כל ההגדרות הפר-ספריות
                  if (settingsState.enablePerBookSettings)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Confirmation'),
                              content: const Text(
                                  'Are you sure you want to delete all per-book settings?\nThis action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete All'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            await PerBookSettings.deleteAllSettings();
                            if (context.mounted) {
                              UiSnack.show(
                                  'All per-book settings have been deleted successfully');
                            }
                          }
                        },
                        icon: const Icon(FluentIcons.delete_24_regular),
                        label: const Text('Reset all these settings for all books'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),

                  const Divider(),

                  // הגדרות עורך טקסטים
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: const Text(
                      'Text Editor Settings',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  StatefulBuilder(
                    builder: (context, setState) {
                      double previewDebounce = Settings.getValue<double>(
                              'key-editor-preview-debounce') ??
                          150.0;
                      double cleanupDays = Settings.getValue<double>(
                              'key-editor-draft-cleanup-days') ??
                          30.0;
                      double draftsQuota = Settings.getValue<double>(
                              'key-editor-drafts-quota') ??
                          100.0;

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // עיכוב תצוגה מקדימה
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(FluentIcons.timer_24_regular),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Debounce Delay in Milliseconds',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${previewDebounce.toInt()}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: previewDebounce,
                                  min: 50,
                                  max: 300,
                                  divisions: 5,
                                  label: previewDebounce.toInt().toString(),
                                  onChanged: (value) {
                                    setState(() => previewDebounce = value);
                                    Settings.setValue<double>(
                                        'key-editor-preview-debounce', value);
                                  },
                                ),
                              ],
                            ),
                            const Divider(),

                            // ניקוי טיוטות ישנות
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                        FluentIcons.delete_dismiss_24_regular),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Cleanup Old Drafts (Days)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${cleanupDays.toInt()}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: cleanupDays,
                                  min: 7,
                                  max: 90,
                                  divisions: 12,
                                  label: cleanupDays.toInt().toString(),
                                  onChanged: (value) {
                                    setState(() => cleanupDays = value);
                                    Settings.setValue<double>(
                                        'key-editor-draft-cleanup-days', value);
                                  },
                                ),
                              ],
                            ),
                            const Divider(),

                            // מכסת טיוטות
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(FluentIcons.database_24_regular),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Drafts Quota (MB)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    Text(
                                      '${draftsQuota.toInt()}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: draftsQuota,
                                  min: 50,
                                  max: 100,
                                  divisions: 5,
                                  label: draftsQuota.toInt().toString(),
                                  onChanged: (value) {
                                    setState(() => draftsQuota = value);
                                    Settings.setValue<double>(
                                        'key-editor-drafts-quota', value);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    ),
  );
}

class _FontSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final ValueChanged<String> onChanged;

  const _FontSelector({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Find the label for the current value
    final selectedFont = AppFonts.availableFonts.firstWhere(
      (element) => element.value == value,
      orElse: () => AppFonts.availableFonts[0],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final fontItems = AppFonts.availableFonts
                .map((font) => SelectionItem<String>(
                      label: font.label,
                      value: font.value,
                      searchValue: '${font.label} ${font.value}',
                    ))
                .toList();

            final result = await showSelectionDialog<String>(
              context: context,
              title: 'Select Font',
              items: fontItems,
              initialValue: value,
              searchHint: 'Search font',
            );
            if (result != null) {
              onChanged(result);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              selectedFont.label,
              style: AppFonts.fontPaths.containsKey(selectedFont.value)
                  ? TextStyle(fontFamily: selectedFont.value)
                  : null,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
