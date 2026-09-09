# Architecture

A SwiftUI companion application embeds a WidgetKit extension for the macOS desktop widget gallery. The deployment target supports desktop widgets on macOS Sonoma and later.

## Clock appearance

The clock face shows hours and minutes with configurable typography, colors, and background. Defaults use light rounded system type, monospaced digits, and a subtle shadow; the hour cycle follows the system locale.

[ClockFace.swift](../Sources/Shared/ClockFace.swift) adapts to small and medium widgets. The accessible label includes the full localized time. [ClockTime.swift](../Sources/Shared/ClockTime.swift) owns formatting. See [[architecture#Architecture#Appearance settings]] for customization.

## Appearance settings

The companion app edits a shared appearance for every clock widget, with a live preview and automatic saving. Settings persist across app launches and widget timeline reloads.

[QuietClockApp.swift](../Sources/ClockApp/QuietClockApp.swift) offers system designs and installed font families, automatic or fixed size, weight, letter spacing, text and background color pickers, and a system-background option. Custom fonts use their nearest available weight; unavailable families fall back to rounded system type. Oversized text scales down to fit.

[ClockAppearance.swift](../Sources/Shared/ClockAppearance.swift) validates and atomically stores settings in the account’s Quiet Clock Application Support folder. The local ad-hoc build grants only that folder: [App.entitlements](../Sources/App.entitlements) allows read/write, and [Widget.entitlements](../Sources/Widget.entitlements) allows read-only access. An App Store distribution should migrate this sharing to a provisioned App Group.

Every edit saves immediately; WidgetKit reload requests wait until adjustments pause briefly. Closing the editor or quitting flushes a pending reload, so the final edit remains saved. Each timeline carries a settings snapshot, with no polling or ongoing app process. Missing settings use defaults; malformed settings report an editor error and fall back to defaults in the widget. Reset immediately saves and requests a refresh of the defaults.

The system-background option omits the app’s background view and permits container removal. On the tested macOS 15 desktop, an opaque black host tile remains. True wallpaper transparency is unsupported by this implementation; the editor previews an approximate system tile instead of wallpaper showing through. The persisted transparency flag remains compatible with prior settings. Full-color mode best preserves selected colors.

## Scheduling

The extension supplies minute-boundary entries with three hours of coverage and requests an hourly reload. WidgetKit controls actual delivery, so precise minute changes and ten-second polling are not guaranteed.

[ClockWidget.swift](../Sources/ClockWidget/ClockWidget.swift) supplies the timeline using [ClockTime.swift](../Sources/Shared/ClockTime.swift). No background loop, network request, or resident companion app is required. Time zone changes take effect with a new timeline.

## Packaging

The build script compiles and signs a macOS application containing a sandboxed WidgetKit extension. The companion window explains how to add the widget and may be closed or quit afterward.

[build.sh](../scripts/build.sh) uses Apple’s command-line compiler without third-party dependencies. Local bundles use ad-hoc signing; distribution requires an Apple signing identity and notarization. [QuietClockApp.swift](../Sources/ClockApp/QuietClockApp.swift) provides the appearance editor and live preview.

The extension links its executable entry point to the macOS extension service bootstrap, which invokes Swift’s widget registration and serves host requests. Starting directly at Swift’s main exits before the gallery receives a descriptor. Install the app in Applications for a stable bundle location.
