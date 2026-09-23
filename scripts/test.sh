#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/module-cache" \
    Sources/Shared/ClockTime.swift Tests/ClockTimeTests.swift -o build/ClockTimeTests
build/ClockTimeTests
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/module-cache" \
    Sources/Shared/ClockShortcut.swift Sources/Shared/ClockAppearance.swift Tests/AppearanceTests.swift -o build/AppearanceTests
build/AppearanceTests
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/module-cache" \
    Sources/Shared/ClockShortcut.swift Sources/Shared/ClockAppearance.swift Tests/ShortcutTests.swift -o build/ShortcutTests
build/ShortcutTests
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/module-cache" \
    Sources/Shared/DesktopGeometry.swift Sources/Shared/DesktopPlacement.swift Tests/DesktopGeometryTests.swift -o build/DesktopGeometryTests
build/DesktopGeometryTests
