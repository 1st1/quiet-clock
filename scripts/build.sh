#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

SDK="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"
APP="$PWD/build/Quiet Clock.app"
EXT="$APP/Contents/PlugIns/QuietClockWidget.appex"
mkdir -p "$APP/Contents/MacOS" "$EXT/Contents/MacOS" "$PWD/build/module-cache"

python3 - "$APP" "$EXT" <<'PY'
import pathlib, plistlib, sys
for path, executable, identifier, package in [
    (sys.argv[1], 'QuietClock', 'local.quietclock.app', 'APPL'),
    (sys.argv[2], 'QuietClockWidget', 'local.quietclock.app.widget', 'XPC!'),
]:
    info = dict(CFBundleExecutable=executable, CFBundleIdentifier=identifier,
                CFBundleName='Quiet Clock', CFBundleDisplayName='Quiet Clock',
                CFBundlePackageType=package, CFBundleVersion='18',
                CFBundleShortVersionString='1.1', LSMinimumSystemVersion='14.0',
                CFBundleDevelopmentRegion='en', NSHumanReadableCopyright='')
    if package == 'XPC!':
        info['NSExtension'] = {'NSExtensionPointIdentifier': 'com.apple.widgetkit-extension'}
    else:
        info['NSPrincipalClass'] = 'NSApplication'
        info['CFBundleURLTypes'] = [dict(CFBundleURLName='local.quietclock.shortcuts', CFBundleURLSchemes=['quietclock'])]
    with open(pathlib.Path(path) / 'Contents/Info.plist', 'wb') as f:
        plistlib.dump(info, f)
PY

COMMON=(-sdk "$SDK" -target "$ARCH-apple-macosx14.0" -O -parse-as-library
        -module-cache-path "$PWD/build/module-cache")
xcrun clang -isysroot "$SDK" -target "$ARCH-apple-macosx14.0" -fobjc-arc -fblocks -O2 \
    -c Sources/ClockWidget/PrivateBackground.m -o build/PrivateBackground.o
# macOS must enter the extension service bootstrap, which invokes Swift's main.
# Entering Swift's main directly registers the widget and immediately exits.
xcrun swiftc "${COMMON[@]}" -application-extension \
    -Xlinker -e -Xlinker _NSExtensionMain \
    Sources/Shared/*.swift Sources/ClockWidget/*.swift build/PrivateBackground.o \
    -o "$EXT/Contents/MacOS/QuietClockWidget"
xcrun swiftc "${COMMON[@]}" Sources/Shared/*.swift Sources/ClockApp/*.swift \
    -o "$APP/Contents/MacOS/QuietClock"

for BUNDLE in "$APP" "$EXT"; do
    mkdir -p "$BUNDLE/Contents/Resources/ServiceIcons"
    cp Resources/ServiceIcons/* "$BUNDLE/Contents/Resources/ServiceIcons/"
done

# Ad-hoc signing is for a local build. Distribution requires an Apple signing identity.
codesign --force --sign "${CODE_SIGN_IDENTITY:--}" --entitlements Sources/Widget.entitlements "$EXT"
codesign --force --sign "${CODE_SIGN_IDENTITY:--}" --entitlements Sources/App.entitlements "$APP"
codesign --verify --deep --strict "$APP"
python3 Tests/check_bundle.py "$APP"
printf 'Built %s\n' "$APP"
