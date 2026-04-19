import 'package:flutter/material.dart';
import 'package:otzaria/settings/panels/library_settings_panel.dart';

/// function גלובלית להצגת דיאלוג settings library
/// ניתן לקרוא לה מכל מקום באפליקציה
void showLibrarySettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(
        'settings library',
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 650,
        height: MediaQuery.of(dialogContext).size.height * 0.7,
        // עטפנו ב-SingleChildScrollView כדי שיהיה ניתן לscroll אם המסך small
        child: const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LibrarySettingsPanel(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('closed'),
        ),
      ],
    ),
  );
}
