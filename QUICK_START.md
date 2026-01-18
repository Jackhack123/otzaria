# OTZARIA WINDOWS BUILD - QUICK START

## 🚀 Fastest Way to Build

### On Windows with Flutter:

**Option 1: Batch File (Double-Click)**
```
Double-click: BUILD_WINDOWS_INSTALLER.bat
Wait 5-10 minutes
Done!
```

**Option 2: PowerShell**
```powershell
Right-click BUILD_WINDOWS_INSTALLER.ps1
Select "Run with PowerShell"
Wait 5-10 minutes
Done!
```

**Option 3: Manual (Command Prompt)**
```bash
flutter clean
flutter pub get
flutter build windows --release
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\otzaria_full.iss
```

---

## ✅ Prerequisites Checklist

- [ ] Windows 10 or later (64-bit)
- [ ] Flutter SDK installed: https://flutter.dev/docs/get-started/install/windows
- [ ] Visual Studio Build Tools: https://visualstudio.microsoft.com/downloads/
- [ ] Inno Setup (optional): https://jrsoftware.org/isdl.php

**Verify Flutter:**
```bash
flutter --version
flutter doctor
```

---

## 📦 After Build Completes

Your files are here:

**Option A: Direct EXE** (Portable)
```
build/windows/runner/Release/otzaria.exe
```
- No installation needed
- Just copy and run
- Include all DLL files

**Option B: Installer** (Professional)
```
Output/otzaria_setup.exe
```
- User-friendly installation
- Handles dependencies
- Creates shortcuts
- Smaller distribution size

---

## 🎯 Deploy to Another PC

### With Installer:
1. Copy `Output\otzaria_setup.exe` to USB
2. On target PC, run `otzaria_setup.exe`
3. Done!

### With Portable EXE:
1. Copy entire `build\windows\runner\Release\` folder to USB
2. On target PC, run `otzaria.exe`
3. Done!

---

## ⏱️ Expected Timeline

| Step | Time | Notes |
|------|------|-------|
| Clean | 1-2 min | Removes old builds |
| Get deps | 1-2 min | Downloads packages |
| Build | 5-8 min | Compiles everything |
| Installer | 1-2 min | Creates setup.exe |
| **TOTAL** | **~10 min** | First build takes longer |

---

## 🔧 If Build Fails

### "Flutter not found"
```bash
# Install Flutter:
# https://flutter.dev/docs/get-started/install/windows

# Add to PATH (Windows):
setx PATH "%PATH%;C:\flutter\bin"

# Restart Command Prompt and try again
```

### "Visual Studio not found"
```
Download & Install:
https://visualstudio.microsoft.com/downloads/
Select: "Desktop development with C++"
```

### "Inno Setup not found"
```
- Build still succeeds without it
- EXE is ready in: build\windows\runner\Release\
- Install Inno Setup if you want installer:
  https://jrsoftware.org/isdl.php
```

---

## 📋 Files Created

After successful build:

```
project/
├── build/windows/runner/Release/
│   ├── otzaria.exe              ← Run this!
│   ├── flutter_windows.dll      ← Required
│   ├── flutter_engine.dll       ← Required
│   ├── data/
│   └── (other DLLs)
│
└── Output/
    └── otzaria_setup.exe        ← Or run this!
```

---

## 🎓 System Requirements (Target PC)

| Component | Requirement |
|-----------|-------------|
| OS | Windows 10+ (64-bit) |
| RAM | 2GB minimum |
| Disk Space | ~500MB |
| .NET Framework | Usually pre-installed |
| Internet | NOT required |

---

## ✨ What's Next?

1. **Built successfully?** 
   - Test on your Windows PC
   - Copy to USB
   - Test on target PC

2. **Ready to distribute?**
   - Use the installer for easier distribution
   - Or just copy the Release folder
   - Run on any Windows 10+ PC

3. **Need to modify?**
   - Edit Dart code in `/lib` folder
   - Run build again
   - Same quick process

---

## 📞 Still Need Help?

1. Check WINDOWS_BUILD_GUIDE.md for detailed instructions
2. Verify all prerequisites are installed
3. Review error messages carefully
4. Check Flutter documentation: https://flutter.dev/docs

Good luck! 🚀
