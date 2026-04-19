// lib/widgets/dialogs.dart
//
// Barrel export לכל דיאלוגי האפליקציה.
//
// ─── דיאלוגי confirm/cancel ─────────────────────────────────────────────────────
// [ConfirmationDialog] / [showConfirmationDialog]     → confirmation_dialog.dart
//   שימוש: דיאלוג עם [isDangerous], [confirmColor], הדגשת focus.
//
// [SingleActionDialog] / [showSingleActionDialog]     → dialogs/app_dialogs.dart
// [TwoActionsDialog]   / [showTwoActionsDialog]       → dialogs/app_dialogs.dart
// [WarningDialog]      / [showWarningDialog]          → dialogs/app_dialogs.dart
//   שימוש: דיאלוגים M3 FilledButton לactions generalות.
//
// ─── דיאלוגי קלט ─────────────────────────────────────────────────────────────
// [InputDialog] / [showInputDialog]                   → input_dialog.dart
//
// ─── דיאלוגי settings ──────────────────────────────────────────────────────────
// [GenericSettingsDialog]                             → generic_settings_dialog.dart
//
// ─── דיאלוגי בחירה ───────────────────────────────────────────────────────────
// [SelectionDialog]                                   → selection_dialog.dart
// ─── מיכל general ───────────────────────────────────────────────────────────────
// [ReusableItemsDialog]                               → reusable_items_dialog.dart

export '../confirmation_dialog.dart';
export 'app_dialogs.dart';
export '../input_dialog.dart';
export '../selection_dialog.dart';
