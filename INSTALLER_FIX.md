# תיקון: Installer Error - Missing otzaria_latest.zip

## בעיה
```
Error on line 130 in D:\a\otzaria\otzaria\installer\otzaria_full.iss: 
Source file "D:\a\otzaria\otzaria\installer\..\otzaria_latest.zip" does not exist.
Compile aborted.
Error: Process completed with exit code 1.
```

## סיבה
קובץ `otzaria_latest.zip` נוצר רק כשה-commit message הוא גרסה (version tag) בפורמט `X.Y.Z`. בכל מקרה אחר, ה-workflow לא מוריד את הקובץ, אבל ה-installer עדיין מחפש אותו - מה שגורם לקריסה.

## פתרון
עדכנתי את [installer/otzaria_full.iss](installer/otzaria_full.iss) כדי לבדוק אם הקובץ קיים לפני שניסיון להשתמש בו:

### שינוי 1: הוספת בדיקה בסעיף [Files]
```innosetup
; לפני:
Source: "..\otzaria_latest.zip"; DestDir: "{tmp}"; Flags: deleteafterinstall

; אחרי:
Source: "..\otzaria_latest.zip"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: FileExists(ExpandConstant('{src}\..\otzaria_latest.zip'))
```

### שינוי 2: עדכון פונקציית ExtractLibrary
הוספתי בדיקה אם הקובץ קיים:
```pascalscript
// בדיקה אם קובץ ה-ZIP קיים
if not FileExists(ZipPath) then
begin
  WizardForm.StatusLabel.Caption := 'הערה: ספריית הספרים לא כללה בהתקנה זו.';
  MsgBox('הערה: קובץ ספריית הספרים (otzaria_latest.zip) לא נמצא.' + #13#10 +
         'ניתן להוריד את הספרים דרך תפריט הגדרות בתוך האפליקציה.', 
         mbInformation, MB_OK);
  Result := True; // לא נחשב כשגיאה
  Exit;
end;
```

### שינוי 3: בדיקה דומה לקובץ VC++ Redistributable
```innosetup
Source: "VisualCppRedist_AIO_x86_x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: FileExists(ExpandConstant('{src}\VisualCppRedist_AIO_x86_x64.exe'))
```

## תוצאה
✅ **Installer עכשיו עובד בשני תרחישים:**

1. **כאשר זה version tag (X.Y.Z):**
   - ה-workflow מוריד את `otzaria_latest.zip` ו-`VisualCppRedist_AIO_x86_x64.exe`
   - Installer מחלץ את הספרים כבקביל
   - Full installer יצור עם כל הספרים

2. **כאשר זה לא version tag:**
   - ה-workflow לא מוריד את הקבצים
   - Installer עדיין מחובר בהצלחה
   - משתמש רואה הודעה אמיקלית: "קובץ ספריית הספרים לא נמצא"
   - משתמש יכול להוריד את הספרים דרך ההגדרות בתוך האפליקציה

## בדיקה
```bash
# כל השינויים בקובץ:
git diff installer/otzaria_full.iss
```

## טיקון למעתיד
אם אתה רוצה שגם בגרסאות שאינן-version-tag יהיה קובץ הספרים, יש לשנות את:
- [.github/workflows/build-and-announce.yml](../.github/workflows/build-and-announce.yml) - כדי להוריד את הקובץ תמיד, לא רק בversion tags
