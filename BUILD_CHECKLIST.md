# ✅ OTZARIA WINDOWS BUILD CHECKLIST

## BEFORE YOU START

- [ ] You have a Windows PC (Windows 10 or later, 64-bit)
- [ ] Internet connection available on the build PC
- [ ] At least 5GB free disk space

## STEP 1: INSTALL PREREQUISITES

### Install Flutter
- [ ] Download: https://flutter.dev/docs/get-started/install/windows
- [ ] Extract to: `C:\flutter` (or your preferred location)
- [ ] Add to Windows PATH
- [ ] Verify: Open Command Prompt and run `flutter --version`

### Install Visual Studio Build Tools
- [ ] Download: https://visualstudio.microsoft.com/downloads/
- [ ] Run installer
- [ ] Select "Desktop development with C++" workload
- [ ] Complete installation (~5GB)

### Install Inno Setup (Optional but Recommended)
- [ ] Download: https://jrsoftware.org/isdl.php
- [ ] Run installer
- [ ] Use default installation path: `C:\Program Files (x86)\Inno Setup 6\`

## STEP 2: PREPARE PROJECT

- [ ] Copy the Otzaria project folder to your Windows PC
- [ ] Navigate to project folder in Command Prompt/PowerShell
- [ ] Verify these files exist:
  - [ ] `pubspec.yaml`
  - [ ] `lib/main.dart`
  - [ ] `windows/CMakeLists.txt`
  - [ ] `BUILD_WINDOWS_INSTALLER.bat` (or `.ps1`)
  - [ ] `installer/otzaria_full.iss`

## STEP 3: BUILD APPLICATION

### Method A: Automated (Recommended)
- [ ] Double-click: `BUILD_WINDOWS_INSTALLER.bat`
- [ ] Wait 5-10 minutes for build to complete
- [ ] Check for success message

### Method B: PowerShell
- [ ] Right-click `BUILD_WINDOWS_INSTALLER.ps1`
- [ ] Select "Run with PowerShell"
- [ ] Allow execution if prompted
- [ ] Wait 5-10 minutes

### Method C: Manual
- [ ] Open Command Prompt in project folder
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter build windows --release`
- [ ] Wait 5-10 minutes

## STEP 4: VERIFY BUILD SUCCESS

After build completes:

- [ ] Check: `build\windows\runner\Release\otzaria.exe` exists
- [ ] Check: Multiple `.dll` files present in Release folder
- [ ] Check: `data` folder exists with assets
- [ ] (If Inno Setup installed) Check: `Output\otzaria_setup.exe` exists

## STEP 5: TEST APPLICATION

### Test Direct EXE
- [ ] Navigate to: `build\windows\runner\Release\`
- [ ] Double-click: `otzaria.exe`
- [ ] Application should launch within 2-3 seconds
- [ ] Test basic functionality (load a book, search, etc.)

### Test Installer (If Available)
- [ ] Navigate to: `Output\`
- [ ] Double-click: `otzaria_setup.exe`
- [ ] Follow installation wizard
- [ ] Launch from Start Menu
- [ ] Verify application runs correctly

## STEP 6: PREPARE FOR DISTRIBUTION

### Option A: Direct EXE (Portable)
- [ ] Copy entire `build\windows\runner\Release\` folder
- [ ] Rename to: `Otzaria_Portable`
- [ ] Compress to ZIP (optional)
- [ ] Ready to distribute!

### Option B: Installer (Recommended)
- [ ] Copy: `Output\otzaria_setup.exe`
- [ ] Rename to: `Otzaria_Setup.exe` (optional)
- [ ] Compress to ZIP (optional)
- [ ] Ready to distribute!

## STEP 7: DEPLOY TO TARGET PC

### For Installer
- [ ] Copy `otzaria_setup.exe` to USB/network
- [ ] Transfer to target Windows PC
- [ ] Double-click installer
- [ ] Follow wizard
- [ ] Application ready!

### For Portable
- [ ] Copy entire `Otzaria_Portable` folder to USB/network
- [ ] Transfer to target Windows PC
- [ ] Double-click `otzaria.exe`
- [ ] Application launches immediately!

## TROUBLESHOOTING

### Build Failed?

**Error: "Flutter not found"**
- [ ] Install Flutter SDK: https://flutter.dev/docs/get-started/install/windows
- [ ] Add to PATH: `setx PATH "%PATH%;C:\flutter\bin"`
- [ ] Restart Command Prompt
- [ ] Try build again

**Error: "Visual Studio build tools not found"**
- [ ] Install Visual Studio Build Tools
- [ ] Select "Desktop development with C++" workload
- [ ] Restart computer
- [ ] Try build again

**Error: "Inno Setup not found"**
- [ ] This is OK - build still succeeds
- [ ] EXE is still ready in `build\windows\runner\Release\`
- [ ] Install Inno Setup if you want the installer:
- [ ] https://jrsoftware.org/isdl.php

### Application Won't Start?

- [ ] Check all DLL files are present in Release folder
- [ ] Verify Windows 10 or later
- [ ] Try running as Administrator
- [ ] Restart the computer
- [ ] Check for error messages

## FINAL VERIFICATION

### Before Distribution:

- [ ] Application launches successfully
- [ ] Application responds to user input
- [ ] Settings can be changed
- [ ] Books/content can be loaded
- [ ] Search functionality works
- [ ] No error messages appear

### System Requirements Met:

- [ ] Target PC: Windows 10 or later (64-bit)
- [ ] Target PC: 2GB RAM minimum
- [ ] Target PC: 500MB free disk space
- [ ] Target PC: No internet required

## NOTES

- **First build is slow** (~10 minutes) - subsequent builds are faster
- **All files are self-contained** - no installation or dependencies needed on target PC
- **Application is offline** - works without internet connection
- **Multiple users can run** from the same folder without issues

---

## SUCCESS! 🎉

You now have:
1. ✅ Built the Windows application
2. ✅ Created an installer (if applicable)
3. ✅ Tested on local PC
4. ✅ Ready to distribute to other Windows PCs

**Next Step:** Transfer files to target PC and run!

---

**Questions?** See:
- WINDOWS_BUILD_GUIDE.md - Detailed instructions
- QUICK_START.md - Quick reference
- README.md - General project information
