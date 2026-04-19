/// מידע תצוגה עבור הרשאת תוסף — name עברי וdescription short
class PluginPermissionInfo {
  /// name short בעברית (מוצג כותרת)
  final String label;

  /// description מה ההרשאה מאפשרת (מוצג כsubtitle)
  final String description;

  const PluginPermissionInfo({required this.label, required this.description});
}

/// מחזיר מידע תצוגה עבור הרשאה בשמה הטכני.
/// אם ההרשאה אינה מוכרת, מחזיר את שמה הטכני עם description גנרי.
PluginPermissionInfo getPermissionInfo(String permissionKey) {
  return _permissionLabels[permissionKey] ??
      PluginPermissionInfo(
        label: permissionKey,
        description: 'גישה לפונקציונליות: $permissionKey',
      );
}

/// מיפוי full של כל ההרשאות התקפות לname וdescription בעברית
const Map<String, PluginPermissionInfo> _permissionLabels = {
  // ===== מידע על האפליקציה =====
  'app.info.read': PluginPermissionInfo(
    label: 'מידע אפליקציה',
    description: 'קריאת מידע general על האפליקציה: גרסה, פלטפורמה, ערכת נושא',
  ),
  'app.user_email.read': PluginPermissionInfo(
    label: 'כתובת מייל',
    description: 'גישה לכתובת המייל של הuser, לשימוש בדיווח errors בלבד',
  ),

  // ===== library =====
  'library.books.read': PluginPermissionInfo(
    label: 'רשימת books',
    description: 'search וצפייה ברשימת כל הbooks בlibrary',
  ),
  'library.content.read': PluginPermissionInfo(
    label: 'content books',
    description: 'קריאת content הbooks מthe library',
  ),

  // ===== search =====
  'search.fulltext.read': PluginPermissionInfo(
    label: 'search text full',
    description: 'ביצוע searchי text ברחבי כל the library',
  ),

  // ===== קורא =====
  'reader.open': PluginPermissionInfo(
    label: 'פתיחת books',
    description: 'פתיחת books בקורא האפליקציה',
  ),

  // ===== ניווט =====
  'navigation.write': PluginPermissionInfo(
    label: 'ניווט במסכים',
    description: 'מעבר בין מסכים שונים באפליקציה',
  ),

  // ===== notes אישיות =====
  'notes.read': PluginPermissionInfo(
    label: 'צפייה בnotes',
    description: 'קריאה וצפייה בnotes האישיות שלך',
  ),
  'notes.write': PluginPermissionInfo(
    label: 'עריכת notes',
    description: 'יצירה, עריכה וdelete של notes אישיות',
  ),

  // ===== לוח year =====
  'calendar.read': PluginPermissionInfo(
    label: 'לוח year עברי',
    description: 'גישה ללוח הyear העברי, זמנים הלכתיים ואירועים',
  ),

  // ===== settings =====
  'settings.read': PluginPermissionInfo(
    label: 'settings האפליקציה',
    description: 'קריאת settings האפליקציה (רק settings שאושרו לתוספים)',
  ),

  // ===== interface user =====
  'ui.feedback': PluginPermissionInfo(
    label: 'הודעות ודיאלוגים',
    description: 'הצגת הודעות, דיאלוגים ועדכונים בinterface הuser',
  ),

  // ===== אחסון תוסף =====
  'plugin.storage.read': PluginPermissionInfo(
    label: 'אחסון מקומי — קריאה',
    description: 'קריאת נתונים שהתוסף שמר בעבר על המכשיר',
  ),
  'plugin.storage.write': PluginPermissionInfo(
    label: 'אחסון מקומי — כתיבה',
    description: 'save נתוני התוסף על המכשיר',
  ),

  // ===== פרסום נתונים =====
  'published_data.write': PluginPermissionInfo(
    label: 'שיתוף נתונים עם האפליקציה',
    description:
        'פרסום נתונים מהתוסף לחלקים אחרים באפליקציה (כגון אירועי לוח year)',
  ),

  // ===== רשת =====
  'network.access': PluginPermissionInfo(
    label: 'גישה noינטרנט',
    description: 'שליחה וקבלה של מידע מרשת האינטרנט',
  ),

  // ===== משוב ומיילים =====
  'feedback.send_email': PluginPermissionInfo(
    label: 'שליחת מייל',
    description: 'שליחת משוב ודיווחים לכתובת מייל שהתוסף מגדיר',
  ),

  // ===== היסטוריית קריאה =====
  'history.read': PluginPermissionInfo(
    label: 'היסטוריית קריאה — צפייה',
    description: 'צפייה בהיסטוריית הקריאה והsearchים שלך',
  ),
  'history.write': PluginPermissionInfo(
    label: 'היסטוריית קריאה — עריכה',
    description: 'delete ועריכה של היסטוריית הקריאה',
  ),

  // ===== מסד נתונים =====
  'database.read': PluginPermissionInfo(
    label: 'קריאת מסד נתונים',
    description: 'קריאת נתונים ממקורות SQLite שהאפליקציה מאשרת לתוסף',
  ),

  // ===== התראות =====
  'notifications.send': PluginPermissionInfo(
    label: 'הודעות מובנות',
    description: 'הצגת הודעות פופ-אפ בתוך האפליקציה',
  ),
  'notifications.system': PluginPermissionInfo(
    label: 'התראות System',
    description: 'שליחת התראות לSystem הEnableה (גם כשהאפליקציה closedה)',
  ),

  // ===== אירועים =====
  'events.subscribe:navigation.changed': PluginPermissionInfo(
    label: 'אירועי ניווט',
    description: 'קבלת update בכל פעם שuser עובר בין מסכים',
  ),
  'events.subscribe:reader.current_book_changed': PluginPermissionInfo(
    label: 'אירועי פתיחת book',
    description: 'קבלת update בכל פעם שנOpen new book בקורא',
  ),
  'events.subscribe:reader.current_ref_changed': PluginPermissionInfo(
    label: 'אירועי שינוי location',
    description: 'קבלת update בכל פעם שlocation הקריאה variable (page, פרק, סעיף)',
  ),
  'events.subscribe:theme.changed': PluginPermissionInfo(
    label: 'אירועי ערכת נושא',
    description: 'קבלת update בכל פעם שuser מחליף ערכת נושא',
  ),
  'events.subscribe:settings.changed': PluginPermissionInfo(
    label: 'אירועי settings',
    description: 'קבלת update בכל פעם שuser מyear setting',
  ),
  'events.subscribe:calendar.date_changed': PluginPermissionInfo(
    label: 'אירועי שינוי date',
    description: 'קבלת update בכל פעם שuser מחליף date בלוח הyear',
  ),
  'events.subscribe:workspace.changed': PluginPermissionInfo(
    label: 'אירועי סביבת עבודה',
    description: 'קבלת update בכל פעם שuser מחליף סביבת עבודה',
  ),
  'events.subscribe:plugin.permissions_changed': PluginPermissionInfo(
    label: 'אירועי שינוי הרשאות',
    description: 'קבלת update בכל פעם שהרשאות התוסף משתנות',
  ),
};
