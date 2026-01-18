#!/bin/bash
# Otzaria Windows Build Script (Linux/macOS compatible)
# Builds a Windows executable and creates installer alternatives

set -e  # Exit on any error

echo ""
echo "================================================================================"
echo "                   OTZARIA WINDOWS BUILD (LINUX/macOS)"
echo "================================================================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "[1/6] Checking Flutter installation..."
flutter --version
echo ""

echo "[2/6] Running Flutter doctor..."
flutter doctor -v || true
echo ""

echo "[3/6] Cleaning previous builds..."
flutter clean
echo ""

echo "[4/6] Getting dependencies..."
flutter pub get
echo ""

echo "[5/6] Building Windows Release (this may take 10-15 minutes)..."
echo "Note: Cross-compiling from Linux to Windows..."
flutter build windows --release

if [ $? -ne 0 ]; then
    echo "ERROR: Build failed"
    exit 1
fi

echo ""
echo "[6/6] Creating distribution package..."

BUILD_DIR="build/windows/x64/runner/Release"
OUTPUT_DIR="build/installers"
APP_NAME="otzaria"
APP_VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}')

mkdir -p "$OUTPUT_DIR"

# Create a zip package (portable version)
echo "Creating portable zip package..."
if [ -d "$BUILD_DIR" ]; then
    cd "$BUILD_DIR"
    zip -r "../../../$OUTPUT_DIR/${APP_NAME}_windows_${APP_VERSION}_portable.zip" .
    cd ../../../
    echo "✓ Created: $OUTPUT_DIR/${APP_NAME}_windows_${APP_VERSION}_portable.zip"
else
    echo "WARNING: Build directory not found: $BUILD_DIR"
fi

# Try to create MSIX package if possible
echo ""
echo "Attempting to create MSIX package..."
if flutter pub global list | grep -q msix; then
    flutter pub global run msix:create
    echo "✓ MSIX package created (if available)"
else
    echo "INFO: MSIX package generation not available"
    echo "To create MSIX packages, run: flutter pub global activate msix"
fi

echo ""
echo "================================================================================"
echo "BUILD COMPLETE"
echo "================================================================================"
echo ""
echo "Your Windows application is ready:"
echo ""
echo "  - Direct EXE: $BUILD_DIR/${APP_NAME}.exe"
echo "  - Portable ZIP: $OUTPUT_DIR/${APP_NAME}_windows_${APP_VERSION}_portable.zip"
echo ""
echo "To create a traditional Windows installer (.exe with setup wizard):"
echo "  1. On Windows, install Inno Setup"
echo "  2. Run: iscc installer/otzaria_full.iss"
echo ""
echo "Alternatively, create an MSIX package on Windows:"
echo "  flutter pub global activate msix"
echo "  flutter pub global run msix:create"
echo ""
