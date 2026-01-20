# אתור מקורות - שיפורים מתקדמים

## סיכום השינויים

### 1. **חיפוש משוער (Fuzzy Search)**

**קובץ:** [lib/find_ref/find_ref_repository.dart](lib/find_ref/find_ref_repository.dart)

#### מה שנוסף:
- **דעיכת תוצאות** - אם יש מעט תוצאות ממדויקות, המערכת תנסה חיפוש משוער
- **התאמה חלקית** - קלידו "שוע" ותקבלו "שולחן ערוך"
- **ראשי תיבות** - קלידו "משנ ברו" ותקבלו "משנה ברורה"
- **דמיון מילים** - התאמה בקירבה כתיבה (Levenshtein distance)

#### דוגמאות:
```
קלידו              → תוצאה צפויה
"שוע"              → "שולחן ערוך"
"גמ"               → "גמרא", "גמלא"
"משנ ברור"        → "משנה ברורה"
"בראשי א"         → "בראשית פרק א"
```

---

### 2. **ניווט בסעיפים (Section Navigation)**

**קובץ חדש:** [lib/find_ref/section_navigator.dart](lib/find_ref/section_navigator.dart)

#### יכולות חדשות:
- **חיפוש לפי סעיפים** - מציאת סימנים, סעיפים וסעיפים-משנה
- **ניווט בהיררכיה** - מעבר בין הורים וילדים
- **חיפוש אחים** - מציאת סעיפים בקטגוריה זהה
- **מסלול מלא** - הצגת הנתיב המלא (אורח חיים → סימן א → סעיף א)

#### API:
```dart
// חיפוש סעיף מסוים
final section = SectionNavigator.findSection(
  toc,
  "סימן א",
  fuzzyMatch: true
);

// חיפוש כל הסימנים (level 1)
final chapters = SectionNavigator.findSectionsByLevel(toc, 1);

// חיפוש כל הסעיפים (level 2)
final sections = SectionNavigator.findSectionsByLevel(toc, 2);

// מציאת ילדים של סעיף
final children = SectionNavigator.findChildSections(parentSection);

// מציאת אחים של סעיף
final siblings = SectionNavigator.findSiblingSections(section);

// המרת TOC לBooSections
final sections = SectionNavigator.convertTocToSections(toc);
```

---

### 3. **UI שיפורים**

**קובץ:** [lib/find_ref/find_ref_dialog.dart](lib/find_ref/find_ref_dialog.dart)

#### שינויים:
- **טעון עזר (Helper Text)** - הנחיות חיפוש משוער
- **דוגמאות מעודכנות** - הוצגו במסך החיפוש

#### הודעה חדשה:
```
"תמיכה בחיפוש משוער - דוגמה: קלידו "שוע" למציאת "שולחן ערוך""
```

---

## דוגמאות שימוש

### חיפוש ספר בקיצור
```
קלידו: "שוע אוח א"
תוצאות: שולחן ערוך אורח חיים סימן א...
```

### ניווט בסימנים וסעיפים
```dart
// קבל את כל הסימנים של שולחן ערוך
final simnim = SectionNavigator.findSectionsByLevel(
  toc,
  1 // level = סימן
);

// קבל את כל הסעיפים של סימן ספציפי
final seifim = SectionNavigator.findChildSections(simnim.first);

// חזור לסימן האב של סעיף מסוים
final parent = SectionNavigator.findParentSection(seif);
```

---

## מאפיינים טכניים

### חיפוש משוער תמיד עובד כאשר:
1. יש פחות מ-10 תוצאות מדויקות
2. המשתמש הקליד 3+ תווים
3. יש מילים משמעותיות (אורך > 2)

### ניווט סעיפים תומך:
- **TocEntry** (מבנה ה-TOC הקיים)
- **היררכיה לא מוגבלת** (כמה שכבות זה שרוצים)
- **חיפוש fuzzy** בשמות סעיפים
- **דמיון מילים** בעזרת Levenshtein distance

---

## שיפורים עתידיים אפשריים

1. **קאשינג** - שמור תוצאות חיפוש משוער נפוצות
2. **יעצות** - הצג "האם התכוונת ל...?"
3. **וקטורים** - שימוש בהטמעות טקסט לדמיון טוב יותר
4. **היסטוריה** - זכור חיפושים נפוצים של המשתמש
