/// כלל join מותר בין שתי טבnoות
class PluginJoinRule {
  final String tableA;
  final String columnA;
  final String tableB;
  final String columnB;

  const PluginJoinRule({
    required this.tableA,
    required this.columnA,
    required this.tableB,
    required this.columnB,
  });

  /// בודק אם ה-join המבוקש תואם את הכלל (בשני הכיוונים)
  bool matches(String t1, String c1, String t2, String c2) {
    return (tableA == t1 && columnA == c1 && tableB == t2 && columnB == c2) ||
        (tableA == t2 && columnA == c2 && tableB == t1 && columnB == c1);
  }
}

/// מדיניות גישה למסד נתונים עבור תוסף
class PluginDatabasePolicy {
  /// names הטבnoות המותרות לקריאה
  final Set<String> tables;

  /// pageות מותרות לפי name טבלה
  final Map<String, Set<String>> columnsByTable;

  /// general join מותרים
  final List<PluginJoinRule> allowedJoins;

  /// מbook lines מקסימלי לשאילתה
  final int maxLimit;

  /// מbook שאילתות מקסימלי ב-batch
  final int maxBatchQueries;

  /// time ריצה מקסימלי לשאילתה
  final Duration maxQueryDuration;

  /// מbook joins מקסימלי בשאילתה
  final int maxJoins;

  /// מbook pageות מקסימלי ב-select
  final int maxColumns;

  const PluginDatabasePolicy({
    required this.tables,
    required this.columnsByTable,
    required this.allowedJoins,
    this.maxLimit = 5000,
    this.maxBatchQueries = 5,
    this.maxQueryDuration = const Duration(milliseconds: 1500),
    this.maxJoins = 4,
    this.maxColumns = 32,
  });

  /// בודק אם טבלה מותרת
  bool isTableAllowed(String table) => tables.contains(table);

  /// בודק אם pageה מותרת בטבלה
  bool isColumnAllowed(String table, String column) =>
      columnsByTable[table]?.contains(column) ?? false;

  /// בודק אם join מותר בין שתי pageות
  bool isJoinAllowed(String t1, String c1, String t2, String c2) =>
      allowedJoins.any((rule) => rule.matches(t1, c1, t2, c2));
}

/// description מקור נתונים SQLite שתוספים יכולים לגשת אליו
class PluginDatabaseSource {
  /// מזהה יoverrideי
  final String sourceId;

  /// name תצוגה
  final String label;

  /// path מוחלט לfile ה-DB
  final String databasePath;

  /// פתיחה במצב קריאה בלבד (מומלץ תמיד true)
  final bool readOnly;

  /// מדיניות הרשאות
  final PluginDatabasePolicy policy;

  const PluginDatabaseSource({
    required this.sourceId,
    required this.label,
    required this.databasePath,
    this.readOnly = true,
    required this.policy,
  });
}
