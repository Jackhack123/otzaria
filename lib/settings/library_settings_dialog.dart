import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/widgets/generic_settings_dialog.dart';

/// פונקציה גלובלית להצגת דיאלוג Library Settings
/// ניתן לקרוא לה מכל מקום באפליקציה
void showLibrarySettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, currentSettingsState) {
        return GenericSettingsDialog(
          title: 'Library Settings',
          width: 500,
          items: [
            SwitchSettingsItem(
              title: 'Display books from external sources?',
              subtitle: currentSettingsState.showExternalBooks
                  ? 'Books from external sources will be displayed'
                  : 'Only Otzaria library books will be displayed',
              value: currentSettingsState.showExternalBooks,
              onChanged: (value) {
                context
                    .read<SettingsBloc>()
                    .add(UpdateShowExternalBooks(value));
                context.read<SettingsBloc>().add(UpdateShowHebrewBooks(value));
                context
                    .read<SettingsBloc>()
                    .add(UpdateShowOtzarHachochma(value));
              },
              dependentItems: currentSettingsState.showExternalBooks
                  ? [
                      CheckboxSettingsItem(
                        title: 'Show books from Otzar HaChochma',
                        value: currentSettingsState.showOtzarHachochma,
                        onChanged: (bool? value) {
                          if (value != null) {
                            context.read<SettingsBloc>().add(
                                  UpdateShowOtzarHachochma(value),
                                );
                          }
                        },
                      ),
                      CheckboxSettingsItem(
                        title: 'Show books from Hebrew Books',
                        value: currentSettingsState.showHebrewBooks,
                        onChanged: (bool? value) {
                          if (value != null) {
                            context.read<SettingsBloc>().add(
                                  UpdateShowHebrewBooks(value),
                                );
                          }
                        },
                      ),
                    ]
                  : null,
            ),
          ],
        );
      },
    ),
  );
}
