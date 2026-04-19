import 'package:flutter/material.dart';
import 'package:otzaria/widgets/custom_ui_components.dart';
import 'package:otzaria/widgets/rtl_text_field.dart';

Future<String?> showErrorReportSenderEmailDialog({
  required BuildContext context,
  String initialValue = '',
  String title = 'כתובת מייל לidentify',
  String subtitle =
      'כתובת זו תצורף לדיווח כדי שצוות Otzaria יוכל לBack אליכם במקרה הצורך.',
}) async {
  final controller = TextEditingController(text: initialValue);

  final confirmed = await showSingleActionDialog(
    context: context,
    title: title,
    confirmText: 'Save',
    customContent: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          subtitle,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: RtlTextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              labelText: 'כתובת דוא"ל',
              hintText: 'name@example.com',
            ),
            autofocus: true,
          ),
        ),
      ],
    ),
  );

  final value = controller.text.trim();
  controller.dispose();

  if (confirmed != true) {
    return null;
  }

  return value;
}
