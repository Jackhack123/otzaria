/// קובע האם יש לSave את הtext הselected כבחירה האחרונה.
///
/// בחירה emptyה יכולה להופיע רגעית אחרי tap ימנית שפותחת תפריט הקשר,
/// ולyes אין לדרוס בגללה את הtext האחרון שהuser סימן.
bool shouldPersistSelectedText(String? selectedText) {
  return selectedText != null && selectedText.trim().isNotEmpty;
}

/// מחזיר את הtext שצריך להישאר Save עבור actions ההקשר.
///
/// כאשר [latestSelectedText] empty או null, שומרים את [previousSelectedText]
/// כדי שtap ימנית no תDelete את הבחירה האחרונה.
String? resolvePersistedSelectedText({
  required String? previousSelectedText,
  required String? latestSelectedText,
}) {
  return shouldPersistSelectedText(latestSelectedText)
      ? latestSelectedText
      : previousSelectedText;
}
