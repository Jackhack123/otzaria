@echo off
REM Otzaria Windows Build and Installer Script
REM Run this on a Windows PC with Flutter installed

echo.
echo ================================================================================
echo                   OTZARIA WINDOWS BUILD AND INSTALLER
echo ================================================================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo [1/5] Checking Flutter installation...
flutter --version
flutter doctor -v

echo.
echo [2/5] Cleaning previous builds...
call flutter clean
if errorlevel 1 (
    echo ERROR: Failed to clean
    pause
    exit /b 1
)

echo.
echo [3/5] Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo [4/5] Building Windows Release (this may take 5-10 minutes)...
call flutter build windows --release
if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo [5/5] Creating installer with Inno Setup...

REM Check if Inno Setup is installed
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo Inno Setup found. Creating installer...
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\otzaria_full.iss
    if errorlevel 1 (
        echo WARNING: Installer creation had issues
    ) else (
        echo.
        echo ================================================================================
        echo SUCCESS! Your installer is ready:
        echo Output\otzaria_setup.exe
        echo ================================================================================
    )
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    echo Inno Setup found. Creating installer...
    "C:\Program Files\Inno Setup 6\ISCC.exe" installer\otzaria_full.iss
    if errorlevel 1 (
        echo WARNING: Installer creation had issues
    ) else (
        echo.
        echo ================================================================================
        echo SUCCESS! Your installer is ready:
        echo Output\otzaria_setup.exe
        echo ================================================================================
    )
) else (
    echo.
    echo WARNING: Inno Setup not found. Skipping installer creation.
    echo You can still use the built files directly from:
    echo   build\windows\runner\Release\otzaria.exe
    echo.
    echo To create an installer, install Inno Setup from:
    echo   https://jrsoftware.org/isdl.php
    echo Then run:
    echo   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\otzaria_full.iss
)

echo.
echo ================================================================================
echo BUILD COMPLETE
echo ================================================================================
echo.
echo Your application is ready in:
echo   - Direct EXE: build\windows\runner\Release\otzaria.exe
echo   - Installer: Output\otzaria_setup.exe (if created)
echo.
pause
