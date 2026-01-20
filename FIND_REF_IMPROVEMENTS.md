# עדכון איתור מקורות - סיכום שינויים

## קבצים שונו/נוצרו

### 1. **[lib/find_ref/find_ref_repository.dart](lib/find_ref/find_ref_repository.dart)** ✅
**שינוי:** שדרוג חיפוש

**מה שנוסף:**
- `_fuzzySearchRefs()` - חיפוש מטושטש באמצעות מילים משמעותיות
- `_mergeFuzzyResults()` - מיזוג תוצאות מדויקות עם מטושטשות בדרגה נכונה
- `_makeRefKey()` - פונקציה עזר ליצירת מפתחות ייחודיים
- עיבוד חכם: עדיפות לתוצאות מדויקות, fallback לחיפוש משוער

**דוגמה:**
```dart
// קלידו: "שוע"
// תוצאה: "שולחן ערוך" (הם לא מדויקים, אבל fuzzy matching יימצא)
```

---

### 2. **[lib/find_ref/section_navigator.dart](lib/find_ref/section_navigator.dart)** ✨ חדש
**סוג:** קובץ חדש לחלוטין

**עיקרי:**
- `BookSection` - מחלקה המייצגת סעיף בספר (סימן, סעיף, וכו')
- `SectionNavigator` - מתן API מתקדם לניווט בסעיפים
  - `findSection()` - חיפוש סעיף בחיפוש דקיק או משוער
  - `findSectionsByLevel()` - חיפוש כל הסעיפים בשכבה מסוימת
  - `findChildSections()` - קבלת כל ילדי סעיף
  - `findSiblingSections()` - קבלת כל האחים של סעיף
  - `convertTocToSections()` - המרה מ-TocEntry ל-BookSection

**תיקיות משנה:**
- `_isFuzzyMatch()` - בדיקת התאמה משוערת
- `_getAbbreviation()` - חילוץ ראשי תיבות
- `_wordSimilarity()` - חישוב דמיון מילים
- `_levenshteinDistance()` - מרחק עריכה לחישוב דמיון

**דוגמה:**
```dart
final section = SectionNavigator.findSection(toc, "סימן א", fuzzyMatch: true);
final children = SectionNavigator.findChildSections(section);
print(section.fullPath); // "אורח חיים, סימן א"
```

---

### 3. **[lib/find_ref/find_ref_dialog.dart](lib/find_ref/find_ref_dialog.dart)** ✏️
**שינוי:** UI שיפורים

**מה שנוסף:**
- `helperText` - טעון עזר המסביר חיפוש משוער
- דוגמאות מעודכנות בהערות

**שינויים:**
```
לפני:
"הקלד מקור מדוייק, לדוגמה: בראשית פרק א או שוע אוח יב"

אחרי:
"הקלד מקור: בראשית א:א, שוע (שולחן ערוך), משנה ברורה"
+ עם helperText על חיפוש משוער
```

---

## יכולות חדשות

### 1️⃣ חיפוש משוער (Fuzzy Search)
```
"שוע"      → "שולחן ערוך"
"גמ"       → "גמרא"
"משנ בר"   → "משנה ברורה"
"פרק א"   → "בראשית פרק א"
```

### 2️⃣ ניווט בסעיפים (הסעיפים לא סימנים בלבד)
- תמיכה בהיררכיה עמוקה (סימנים, סעיפים, סעיפים-משנה, וכו')
- חיפוש בכל שכבה
- ניווט מעלה/מטה בהיררכיה

### 3️⃣ API למתפתחים
```dart
// חיפוש סעיף
SectionNavigator.findSection(toc, "סימן א", fuzzyMatch: true);

// חיפוש רמה מסוימת
SectionNavigator.findSectionsByLevel(toc, 2); // רמה 2 = סעיפים

// ניווט בהיררכיה
SectionNavigator.findChildSections(section);
SectionNavigator.findParentSection(section);
SectionNavigator.findSiblingSections(section);
```

---

## בדיקות

✅ **כל קבצים חדשים:**
- לא יש שגיאות דחיסה
- לא יש שגיאות typo

✅ **התאימות:**
- כל הקבצים תואמים את מבנה הפרויקט
- אין dependencies חדשות

---

## דוגמאות שימוש בפרויקט

### בUI - איתור מקורות
```dart
// משתמש מקליד "שוע"
// FindRefBloc יגרום ל-FindRefRepository.findRefs("שוע")
// Repository תבצע:
// 1. חיפוש מדויק
// 2. אם < 10 תוצאות, חיפוש משוער
// 3. מיזוג וח זרה
// 4. הצגה ב-UI
```

### בקוד - ניווט סעיפים
```dart
// import 'package:otzaria/find_ref/section_navigator.dart';

final toc = await book.tableOfContents;
final sections = SectionNavigator.convertTocToSections(toc);

// מציאת סעיף מסוים
final section = SectionNavigator.findSection(toc, "סימן א");
if (section != null) {
  print("נמצא: ${section.fullPath}");
  
  // מציאת סעיפים תחתיו
  final children = SectionNavigator.findChildSections(section);
  for (final child in children) {
    print("- ${child.text}");
  }
}
```

---

## הערות חשובות

1. **חיפוש משוער מופעל רק כאשר:**
   - יש פחות מ-10 תוצאות מדויקות
   - המשתמש הקליד 3+ תווים

2. **הדגשי ה-Fuzzy:**
   - חיפוש תת-מחרוזת (substring matching)
   - ראשי תיבות (abbreviations)
   - דמיון מילים (Levenshtein distance > 0.7)

3. **מה לא יוצא מהקופסה:**
   - סינון לפי סוג סעיף (יאה לעתיד)
   - יעצות (האם התכוונת ל...?) - אפשר לעתיד
   - קאש מתקדם - אפשר לעתיד

---

## קבצים תיעוד

- [find_ref_enhancements.md](find_ref_enhancements.md) - מאפיינים מתקדמים
- [find_ref_user_guide.md](find_ref_user_guide.md) - מדריך למשתמשים
