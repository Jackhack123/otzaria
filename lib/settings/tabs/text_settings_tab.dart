import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/theme/app_fonts.dart';
import 'package:otzaria/settings/engine/settings_engine_exports.dart';
import 'package:otzaria/settings/services/per_book_settings_service.dart';
import 'package:otzaria/settings/settings_card.dart';
import 'package:otzaria/theme/layout_tokens.dart';
import 'package:otzaria/widgets/custom_ui_components.dart';
import 'package:otzaria/core/ui_snack.dart';

/// טאב settings תצוגת books
/// ניתן להשתמש בו גם כcontent בתוך דיאלוג וגם כטאב במסך settings
class TextSettingsTab extends StatelessWidget {
  /// האם להציג כדיאלוג (עם button סגירה) או כטאב (לno)
  final bool isDialog;

  const TextSettingsTab({super.key, this.isDialog = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final content = SingleChildScrollView(
          primary: true,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFontSection(context, settingsState),
              kSettingsCardSpacing,
              _buildNikudSection(context, settingsState),
              kSettingsCardSpacing,
              _buildCopySection(context, settingsState),
              kSettingsCardSpacing,
              _buildPerBookSection(context, settingsState),
            ],
          ),
        );

        return content;
      },
    );
  }

  Widget _buildFontSection(BuildContext context, SettingsState state) {
    return SettingsCard(
      title: 'settings גופן ועיצוב',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < LayoutBreakpoints.compact;
            final colorScheme = Theme.of(context).colorScheme;
            final divider = Divider(
              height: 1,
              thickness: 1.5,
              color: colorScheme.surfaceContainerHighest,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // line 1: גודל גופן הbook + גופן text
                if (isNarrow) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _FontSizeSlider(
                      icon: FluentIcons.text_font_size_24_regular,
                      label: 'גודל גופן הbook',
                      value: state.fontSize.clamp(15, 60),
                      min: 15,
                      max: 60,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(UpdateFontSize(value));
                      },
                    ),
                  ),
                  divider,
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _FontDropdown(
                      icon: FluentIcons.text_font_24_regular,
                      label: 'גופן text',
                      value: state.fontFamily,
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateFontFamily(value));
                        }
                      },
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FontSizeSlider(
                            icon: FluentIcons.text_font_size_24_regular,
                            label: 'גודל גופן הbook',
                            value: state.fontSize.clamp(15, 60),
                            min: 15,
                            max: 60,
                            onChanged: (value) {
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateFontSize(value));
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FontDropdown(
                            icon: FluentIcons.text_font_24_regular,
                            label: 'גופן text',
                            value: state.fontFamily,
                            onChanged: (value) {
                              if (value != null) {
                                context
                                    .read<SettingsBloc>()
                                    .add(UpdateFontFamily(value));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                divider,

                // line 2: גודל גופן Commentators + גופן Commentators
                if (isNarrow) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _FontSizeSlider(
                      icon: FluentIcons.text_font_size_24_regular,
                      label: 'גודל גופן Commentators',
                      value: state.commentatorsFontSize.clamp(10, 40),
                      min: 10,
                      max: 40,
                      onChanged: (value) {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateCommentatorsFontSize(value));
                      },
                    ),
                  ),
                  divider,
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _FontDropdown(
                      icon: FluentIcons.book_24_regular,
                      label: 'גופן Commentators',
                      value: state.commentatorsFontFamily,
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateCommentatorsFontFamily(value));
                        }
                      },
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _FontSizeSlider(
                            icon: FluentIcons.text_font_size_24_regular,
                            label: 'גודל גופן Commentators',
                            value: state.commentatorsFontSize.clamp(10, 40),
                            min: 10,
                            max: 40,
                            onChanged: (value) {
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateCommentatorsFontSize(value));
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FontDropdown(
                            icon: FluentIcons.book_24_regular,
                            label: 'גופן Commentators',
                            value: state.commentatorsFontFamily,
                            onChanged: (value) {
                              if (value != null) {
                                context
                                    .read<SettingsBloc>()
                                    .add(UpdateCommentatorsFontFamily(value));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                divider,

                // line 3: מרווח בין lines (תמיד חצי רוחב)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isNarrow
                      ? _FontSizeSlider(
                          icon: FluentIcons
                              .text_align_distributed_vertical_24_regular,
                          label: 'מרווח בין lines',
                          value: state.lineHeight.clamp(1.0, 3.0),
                          min: 1.0,
                          max: 3.0,
                          divisions: 20,
                          onChanged: (value) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateLineHeight(value));
                          },
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _FontSizeSlider(
                                icon: FluentIcons
                                    .text_align_distributed_vertical_24_regular,
                                label: 'מרווח בין lines',
                                value: state.lineHeight.clamp(1.0, 3.0),
                                min: 1.0,
                                max: 3.0,
                                divisions: 20,
                                onChanged: (value) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateLineHeight(value));
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                ),
                divider,
                _TextWidthSlider(state: state),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNikudSection(BuildContext context, SettingsState state) {
    // קביעת הvalue הcurrent של הניקוד
    String nikudValue;
    if (!state.defaultRemoveNikud) {
      nikudValue = 'show_always';
    } else if (state.removeNikudFromTanach) {
      nikudValue = 'hide_all';
    } else {
      nikudValue = 'show_tanach_only';
    }

    // קביעת ה-subtitle בהתאם למצב
    String nikudSubtitle;
    switch (nikudValue) {
      case 'show_always':
        nikudSubtitle = 'הניקוד יוצג בכל הbooks';
        break;
      case 'show_tanach_only':
        nikudSubtitle = 'הניקוד יוצג בbookי הWritten Torah בלבד';
        break;
      case 'hide_all':
        nikudSubtitle = 'הניקוד no יוצג בכלל';
        break;
      default:
        nikudSubtitle = '';
    }

    return SettingsCard(
      title: 'כתרי אותיות',
      children: [
        SegmentedSettingsTile<String>(
          icon: FluentIcons.text_font_info_24_regular,
          title: 'הצגת הניקוד',
          subtitle: nikudSubtitle,
          options: const [
            SegmentOption(value: 'show_always', label: 'הצג תמיד'),
            SegmentOption(value: 'show_tanach_only', label: 'הצג בWritten Torah'),
            SegmentOption(value: 'hide_all', label: 'אל תציג'),
          ],
          currentValue: nikudValue,
          onChanged: (value) {
            switch (value) {
              case 'show_always':
                context
                    .read<SettingsBloc>()
                    .add(const UpdateDefaultRemoveNikud(false));
                break;
              case 'show_tanach_only':
                context
                    .read<SettingsBloc>()
                    .add(const UpdateDefaultRemoveNikud(true));
                context
                    .read<SettingsBloc>()
                    .add(const UpdateRemoveNikudFromTanach(false));
                break;
              case 'hide_all':
                context
                    .read<SettingsBloc>()
                    .add(const UpdateDefaultRemoveNikud(true));
                context
                    .read<SettingsBloc>()
                    .add(const UpdateRemoveNikudFromTanach(true));
                break;
            }
          },
        ),
        SwitchSettingsTile(
          leading: const Icon(FluentIcons.shield_keyhole_24_regular),
          title: RichText(
            text: TextSpan(
              style: kSettingsTitleStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: const [
                TextSpan(text: 'הצגת name הקודש'),
              ],
            ),
          ),
          subtitle: Text(
            !state.replaceHolyNames
                ? 'הname הקדוש יוצג'
                : 'הname הקדוש no יוצג מפני קדושתו',
            style: kSettingsSubtitleStyle,
          ),
          value: !state.replaceHolyNames,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateReplaceHolyNames(!value));
          },
        ),
        SwitchSettingsTile(
          title: const Text('הצגת טעמי המקרא', style: kSettingsTitleStyle),
          subtitle: Text(
              state.showTeamim ? 'המקרא יוצג עם טעמים' : 'המקרא יוצג לno טעמים',
              style: kSettingsSubtitleStyle),
          value: state.showTeamim,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateShowTeamim(value));
          },
        ),
      ],
    );
  }

  Widget _buildCopySection(BuildContext context, SettingsState state) {
    return SettingsCard(
      title: 'settings Copyה',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < LayoutBreakpoints.compact;
            final colorScheme = Theme.of(context).colorScheme;
            final divider = Divider(
              height: 1,
              thickness: 1.5,
              color: colorScheme.surfaceContainerHighest,
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Copyה עם כותרות
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(FluentIcons.copy_24_regular),
                            const SizedBox(width: 8),
                            Text('Copyה עם כותרות', style: kSettingsTitleStyle),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: state.copyWithHeaders,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('לno')),
                            DropdownMenuItem(
                                value: 'book_name',
                                child: Text('name הbook בלבד')),
                            DropdownMenuItem(
                                value: 'book_and_path',
                                child: Text('name הbook+path')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateCopyWithHeaders(value));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  divider,
                  // עיצוב Copyה
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(FluentIcons.text_align_right_24_regular),
                            const SizedBox(width: 8),
                            Text('עיצוב Copyה', style: kSettingsTitleStyle),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: state.copyHeaderFormat,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'same_line_after_brackets',
                                child: Text('אותה line אחרי (עם סוגריים)')),
                            DropdownMenuItem(
                                value: 'same_line_after_no_brackets',
                                child: Text('אותה line אחרי (בלי סוגריים)')),
                            DropdownMenuItem(
                                value: 'same_line_before_brackets',
                                child: Text('אותה line לפני (עם סוגריים)')),
                            DropdownMenuItem(
                                value: 'same_line_before_no_brackets',
                                child: Text('אותה line לפני (בלי סוגריים)')),
                            DropdownMenuItem(
                                value: 'separate_line_after',
                                child: Text('פסקה נפרדת אחרי')),
                            DropdownMenuItem(
                                value: 'separate_line_before',
                                child: Text('פסקה נפרדת לפני')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateCopyHeaderFormat(value));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(FluentIcons.copy_24_regular),
                          const SizedBox(width: 8),
                          Text('Copyה עם כותרות', style: kSettingsTitleStyle),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: state.copyWithHeaders,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'none', child: Text('לno')),
                                DropdownMenuItem(
                                    value: 'book_name',
                                    child: Text('name הbook בלבד')),
                                DropdownMenuItem(
                                    value: 'book_and_path',
                                    child: Text('name הbook+path')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateCopyWithHeaders(value));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(FluentIcons.text_align_right_24_regular),
                          const SizedBox(width: 8),
                          Text('עיצוב Copyה', style: kSettingsTitleStyle),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: state.copyHeaderFormat,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'same_line_after_brackets',
                                    child: Text('אותה line אחרי (עם סוגריים)')),
                                DropdownMenuItem(
                                    value: 'same_line_after_no_brackets',
                                    child:
                                        Text('אותה line אחרי (בלי סוגריים)')),
                                DropdownMenuItem(
                                    value: 'same_line_before_brackets',
                                    child: Text('אותה line לפני (עם סוגריים)')),
                                DropdownMenuItem(
                                    value: 'same_line_before_no_brackets',
                                    child:
                                        Text('אותה line לפני (בלי סוגריים)')),
                                DropdownMenuItem(
                                    value: 'separate_line_after',
                                    child: Text('פסקה נפרדת אחרי')),
                                DropdownMenuItem(
                                    value: 'separate_line_before',
                                    child: Text('פסקה נפרדת לפני')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateCopyHeaderFormat(value));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPerBookSection(BuildContext context, SettingsState state) {
    return SettingsCard(
      title: 'settings לפי book',
      children: [
        SwitchSettingsTile(
          title: const Text('save התאמות לכל book בנפרד',
              style: kSettingsTitleStyle),
          subtitle: Text(
              state.enablePerBookSettings
                  ? 'שינויים בסרגל הלחצנים יישמרו לכל book בנפרד'
                  : 'כל הbooks ישתמשו בsettings הgeneralות',
              style: kSettingsSubtitleStyle),
          value: state.enablePerBookSettings,
          onChanged: (value) {
            context
                .read<SettingsBloc>()
                .add(UpdateEnablePerBookSettings(value));
          },
        ),
        if (state.enablePerBookSettings)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _resetPerBookSettings(context),
              icon: const Icon(FluentIcons.delete_24_regular),
              label: const Text('אפס את כל settings אלו, בכל הbooks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _resetPerBookSettings(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('confirm delete'),
        content: const Text(
            'האם אתה בטוח שברצונך לdeleted את כל הsettings לפי book?\naction זו אינה ניתנת לcancel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete הכל'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await PerBookSettings.deleteAllSettings();
      UiSnack.show('כל הsettings המיוחדות נDeleteו בsuccess');
    }
  }
}

// Widget עזר לסליידר גודל גופן
class _FontSizeSlider extends StatefulWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _FontSizeSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  State<_FontSizeSlider> createState() => _FontSizeSliderState();
}

class _FontSizeSliderState extends State<_FontSizeSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(_FontSizeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.label, style: kSettingsTitleStyle),
            ),
            Text(
              widget.divisions != null
                  ? _currentValue.toStringAsFixed(1)
                  : _currentValue.toStringAsFixed(0),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _currentValue,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions ?? (widget.max - widget.min).toInt(),
          label: widget.divisions != null
              ? _currentValue.toStringAsFixed(1)
              : _currentValue.toStringAsFixed(0),
          onChanged: (value) {
            setState(() => _currentValue = value);
            widget.onChanged(value);
          },
        ),
      ],
    );
  }
}

