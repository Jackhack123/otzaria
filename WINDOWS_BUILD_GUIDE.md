# Otzaria Windows Build & Installer Guide

## Prerequisites

Before building, ensure you have these installed on your Windows PC:

### 1. **Flutter SDK**
- Download: https://flutter.dev/docs/get-started/install/windows
- Extract to: `C:\flutter` (or your preferred location)
- Add to PATH

Verify installation:
```bash
flutter --version
flutter doctor
```

### 2. **Visual Studio Build Tools** (or full Visual Studio)
- Download: https://visualstudio.microsoft.com/downloads/
- Select "Desktop development with C++" workload
- Or install full Visual Studio Community (free)

### 3. **Inno Setup** (for installer creation - optional)
- Download: https://jrsoftware.org/isdl.php
- Install to default location: `C:\Program Files (x86)\Inno Setup 6\`
- Needed only if you want to create an installer

---

## Quick Build Steps

### Option A: Automated (Recommended)

1. **Extract the project** to your Windows PC
2. **Double-click**: `BUILD_WINDOWS_INSTALLER.bat`
3. **Wait** 5-10 minutes for build to complete
4. **Get your files**:
   - Direct EXE: `build\windows\runner\Release\otzaria.exe`
   - Installer: `Output\otzaria_setup.exe`

### Option B: Manual Build

```bash
# Open Command Prompt or PowerShell in the project folder

# Step 1: Clean previous builds
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Build Release version
flutter build windows --release

# Step 4: Create installer (if Inno Setup installed)
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\otzaria_full.iss
```

---

## Output Files

After building, you'll have:

### Direct Executable
```
build/windows/runner/Release/otzaria.exe
```
- Ready to run immediately
- Requires all DLL files present
- No installation needed

### Installer (if created)
```
Output/otzaria_setup.exe
```
- User-friendly installation wizard
- Handles all dependencies
- Creates Start Menu shortcuts
- Recommended for distribution

---

## Distribute to Other PCs

### With Installer (Recommended)
1. Copy `Output\otzaria_setup.exe` to USB/network
2. On target PC, double-click `otzaria_setup.exe`
3. Follow installation wizard
4. Application is installed and ready

### Without Installer
1. Copy entire `build\windows\runner\Release\` folder to USB
2. On target PC, double-click `otzaria.exe`
3. Application runs immediately (no installation)

---

## Troubleshooting

### Build fails: "Flutter SDK not found"
- Install Flutter from https://flutter.dev/docs/get-started/install/windows
- Add Flutter to PATH: `setx PATH "%PATH%;C:\flutter\bin"`
- Restart Command Prompt

### Build fails: "Visual Studio not found"
- Install Visual Studio Build Tools
- Select "Desktop development with C++"
- Download: https://visualstudio.microsoft.com/downloads/

### Installer creation fails
- Install Inno Setup from https://jrsoftware.org/isdl.php
- Ensure it's installed to: `C:\Program Files (x86)\Inno Setup 6\`
- Run the batch file again

### Application won't start
- Ensure all DLL files are present in the Release folder
- Check Windows compatibility (Windows 10 or later)
- Try running in compatibility mode if needed

---

## File Structure After Build

```
project/
├── build/
│   └── windows/
│       └── runner/
│           └── Release/
│               ├── otzaria.exe           ← Main executable
│               ├── flutter_windows.dll
│               ├── flutter_engine.dll
│               ├── data/
│               │   ├── flutter_assets/
│               │   └── icudtl.dat
│               └── (other DLLs)
│
└── Output/
    └── otzaria_setup.exe               ← Installer
```

---

## System Requirements (Target PC)

- **OS**: Windows 10 or later (64-bit)
- **RAM**: 2GB minimum
- **.NET Framework**: Usually pre-installed
- **Internet**: Not required (fully offline)

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter documentation: https://flutter.dev/docs
3. Check Inno Setup docs: https://jrsoftware.org/isinfo.php

---

## Summary

**Total time to build**: 5-10 minutes
**Output**: Ready-to-run Windows application
**Distribution**: Single EXE or professional installer

Good luck with your build! 🚀
