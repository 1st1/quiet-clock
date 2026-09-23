# Validation

Automated checks validate time generation and native bundle compilation. Interactive desktop checks validate the host-controlled appearance and refresh behavior.

## Time formatting and scheduling

The executable test verifies locale-aware hour cycles, midnight rollover, the first upcoming minute boundary, and the spacing and coverage of future entries.

[ClockTimeTests.swift](../Tests/ClockTimeTests.swift) runs through [test.sh](../scripts/test.sh). These checks exercise time calculations independently of WidgetKit scheduling.

## Native build

The build compiles both Swift executables, embeds the extension, applies sandbox entitlements, and verifies the complete bundle signature.

[build.sh](../scripts/build.sh) performs the native build with the installed macOS SDK. This does not establish gallery registration or onscreen behavior.

[check_bundle.py](../Tests/check_bundle.py) checks the extension declaration and verifies that the Mach-O launch address resolves to the extension service bootstrap. This catches a signed, compilable binary that exits without serving gallery requests.

## Appearance persistence

Settings tests verify persistence of typography, icon layout, and divider settings, compatibility with older appearance files, rejection of invalid values and corrupt data, preservation after invalid writes, and restoration of defaults.

[AppearanceTests.swift](../Tests/AppearanceTests.swift) runs through [test.sh](../scripts/test.sh) using isolated temporary storage. [AppearanceSandboxProbe.swift](../Tests/AppearanceSandboxProbe.swift), run by [test-sandbox.sh](../scripts/test-sandbox.sh), verifies signed app-to-widget sharing and rejects writes using widget entitlements.

## Appearance interaction

Manual checks exercise font selection, size and weight extremes, spacing, text color, shortcut editing, automatic saving, Reset, and reopening the app with saved settings.

Compare all three preview sizes with the desktop widget, including system full-color and monochrome modes. Observe a minute boundary and verify the digits change without a fade or slide. Confirm that changes save without an Apply button and update the widget after adjustments stop. Close or quit immediately after a slider change, reopen, and verify the last value persisted. Rapid slider changes must coalesce refresh requests, and quitting the editor must leave the widget working. Check custom fonts with limited available weights and long localized time strings.

Verify that no background controls remain and that Reset preserves transparency. Preview backgrounds must show the sample wallpaper directly. Existing appearance files must preserve typography and text color while ignoring obsolete background preferences.

## Desktop integration

Manual verification adds all three widget sizes, observes minute changes and sleep/wake, checks light/dark appearance, and confirms that quitting the companion does not remove the widget.

Follow [[setup#Setup]] to install and perform these checks. WidgetKit may defer timeline delivery, so the implementation cannot guarantee exact update timing.

Plugin registration alone is insufficient: verify that the gallery displays the widget, or that the macOS widget host successfully receives its descriptor and renders its preview. A registered extension can still fail during startup.

## Private descriptor controls

Automated tests verify that the fixed transparency transformation targets only Quiet Clock, preserves unrelated encoded data, and falls back for non-codable inputs.

[PrivateBackgroundTests.m](../Tests/PrivateBackgroundTests.m) uses secure-coding stand-ins to exercise native archive replacement through [test.sh](../scripts/test.sh). It verifies that a previously different background style becomes clear. This tests transformation logic, not the private host ABI. The build links the hook only into the widget extension.

On macOS, re-add an upgraded widget if its descriptor was cached. Confirm full transparency with default, migrated, and Reset settings. The user confirmed this private route on macOS 27. QCBackground log entries distinguish hook or decoding failures from host rendering behavior.

## Shortcut links

Tests validate website normalization, rejection of unsafe schemes and credentials, stable click routing including idle/settings routes, duplicate-ID rejection, draft persistence, and the six-link limit.

[ShortcutTests.swift](../Tests/ShortcutTests.swift) runs through [test.sh](../scripts/test.sh). Appearance persistence tests cover populated shortcut settings, shared link size, link spacing, divider brightness, alignment, and migration from files without links, alignment, or shared size. Spacing and divider tests cover persistence, older-file defaults, valid endpoints, and rejection of out-of-range and nonfinite values. Boundary checks accept 8/32 pt for links and 8/240 pt for the clock, and reject out-of-range and nonfinite sizes. Sandbox probes verify shortcut sharing using a disposable file.

Manual checks add, edit, reorder, and delete links; exercise icon/text/both modes and sizes; and search for Linear, GitHub, and X. Confirm all three widget sizes fit six links with exactly one link per row, long labels wrap without ellipsis, the dotted divider disappears with no valid links, left/center/right alignment moves clock and link rows together, incomplete addresses are omitted, text color applies to icons, and clicking each link opens the correct destination in the default browser. Deleted link IDs must not open stale destinations. Live browser handoff requires a desktop check.

## Bundled service icons

Bundle validation checks that both targets contain the entire pinned icon catalog and every referenced SVG, the upstream license, required service logos, and the shortcut URL scheme registration.

[check_bundle.py](../Tests/check_bundle.py) runs during the native build. AppKit rendering checks inspect all three clock sizes with six mixed-display shortcuts; actual widget-host link interaction remains a manual desktop check.

## Settings launch behavior

Desktop checks verify that idle and shortcut URL launches do not create an appearance window, while clicking the time and manual application launch do.

Use cold and already-running app launches, including a previously closed editor. Check that the time label opens settings, its surrounding alignment space and divider do not, and shortcut links still open their websites. Confirm no gear is displayed. Switching the desktop widget to Large must provide more vertical room while preserving transparency, alignment, links, and time-only settings access. Explicit settings access must still work after an idle launch. Existing editor windows need not close when a shortcut is clicked. The OS may activate the app even when it has no windows; the app does not control WidgetKit’s activation policy.
