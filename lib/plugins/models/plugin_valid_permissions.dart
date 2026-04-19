/// מיפוי מnames שיטות API לnames ההרשאות הנדרשות - לשימוש בהודעות error מועילות
const Map<String, String> apiCallToPermissionHint = {
  // database.*
  'database.listSources': 'database.read',
  'database.describeSource': 'database.read',
  'database.query': 'database.read',
  'database.batchQuery': 'database.read',

  // app.*
  'app.getUserEmail': 'app.user_email.read',
  'app.getInfo': 'app.info.read',
  'app.getTheme': 'app.info.read',
  'app.getLocale': 'app.info.read',
  'app.getGrantedPermissions': 'app.info.read',

  // feedback.*
  'feedback.sendEmail': 'feedback.send_email',

  // history.*
  'history.list': 'history.read',
  'history.listSearches': 'history.read',
  'history.clear': 'history.write',
  'history.remove': 'history.write',

  // notifications.*
  'notifications.showInApp': 'notifications.send',
  'notifications.sendSystem': 'notifications.system',
  'notifications.scheduleSystem': 'notifications.system',
  'notifications.cancel': 'notifications.system',
  'notifications.cancelAll': 'notifications.system',
  'notifications.checkPermissions': 'notifications.system',
  'notifications.requestPermissions': 'notifications.system',

  // reader.* (new APIs)
  'reader.addContextMenuItem': 'reader.context_menu',
  'reader.removeContextMenuItem': 'reader.context_menu',
  'reader.setHighlight': 'reader.highlight',
  'reader.getHighlights': 'reader.highlight',
  'reader.clearHighlight': 'reader.highlight',
  'reader.clearAllHighlights': 'reader.highlight',
};

/// רשימת כל ההרשאות התקפות שתוסף יכול לבקש
///
/// הרשאות אלו מאפשרות לתוספים לגשת לפונקציונליות שונות של Otzaria.
/// כל הרשאה חייבת להיות מוגדרת ב-manifest.json של התוסף.
const pluginValidPermissions = <String>[
  // ===== מידע על האפליקציה =====
  /// גישה למידע general על האפליקציה (גרסה, פלטפורמה, ערכת נושא)
  'app.info.read',

  /// גישה למייל הuser (לדיווח errors)
  'app.user_email.read',

  // ===== library =====
  /// search וקריאת רשימת books
  'library.books.read',

  /// קריאת content books
  'library.content.read',

  // ===== search =====
  /// ביצוע search text full
  'search.fulltext.read',

  // ===== קורא =====
  /// פתיחת books במצב קריאה
  'reader.open',

  /// הוספת פריטים לתפריט ההקשר של הקורא
  'reader.context_menu',

  /// add וניהול של הדגשות צבעוניות בtext
  'reader.highlight',

  // ===== ניווט =====
  /// מעבר בין מסכים באפליקציה
  'navigation.write',

  // ===== notes אישיות =====
  /// קריאת notes אישיות
  'notes.read',

  /// כתיבה ועריכת notes אישיות
  'notes.write',

  // ===== לוח year =====
  /// גישה ללוח הyear העברי, זמנים הלכתיים ואירועים
  'calendar.read',

  // ===== settings =====
  /// קריאת settings האפליקציה (רק מlist מאושרת)
  'settings.read',

  // ===== interface user =====
  /// הצגת הודעות ודיאלוגים לuser
  'ui.feedback',

  // ===== אחסון תוסף =====
  /// קריאה מאחסון key-value של התוסף
  'plugin.storage.read',

  /// כתיבה noחסון key-value של התוסף
  'plugin.storage.write',

  // ===== פרסום נתונים =====
  /// פרסום נתונים מהתוסף noפליקציה (למשל אירועי לוח year)
  'published_data.write',

  // ===== רשת =====
  /// גישה noינטרנט (לתוספים שצריכים לטעון משאבים חיצוניים)
  'network.access',

  // ===== משוב ומיילים =====
  /// שליחת משוב/דיווחים למייל מותאם אישית
  'feedback.send_email',

  // ===== היסטוריית קריאה =====
  /// קריאת היסטוריית קריאה וsearchים
  'history.read',

  /// delete ועריכת היסטוריית קריאה
  'history.write',

  // ===== מסד נתונים =====
  /// קריאת נתונים ממקורות SQLite שהאפליקציה מאשרת לתוסף
  'database.read',

  // ===== התראות =====
  /// הצגת התראות בתוך האפליקציה (UiSnack)
  'notifications.send',

  /// שליחת התראות לSystem הEnableה
  'notifications.system',

  // ===== אירועים (Events) =====
  /// הרשמה noירועי שינוי ניווט
  'events.subscribe:navigation.changed',

  /// הרשמה noירועי שינוי book current
  'events.subscribe:reader.current_book_changed',

  /// הרשמה noירועי שינוי location בקורא
  'events.subscribe:reader.current_ref_changed',

  /// הרשמה noירועי שינוי ערכת נושא
  'events.subscribe:theme.changed',

  /// הרשמה noירועי שינוי settings
  'events.subscribe:settings.changed',

  /// הרשמה noירועי שינוי date בלוח הyear
  'events.subscribe:calendar.date_changed',

  /// הרשמה noירועי שינוי סביבת עבודה
  'events.subscribe:workspace.changed',

  /// הרשמה noירועי שינוי הרשאות התוסף
  'events.subscribe:plugin.permissions_changed',

  /// הרשמה noירועי סימון text בקורא
  'events.subscribe:reader.selection_changed',
];
