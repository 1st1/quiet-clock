#!/bin/bash
# Integration check: signed probes access only a disposable file in the settings folder.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/module-cache" \
    Sources/Shared/ClockShortcut.swift Sources/Shared/ClockAppearance.swift Tests/AppearanceSandboxProbe.swift -o build/AppearanceProbe
python3 - <<'PY'
import pathlib, plistlib, shutil
for role in ['Writer', 'Reader']:
    app = pathlib.Path('build/Appearance' + role + '.app/Contents')
    (app / 'MacOS').mkdir(parents=True, exist_ok=True)
    shutil.copy2('build/AppearanceProbe', app / 'MacOS/AppearanceProbe')
    with (app / 'Info.plist').open('wb') as f:
        plistlib.dump(dict(CFBundleIdentifier='local.quietclock.probe.'+role.lower(),
                          CFBundleExecutable='AppearanceProbe', CFBundlePackageType='APPL'), f)
PY
codesign --force --sign - --entitlements Sources/App.entitlements build/AppearanceWriter.app
codesign --force --sign - --entitlements Sources/App.entitlements build/AppearanceReader.app
PROBE_NAME="probe-$(uuidgen).json"
WRITER="$PWD/build/AppearanceWriter.app/Contents/MacOS/AppearanceProbe"
READER="$PWD/build/AppearanceReader.app/Contents/MacOS/AppearanceProbe"
"$WRITER" write "$PROBE_NAME"
trap '"$WRITER" cleanup "$PROBE_NAME"' EXIT
"$READER" read "$PROBE_NAME"
