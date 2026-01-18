# Otzaria Windows Build and Installer Script (PowerShell)
# Run this on a Windows PC with Flutter installed
# Right-click and select "Run with PowerShell"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                   OTZARIA WINDOWS BUILD AND INSTALLER" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[1/5] Checking Flutter installation..." -ForegroundColor Green
flutter --version
Write-Host ""

Write-Host "[2/5] Cleaning previous builds..." -ForegroundColor Green
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to clean" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Clean complete" -ForegroundColor Green
Write-Host ""

Write-Host "[3/5] Getting dependencies..." -ForegroundColor Green
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Dependencies downloaded" -ForegroundColor Green
Write-Host ""

Write-Host "[4/5] Building Windows Release (this may take 5-10 minutes)..." -ForegroundColor Green
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Build complete!" -ForegroundColor Green
Write-Host ""

Write-Host "[5/5] Creating installer with Inno Setup..." -ForegroundColor Green
Write-Host ""

# Check if Inno Setup is installed
$innoSetupPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup\ISCC.exe",
    "C:\Program Files\Inno Setup\ISCC.exe"
)

$innoSetupFound = $false
foreach ($path in $innoSetupPaths) {
    if (Test-Path $path) {
        Write-Host "Inno Setup found at: $path" -ForegroundColor Green
        Write-Host "Creating installer..." -ForegroundColor Green
        & $path "installer\otzaria_full.iss"
        if ($LASTEXITCODE -eq 0) {
            $innoSetupFound = $true
            break
        }
    }
}

if ($innoSetupFound) {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host "SUCCESS! Your installer is ready:" -ForegroundColor Green
    Write-Host "Output\otzaria_setup.exe" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "WARNING: Inno Setup not found. Skipping installer creation." -ForegroundColor Yellow
    Write-Host "You can still use the built files directly from:" -ForegroundColor Yellow
    Write-Host "  build\windows\runner\Release\otzaria.exe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To create an installer, install Inno Setup from:" -ForegroundColor Yellow
    Write-Host "  https://jrsoftware.org/isdl.php" -ForegroundColor Cyan
    Write-Host "Then run:" -ForegroundColor Yellow
    Write-Host '  & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\otzaria_full.iss' -ForegroundColor Cyan
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "BUILD COMPLETE" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your application is ready in:" -ForegroundColor Yellow
Write-Host "  - Direct EXE: build\windows\runner\Release\otzaria.exe" -ForegroundColor Cyan
Write-Host "  - Installer: Output\otzaria_setup.exe (if created)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  1. Copy the files to your target Windows PC" -ForegroundColor White
Write-Host "  2. Double-click otzaria.exe or run the installer" -ForegroundColor White
Write-Host "  3. Application will start immediately" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
