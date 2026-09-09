#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/module-cache" \
    Sources/Shared/ClockTime.swift Tests/ClockTimeTests.swift -o build/ClockTimeTests
build/ClockTimeTests
xcrun swiftc -parse-as-library -module-cache-path "$PWD/build/module-cache" \
    Sources/Shared/ClockAppearance.swift Tests/AppearanceTests.swift -o build/AppearanceTests
build/AppearanceTests
