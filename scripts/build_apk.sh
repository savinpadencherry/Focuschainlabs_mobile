#!/usr/bin/env bash
# Build a release APK (Codespace / local). Requires Flutter + Android SDK.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter pub get
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "✓ APK ready: $APK"
ls -lh "$APK"
