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

Settings tests verify that all appearance choices survive persistence, invalid writes preserve prior settings, corrupt data is rejected, and defaults can be restored.

[AppearanceTests.swift](../Tests/AppearanceTests.swift) runs through [test.sh](../scripts/test.sh) using isolated temporary storage. [AppearanceSandboxProbe.swift](../Tests/AppearanceSandboxProbe.swift), run by [test-sandbox.sh](../scripts/test-sandbox.sh), verifies signed app-to-widget sharing and rejects writes using widget entitlements.

## Appearance interaction

Manual checks exercise font selection, size and weight extremes, spacing, colors, system background, automatic saving, Reset, and reopening the app with saved settings.

Compare both preview sizes with the desktop widget, including system full-color and monochrome modes. Confirm that changes save without an Apply button and update the widget after adjustments stop. Close or quit immediately after a slider change, reopen, and verify the last value persisted. Rapid slider changes must coalesce refresh requests, and quitting the editor must leave the widget working. Check custom fonts with limited available weights and long localized time strings.

Verify that the system-background option is not labeled or previewed as true transparency. Desktop verification on macOS 15 shows an opaque black host tile even with the app background omitted and container removal permitted. The persisted transparency flag must remain readable for existing users.

## Desktop integration

Manual verification adds both widget sizes, observes minute changes and sleep/wake, checks light/dark appearance, and confirms that quitting the companion does not remove the widget.

Follow [[setup#Setup]] to install and perform these checks. WidgetKit may defer timeline delivery, so the implementation cannot guarantee exact update timing.

Plugin registration alone is insufficient: verify that the gallery displays the widget, or that the macOS widget host successfully receives its descriptor and renders its preview. A registered extension can still fail during startup.
