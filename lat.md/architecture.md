# Architecture

An AppKit companion application with a SwiftUI editor embeds a WidgetKit extension for the macOS desktop widget gallery. The deployment target supports desktop widgets on macOS Sonoma and later.

## Clock appearance

The clock face shows hours and minutes with configurable typography, text color, and optional shortcut links. Defaults use light rounded system type, monospaced digits, and a subtle shadow; the hour cycle follows the system locale.

[ClockFace.swift](../Sources/Shared/ClockFace.swift) adapts to small, medium, and large widgets. The accessible label includes the full localized time. Identity content/view transitions and a nil animation tied to the entry date suppress minute-change animations, following [Apple’s widget animation guidance](https://developer.apple.com/documentation/widgetkit/animating-data-updates-in-widgets-and-live-activities). [ClockTime.swift](../Sources/Shared/ClockTime.swift) owns formatting. See [[architecture#Architecture#Appearance settings]] for customization.

The widget advertises small, medium, and large families. Large provides a taller host allocation for links; content adapts to the supplied geometry. WidgetKit controls preset sizes, so the widget cannot expand its desktop bounds dynamically. The editor previews all three sizes, scaling the large preview down to fit the window.

## Appearance settings

The companion app edits a shared appearance for every clock widget, with a live preview and automatic saving. Settings persist across app launches and widget timeline reloads.

[QuietClockApp.swift](../Sources/ClockApp/QuietClockApp.swift) offers system designs and installed font families, automatic or fixed clock size from 8–240 pt, weight, letter spacing, whole-widget left/center/right alignment, the existing automatic/custom text color controls, and shortcut editing. Custom fonts use their nearest available weight; unavailable families fall back to rounded system type. Oversized text scales down to fit.

[ClockAppearance.swift](../Sources/Shared/ClockAppearance.swift) validates and atomically stores settings in the account’s Quiet Clock Application Support folder. The local ad-hoc build grants only that folder: [App.entitlements](../Sources/App.entitlements) allows read/write, and [Widget.entitlements](../Sources/Widget.entitlements) allows read-only access. An App Store distribution should migrate this sharing to a provisioned App Group.

Every edit saves immediately; WidgetKit reload requests wait until adjustments pause briefly. Closing the editor or quitting flushes a pending reload, so the final edit remains saved. Each timeline carries a settings snapshot, with no polling or ongoing app process. Missing settings use defaults; malformed settings report an editor error and fall back to defaults in the widget. Reset immediately saves and requests a refresh of the defaults.

Background controls have been removed. Older appearance files retain typography and text color while obsolete background keys are ignored. Shortcut storage is optional for backward compatibility; older files start with no links. Missing link typography defaults to System Medium at 16 pt; obsolete per-link sizes are ignored. Reset clears links and restores type and text color defaults without disabling transparency.

## Transparent background

The widget always requests a clear, removable, transparent host background. This private implementation was confirmed visually on macOS 27; its behavior can still change with OS updates.

[PrivateBackground.m](../Sources/ClockWidget/PrivateBackground.m) intercepts both descriptor-fetch selectors and applies a fixed transparency configuration to Quiet Clock only. A secure archive round trip replaces matching descriptors through an unarchiver delegate, preserving unrelated encoded fields. Missing hooks, missing setters, and recoverable coding errors retain the original result. This cannot protect against every private ABI change or native crash.

The private properties were identified in [ClearAndBlurredWidgets](https://github.com/pookjw/ClearAndBlurredWidgets). The hook uses native root decoding rather than directly calling a private Swift initializer. It does not read appearance settings, so saved preferences and Reset cannot turn transparency off. No system process injection, private service access, or background polling is used.

macOS caches descriptors separately from timelines. Upgrading an older installation may require removing and re-adding the widget once. Hook and decoding diagnostics use the QCBackground log prefix. Private APIs are unsuitable for App Store distribution. The companion preview draws directly over its sample wallpaper.

## Shortcut links

Up to six website links sit beneath the clock in its text color. Each has a URL, label, icon, display mode, and editable order. Shared typography controls set the link font family, weight, and 8–32 pt size.

[ClockShortcut.swift](../Sources/Shared/ClockShortcut.swift) accepts HTTP and HTTPS websites, adds HTTPS to bare hostnames, and rejects credentials and other schemes. Incomplete edits persist as drafts and stay off the widget until valid. Blank labels use the hostname. Stable unique IDs route clicks to the current saved URL; removed or unknown IDs do nothing.

Link labels have their own shared font family and weight, independent of the clock, using the same system designs, installed families, and font fallback. Text size and weight apply only to labels. Shared icon size (8–64 pt) and icon–text gap (0–32 pt, default 5 pt) are independently adjustable. Older files preserve their former link size for icons, including when text size is subsequently changed. Icons, text, and gaps scale together when rows must shrink to fit.

[ClockFace.swift](../Sources/Shared/ClockFace.swift) places each link on its own row, wrapping long labels without ellipsis. Links never share a row. The shared link-spacing control sets the vertical gap between rows from 0–48 pt, defaulting to 12 pt. A dotted divider appears only when valid links exist; its brightness control changes opacity from 0–100%, defaulting to 25%, while retaining the text color. Divider length ranges from 0–100% of the padded content width and follows the widget alignment; existing settings default to full width. Zero length or brightness hides the line without changing vertical layout. Clock text and link rows share the selected alignment, defaulting to center for older settings. If the links exceed their height budget, the complete group scales down until it fits rather than truncating labels. Each SwiftUI Link uses the registered quietclock scheme. [ShortcutEditor.swift](../Sources/ClockApp/ShortcutEditor.swift) handles that route and opens the saved address through the default HTTPS browser, rather than relying on the destination’s native-app association. The editor also has an explicit Open button. Icon-picker labels wrap without ellipsis.

The complete [Simple Icons 15.0.0 collection](../Resources/ServiceIcons/SOURCE.md) is bundled in both targets: 3,291 monochrome SVGs, original titles, license, and disclaimer. The searchable picker matches service names and slugs, and uses a lazy grid. A bounded image cache loads only viewed icons; the widget never downloads icons or site content. The Website fallback uses a system globe symbol.

## Settings access

Clicking the time opens the appearance window. Empty widget space and the divider use an idle route; shortcut launches route to the browser without creating a settings window.

[QuietClockApp.swift](../Sources/ClockApp/QuietClockApp.swift) uses an AppKit application delegate to create the SwiftUI editor only for manual app opens, the settings route, or the settings menu command. [ClockShortcut.swift](../Sources/Shared/ClockShortcut.swift) classifies idle, settings, shortcut, and invalid routes. Unknown routes do nothing.

WidgetKit still activates the containing app for widget links, as described in [Apple’s linking documentation](https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity). The clock cannot prevent that OS activation. The settings Link wraps only the time label, before the outer alignment frame, so the surrounding empty space is not part of its settings target. There is no separate settings icon.

## Scheduling

The extension supplies minute-boundary entries with three hours of coverage and requests an hourly reload. WidgetKit controls actual delivery, so precise minute changes and ten-second polling are not guaranteed.

[ClockWidget.swift](../Sources/ClockWidget/ClockWidget.swift) supplies the timeline using [ClockTime.swift](../Sources/Shared/ClockTime.swift). No background loop, network request, or resident companion app is required. Time zone changes take effect with a new timeline. On the first companion-app launch of each build, a public WidgetKit timeline reload is requested so a software upgrade replaces old rendered content.

## Packaging

The build script compiles and signs a macOS application containing a sandboxed WidgetKit extension. The companion window explains how to add the widget and may be closed or quit afterward.

[build.sh](../scripts/build.sh) uses Apple’s command-line compiler without third-party dependencies. Local bundles use ad-hoc signing; distribution requires an Apple signing identity and notarization. [QuietClockApp.swift](../Sources/ClockApp/QuietClockApp.swift) provides the appearance editor and live preview.

The extension links its executable entry point to the macOS extension service bootstrap, which invokes Swift’s widget registration and serves host requests. Starting directly at Swift’s main exits before the gallery receives a descriptor. Install the app in Applications for a stable bundle location.
