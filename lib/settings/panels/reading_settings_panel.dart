import 'package:flutter/material.dart';
import 'package:otzaria/settings/tabs/text_settings_tab.dart';

/// פאנל settings תצוגת הbooks (לשימוש כ-overlay צף)
class ReadingSettingsPanel extends StatelessWidget {
  const ReadingSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: TextSettingsTab(isDialog: true),
    );
  }
}