// Widget עזר לדרופדאון גופן
class _FontDropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  const _FontDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(label, style: kSettingsTitleStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            dropdownColor: Theme.of(context).colorScheme.surface,
            isExpanded: true,
            items: AppFonts.buildDropdownItems(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Widget עזר לסליידר רוחב text
class _TextWidthSlider extends StatefulWidget {
  final SettingsState state;

  const _TextWidthSlider({required this.state});

  @override
  State<_TextWidthSlider> createState() => _TextWidthSliderState();
}

class _TextWidthSliderState extends State<_TextWidthSlider> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentMaxWidth = widget.state.textMaxWidth;

    int currentLevel;
    if (currentMaxWidth < 0) {
      currentLevel = (-currentMaxWidth).toInt();
    } else if (currentMaxWidth == 0) {
      currentLevel = 0;
    } else {
      final ratio = currentMaxWidth / screenWidth;
      currentLevel = ((1.0 - ratio) / 0.05).round().clamp(0, 14);
    }

    String getLevelDescription(int level) {
      if (level == 0) return 'full';
      final percent = 100 - (level * 5);
      return '$percent%';
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(FluentIcons.text_align_justify_24_regular),
          title: const Text('רוחב הtext', style: kSettingsTitleStyle),
          subtitle: Text(
            currentLevel == 0
                ? 'הtext יfull את כל הרוחב הזמין'
                : 'הtext יהיה צר יותר ומרוכז במסך',
            style: kSettingsSubtitleStyle,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: currentLevel.toDouble(),
            min: 0,
            max: 14,
            divisions: 14,
            label: getLevelDescription(currentLevel),
            onChanged: (value) {
              setState(() {});
              final level = value.toInt();
              double newMaxWidth;
              if (level == 0) {
                newMaxWidth = 0;
              } else {
                final widthPercent = 1.0 - (level * 0.05);
                newMaxWidth = screenWidth * widthPercent;
              }
              context.read<SettingsBloc>().add(UpdateTextMaxWidth(newMaxWidth));
            },
          ),
        ),
      ],
    );
  }
}
