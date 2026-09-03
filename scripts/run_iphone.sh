#!/usr/bin/env bash
# Wireless iOS 26: `flutter run` hangs on Dart VM / LLDB.
# Build with Flutter, then install+launch via CoreDevice (devicectl).
set -euo pipefail
cd "$(dirname "$0")/.."

API_BASE_URL="${API_BASE_URL:-https://mysancho.com/api/v1}"
DEVICE="${DEVICE:-3334543D-7A6C-55D4-A18C-A09168CCC80A}"
BUNDLE="az.homeservice.homeServiceApp"

# Debug without a debugger crashes on ProMotion (VSyncClient nil) — use release.
flutter build ios --release \
  --dart-define="API_BASE_URL=${API_BASE_URL}" \
  --dart-define-from-file=dart_defines.json

APP="build/ios/Release-iphoneos/Runner.app"

xcrun devicectl device install app --device "$DEVICE" --timeout 180 "$APP"
xcrun devicectl device process launch --device "$DEVICE" --timeout 30 "$BUNDLE"
echo "Launched $BUNDLE (no hot reload; USB + flutter run for debug)."
