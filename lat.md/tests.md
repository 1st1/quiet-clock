# Validation

Automated checks cover time calculations, placement, persistence, URLs, icons, and packaging. Desktop checks cover window layering, clicks, transparency, and updates.

## Time formatting and scheduling

Tests verify locale-aware hours/minutes, midnight rollover, and future minute boundaries, including an exact boundary and fractional seconds.

[ClockTimeTests.swift](../Tests/ClockTimeTests.swift) runs through [test.sh](../scripts/test.sh). Runtime checks must also cover sleep/wake and changes to system time, locale, or time zone.

## Native build

The build compiles one application, applies sandbox entitlements, verifies signing, and checks that no extension or WidgetKit dependency remains.

[check_bundle.py](../Tests/check_bundle.py) verifies agent mode, resources, and URL scheme registration during [build.sh](../scripts/build.sh). Compilation alone does not verify visual behavior.

## Appearance persistence

Tests cover persisted typography/layout/links, legacy defaults, numeric bounds, corrupt files, invalid-write preservation, and Reset.

[AppearanceTests.swift](../Tests/AppearanceTests.swift) uses isolated storage. [AppearanceSandboxProbe.swift](../Tests/AppearanceSandboxProbe.swift) verifies signed app access to a disposable settings file through [test-sandbox.sh](../scripts/test-sandbox.sh).

## Appearance interaction

Manual checks verify immediate updates, automatic saving, Reset, font fallback, line height, signed padding, and reopening settings with the saved values.

Verify there are no previews, Apply buttons, or background controls. Close settings immediately after a slider change, reopen, and verify persistence. Existing appearance files must retain settings and ignore obsolete background keys.

## Desktop integration

Placement tests cover monitor-group persistence, order-independent identity, display rearrangement, disconnected-display recovery, oversized frames, and malformed sizes. Manual checks cover transparency and desktop interaction.

[DesktopGeometryTests.swift](../Tests/DesktopGeometryTests.swift) runs through [test.sh](../scripts/test.sh). Verify moving, locking, resizing, position restoration after relaunch, and display changes. Save distinct placements with and without an external monitor, reconnect each group, and verify its previous position and size return. Change the primary display or arrangement and check that placement follows the same monitor. During connection changes, automatic OS window movement must not overwrite either group. Automated tests exercise independent profiles, reloading preferences, changed origins, same-count different-monitor groups, and resolution clamping. Normal app windows should cover the clock; desktop Spaces should show it. Only move mode should show an outline. Observe several minute boundaries for unwanted borders or animations. Check that closing settings keeps the clock running and Quit removes it.

## Shortcut links

Tests cover website normalization, unsafe schemes, credentials, stable routing, duplicate IDs, draft persistence, and the six-link limit.

[ShortcutTests.swift](../Tests/ShortcutTests.swift) runs through [test.sh](../scripts/test.sh). Manually check icon/text/both modes, all alignments, long wrapping labels, one link per row, divider visibility, and browser handoff. Move mode intentionally disables links until locked.

## Bundled service icons

Bundle validation checks all 3,291 pinned icons, catalog names, required service logos, license, and shortcut URL scheme registration.

[check_bundle.py](../Tests/check_bundle.py) runs during builds. Manually search for Linear, GitHub, and X in the picker and verify rendered icons follow text color.

## Settings launch behavior

Desktop checks verify that time clicks and the menu-bar Settings command open the editor, including after closing it and after minute changes.

Check cold app launch, URL settings launch, and an already-running app. Shortcut and idle URLs must not create a settings window. No gear or Dock icon should appear. Empty clock space does not open settings. The clock panel must not steal keyboard focus from other apps.
