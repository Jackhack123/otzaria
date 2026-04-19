import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart'
    hide SwitchSettingsTile;
import 'package:otzaria/settings/settings_card.dart';
import 'package:otzaria/widgets/custom_ui_components.dart';

/// טאב settings גימטריה
class GematriaSettingsTab extends StatefulWidget {
  const GematriaSettingsTab({super.key});

  @override
  State<GematriaSettingsTab> createState() => _GematriaSettingsTabState();
}

class _GematriaSettingsTabState extends State<GematriaSettingsTab> {
  late int maxResults;
  late bool filterDuplicates;
  late bool wholeVerseOnly;
  late bool torahOnly;
  late bool useSmallGematria;
  late bool useFinalLetters;
  late bool useWithKolel;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    maxResults = Settings.getValue<int>('key-gematria-max-results') ?? 100;
    filterDuplicates =
        Settings.getValue<bool>('key-gematria-filter-duplicates') ?? false;
    wholeVerseOnly =
        Settings.getValue<bool>('key-gematria-whole-verse-only') ?? false;
    torahOnly = Settings.getValue<bool>('key-gematria-torah-only') ?? false;
    useSmallGematria =
        Settings.getValue<bool>('key-gematria-use-small') ?? false;
    useFinalLetters =
        Settings.getValue<bool>('key-gematria-use-final-letters') ?? false;
    useWithKolel =
        Settings.getValue<bool>('key-gematria-use-with-kolel') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsCard(
            title: 'search גימטריה',
            children: [
              ListTile(
                leading: const Icon(FluentIcons.number_row_24_regular),
                title: const Text('מbook results מקסימלי',
                    style: kSettingsTitleStyle),
                subtitle: const Text('כמות הresults המקסימלית להצגה',
                    style: kSettingsSubtitleStyle),
                trailing: DropdownButton<int>(
                  value: maxResults,
                  underline: const SizedBox(),
                  items: [50, 100, 200, 500, 1000].map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => maxResults = value);
                      Settings.setValue<int>('key-gematria-max-results', value);
                    }
                  },
                ),
              ),
              SwitchSettingsTile(
                leading: const Icon(FluentIcons.filter_24_regular),
                title: const Text('סינון results כפולות',
                    style: kSettingsTitleStyle),
                subtitle: Text(
                  filterDuplicates
                      ? 'results זהות יוצגו פעם אחת בלבד'
                      : 'כל הresults יוצגו',
                  style: kSettingsSubtitleStyle,
                ),
                value: filterDuplicates,
                onChanged: (value) {
                  setState(() => filterDuplicates = value);
                  Settings.setValue<bool>(
                      'key-gematria-filter-duplicates', filterDuplicates);
                },
              ),
              SwitchSettingsTile(
                leading: const Icon(FluentIcons.text_word_count_24_regular),
                title: const Text('search פסוק שלם בלבד',
                    style: kSettingsTitleStyle),
                subtitle: Text(
                  wholeVerseOnly
                      ? 'search רק בפסוקים שלמים'
                      : 'search גם בחלקי פסוקים',
                  style: kSettingsSubtitleStyle,
                ),
                value: wholeVerseOnly,
                onChanged: (value) {
                  setState(() => wholeVerseOnly = value);
                  Settings.setValue<bool>(
                      'key-gematria-whole-verse-only', wholeVerseOnly);
                },
              ),
              SwitchSettingsTile(
                leading: const Icon(FluentIcons.book_24_regular),
                title:
                    const Text('search בתורה בלבד', style: kSettingsTitleStyle),
                subtitle: Text(
                  torahOnly ? 'search רק בחמישה חומשי תורה' : 'search בכל הbooks',
                  style: kSettingsSubtitleStyle,
                ),
                value: torahOnly,
                onChanged: (value) {
                  setState(() => torahOnly = value);
                  Settings.setValue<bool>('key-gematria-torah-only', torahOnly);
                },
              ),
            ],
          ),
          kSettingsCardSpacing,
          SettingsCard(
            title: 'שיטת חישוב גימטריה',
            children: [
              SwitchSettingsTile(
                leading: const Icon(FluentIcons.number_symbol_24_regular),
                title: const Text('גימטריה קטנה', style: kSettingsTitleStyle),
                subtitle: const Text('כל אות מחושבת לפי bookה אחת',
                    style: kSettingsSubtitleStyle),
                value: useSmallGematria,
                onChanged: (value) {
                  setState(() {
                    useSmallGematria = value;
                    if (useSmallGematria) {
                      useFinalLetters = false;
                      Settings.setValue<bool>(
                          'key-gematria-use-final-letters', false);
                    }
                  });
                  Settings.setValue<bool>(
                      'key-gematria-use-small', useSmallGematria);
                },
              ),
              SwitchSettingsTile(
                leading: const Icon(FluentIcons.text_font_24_regular),
                title: const Text('אותיות סופיות שונות',
                    style: kSettingsTitleStyle),
                subtitle: const Text('מנצפ"ך בvalues שונים',
                    style: kSettingsSubtitleStyle),
                value: useFinalLetters,
                onChanged: (value) {
                  setState(() {
                    useFinalLetters = value;
                    if (useFinalLetters) {
                      useSmallGematria = false;
                      Settings.setValue<bool>('key-gematria-use-small', false);
                    }
                  });
                  Settings.setValue<bool>(
                      'key-gematria-use-final-letters', useFinalLetters);
                },
              ),
              SwitchSettingsTile(
                leading: const Icon(FluentIcons.add_circle_24_regular),
                title: const Text('עם הכולל', style: kSettingsTitleStyle),
                subtitle: const Text('הוספת מbook האותיות לסכום',
                    style: kSettingsSubtitleStyle),
                value: useWithKolel,
                onChanged: (value) {
                  setState(() => useWithKolel = value);
                  Settings.setValue<bool>(
                      'key-gematria-use-with-kolel', useWithKolel);
                },
              ),
            ],
          ),
        ],
    );
  }
}
