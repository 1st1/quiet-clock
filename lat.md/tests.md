# Validation

Automated checks cover time calculations, placement, persistence, URLs, icons, and packaging. Desktop checks cover window layering, clicks, transparency, and updates.

## Time formatting and scheduling

Tests verify locale-aware hours/minutes, midnight rollover, and future minute boundaries, including an exact boundary and fractional seconds.

[[Tests/ClockTimeTests.swift#ClockTimeTests#main|ClockTimeTests]] runs through [test.sh](../scripts/test.sh). Runtime checks must also cover sleep/wake and changes to system time, locale, or time zone.

## Native build

The build compiles one application, applies sandbox entitlements, verifies signing, and checks that no extension or WidgetKit dependency remains.

[check_bundle.py](../Tests/check_bundle.py) verifies agent mode, resources, and URL scheme registration during [build.sh](../scripts/build.sh). Compilation alone does not verify visual behavior.

## Appearance persistence

Tests cover persisted typography/layout/links, legacy defaults, divider visibility, numeric bounds, corrupt files, invalid-write preservation, and Reset.

[[Tests/AppearanceTests.swift#AppearanceTests#main|AppearanceTests]] uses isolated storage. [[Tests/AppearanceSandboxProbe.swift#AppearanceSandboxProbe#main|AppearanceSandboxProbe]] verifies signed app access to a disposable settings file through [test-sandbox.sh](../scripts/test-sandbox.sh).

## Appearance interaction

Manual checks verify immediate updates, automatic saving, Reset, font fallback, line height, signed padding, and reopening settings with the saved values.

Verify there are no previews, Apply buttons, or background controls. All settings sliders should have one track without a row of ticks underneath; dragging and accessibility adjustments must retain the configured increments and bounds. Toggle Show divider off and on: the line and its padding disappear and return without losing divider length/brightness/padding settings. Close settings immediately after a slider change, reopen, and verify persistence. Existing appearance files must retain settings and ignore obsolete background keys.

## Desktop integration

Placement tests cover monitor-group persistence, order-independent identity, display rearrangement, disconnected-display recovery, oversized frames, and malformed sizes. Manual checks cover transparency and desktop interaction.

[[Tests/DesktopGeometryTests.swift#DesktopGeometryTests#main|DesktopGeometryTests]] runs through [test.sh](../scripts/test.sh). Verify moving, locking, resizing, position restoration after relaunch, and display changes. Save distinct placements with and without an external monitor, reconnect each group, and verify its previous position and width return while height follows current content. Change the primary display or arrangement and check that placement follows the same monitor. During connection changes, automatic OS window movement must not overwrite either group. Automated tests exercise independent profiles, reloading preferences, changed origins, same-count different-monitor groups, and resolution clamping. Normal app windows should cover the clock; desktop Spaces should show it. Only move mode should show an outline. Observe several minute boundaries for unwanted borders or animations. Check that closing settings keeps the clock running and Quit removes it.

## Shortcut links

Tests cover website normalization, unsafe schemes, credentials, stable routing, duplicate IDs, draft persistence, and the six-link limit.

[[Tests/ShortcutTests.swift#ShortcutTests#main|ShortcutTests]] runs through [test.sh](../scripts/test.sh). Manually check icon/text/both modes, all alignments, long wrapping labels, one link per row, divider visibility, and browser handoff. Move mode intentionally disables links until locked. With another app active, verify hovering links preserves keyboard focus and clicking still opens the browser. A hand cursor is not expected on the nonactivating desktop panel.

## Bundled service icons

Bundle validation checks all 3,291 pinned icons, catalog names, required service logos, license, and shortcut URL scheme registration.

[check_bundle.py](../Tests/check_bundle.py) runs during builds. Manually search for Linear, GitHub, and X in the picker and verify rendered icons follow text color.

## Settings launch behavior

Desktop checks verify the right-click menu’s Move/Lock, Settings, and Quit actions, including after closing settings and after minute changes.

Check cold app launch, URL settings launch, and an already-running app. Shortcut and idle URLs must not create a settings window. No gear, menu-bar icon, or Dock icon should appear. Left-clicking the time must do nothing. Right-click and Control-click on the time, empty space, shortcuts, and move surface must open the same menu. Menu actions must remain usable while the clock is not focused. Empty clock space does not open settings. The clock panel must not steal keyboard focus from other apps.

## Content-driven layout

Native SwiftUI measurements verify that line height adds space, larger fonts increase natural height, links wrap at fixed size, and hiding the divider removes its line and padding.

[[Tests/ClockLayoutTests.swift#ClockLayoutTests#main|ClockLayoutTests]] uses AppKit hosting views through [test.sh](../scripts/test.sh). Manually change clock font size, line height, link size, width, and padding: the panel should resize downward without moving its top edge or scaling labels. Check auto-height after restoring monitor profiles and after changing divider visibility.

## Desktop corner masks

Tests verify four-corner placement, negative display coordinates, radius clamping, black outer corners with transparent interiors, per-monitor persistence, and invalid-setting rejection.

[[Tests/DesktopCornersTests.swift#DesktopCornersTests#main|Corner tests]] run through [test.sh](../scripts/test.sh). Manually enable two monitors with different radii, check all four corners on each, disable one, and reconnect it to verify saved preferences. Confirm masks stay click-through and below app windows, preserve keyboard focus, follow display rearrangement and Retina scaling, and disappear when the app quits. Confirm the Clock tab preserves existing settings and its Reset does not reset corners.
