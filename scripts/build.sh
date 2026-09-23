#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

SDK="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"
APP="$PWD/build/Quiet Clock.app"
mkdir -p "$APP/Contents/MacOS" "$PWD/build/module-cache"
# Remove the obsolete extension when upgrading an existing build directory.
rm -rf "$APP/Contents/PlugIns"
python3 - "$APP" <<'PLIST'
import pathlib, plistlib, sys
info = dict(CFBundleExecutable='QuietClock', CFBundleIdentifier='local.quietclock.app',
            CFBundleName='Quiet Clock', CFBundleDisplayName='Quiet Clock',
            CFBundlePackageType='APPL', CFBundleVersion='26',
            CFBundleShortVersionString='2.0', LSMinimumSystemVersion='14.0',
            CFBundleDevelopmentRegion='en', NSPrincipalClass='NSApplication', LSUIElement=True,
            CFBundleURLTypes=[dict(CFBundleURLName='local.quietclock.shortcuts', CFBundleURLSchemes=['quietclock'])])
with open(pathlib.Path(sys.argv[1]) / 'Contents/Info.plist', 'wb') as f:
    plistlib.dump(info, f)
PLIST

COMMON=(-sdk "$SDK" -target "$ARCH-apple-macosx14.0" -O -parse-as-library
        -module-cache-path "$PWD/build/module-cache")
xcrun swiftc "${COMMON[@]}" Sources/Shared/*.swift Sources/ClockApp/*.swift \
    -o "$APP/Contents/MacOS/QuietClock"

for BUNDLE in "$APP"; do
    mkdir -p "$BUNDLE/Contents/Resources/ServiceIcons"
    cp Resources/ServiceIcons/* "$BUNDLE/Contents/Resources/ServiceIcons/"
done

# Ad-hoc signing is for a local build. Distribution requires an Apple signing identity.
codesign --force --sign "${CODE_SIGN_IDENTITY:--}" --entitlements Sources/App.entitlements "$APP"
codesign --verify --deep --strict "$APP"
python3 Tests/check_bundle.py "$APP"
printf 'Built %s\n' "$APP"
